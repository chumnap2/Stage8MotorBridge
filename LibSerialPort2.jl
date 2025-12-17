using LibSerialPort
using Sockets
using Dates

# --- Serial port setup ---
const PORT_NAME = "/dev/ttyACM2"
const BAUD_RATE = 115200

function open_vesc_port()
    sp = LibSerialPort.open(PORT_NAME, BAUD_RATE; mode=LibSerialPort.SP_MODE_READ_WRITE)
    println("Serial port opened: ", sp)
    return sp
end

# --- VESC helpers ---
function vesc_crc(data::Vector{UInt8})
    crc = UInt16(0)
    for b in data
        crc ⊻= UInt16(b) << 8
        for _ in 1:8
            crc = (crc & 0x8000 != 0) ? (crc << 1) ⊻ 0x1021 : (crc << 1)
        end
    end
    crc
end

function send_get_values(sp)
    payload = UInt8[0x04]  # COMM_GET_VALUES
    crc = vesc_crc(payload)
    frame = UInt8[0x02, length(payload), payload..., crc >> 8, crc & 0xff, 0x03]
    write(sp, frame)
end

function decode_get_values(data::Vector{UInt8})
    if length(data) < 79
        error("Too few bytes: $(length(data))")
    end

    get_i16(i) = reinterpret(Int16, UInt16(data[i]) | (UInt16(data[i+1]) << 8))[1]
    get_i32(i) = reinterpret(Int32, UInt32(data[i]) | (UInt32(data[i+1]) << 8) |
                             (UInt32(data[i+2]) << 16) | (UInt32(data[i+3]) << 24))[1]

    return Dict(
        :temp_mos1 => get_i16(1)/10,
        :temp_mos2 => get_i16(3)/10,
        :temp_mos3 => get_i16(5)/10,
        :temp_motor => get_i16(7)/10,
        :current_motor => get_i32(9)/1000,
        :current_in => get_i32(13)/1000,
        :duty_cycle_now => get_i16(17)/10000,
        :rpm => get_i32(19),
        :v_in => get_i16(23)/10,
        :amp_hours => get_i32(25)/10000,
        :amp_hours_charged => get_i32(29)/10000,
        :watt_hours => get_i32(33)/10000,
        :watt_hours_charged => get_i32(37)/10000,
        :fault_code => data[79]
    )
end

# --- Poll VESC continuously in a Task ---
function start_polling(sp; interval_s=0.05)
    @async while true
        send_get_values(sp)
        buf = Vector{UInt8}(undef, 128)
        n = try
            readbytes!(sp, buf)
        catch e
            0
        end

        if n > 0
            try
                telem = decode_get_values(buf[1:n])
                println("VESC:", telem)
            catch e
                println("Decode failed: ", e)
            end
        end

        sleep(interval_s)
    end
end

# --- TCP server ---
function start_tcp_server(sp; host="127.0.0.1", port=12345)
    server = listen(IPv4(host), port)
    println("TCP server listening on $host:$port ...")

    @async while true
        client = accept(server)
        println("Client connected: ", client)
        @async begin
            while true
                # Send latest VESC values to client
                send_get_values(sp)
                buf = Vector{UInt8}(undef, 128)
                n = try
                    readbytes!(sp, buf)
                catch e
                    0
                end

                if n > 0
                    try
                        telem = decode_get_values(buf[1:n])
                        write(client, string(telem) * "\n")
                        flush(client)
                    catch e
                        println("Decode failed: ", e)
                    end
                end

                sleep(0.05)
            end
        end
    end
end

# --- Main ---
function main()
    sp = open_vesc_port()
    poll_task = start_polling(sp)
    start_tcp_server(sp)
end

main()
