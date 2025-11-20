#!/usr/bin/env julia
using Sockets
using GLMakie

if length(ARGS) != 3
    println("Usage: julia run_motor_makie.jl <host> <port> <target_duty>")
    exit(1)
end

host = ARGS[1]
port = parse(Int, ARGS[2])
target_duty = parse(Float64, ARGS[3])

println("[Info] Connecting to VESC server at $host:$port")
sock = connect(host, port)

function send_duty(d::Float64)
    write(sock, "duty $(d)\n")
    flush(sock)
end

# ========== Plot Setup ==========
fig = Figure(resolution = (700, 450))
ax = Axis(fig[1, 1], xlabel="Time (s)", ylabel="Duty Cycle", title="Real-time Duty Command")

duty_data = Node(Float64[])
time_data = Node(Float64[])

lines!(ax,
    @lift(range(0, length($duty_data)-1) .* 0.05),
    duty_data,
    linewidth = 2
)

display(fig)

t0 = time()

function push_point(d)
    push!(duty_data[], d)
    push!(time_data[], time() - t0)
    notify(duty_data)
end

# ========== Control Sequence ==========
println("🟢 Setting duty to $target_duty")
send_duty(target_duty)

# ramp up shown in plot
for i in 1:20
    push_point(target_duty)
    sleep(0.05)
end

println("⏸ Holding for 2 seconds...")
sleep(2)

println("🔻 Setting duty to 0.0")
send_duty(0.0)

for i in 1:20
    push_point(0.0)
    sleep(0.05)
end

println("🔴 Motor stopped")
send_duty(0.0)

println("[Info] Plot window remains open.")
