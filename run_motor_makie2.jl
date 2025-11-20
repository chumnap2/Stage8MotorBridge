# =============================================================
# run_motor_makie.jl — FULL REWRITE (Clean, Fixed Version)
# Supports SimMotorController + VESCMotorController + Makie live plot
# =============================================================

using CairoMakie
using Observables
using Dates

# -------------------------------------------------------------
# Try loading local modules
# -------------------------------------------------------------
function try_include(name)
    file = name * ".jl"
    if isfile(file)
        include(file)
        @eval using .$(Symbol(name))
        return true
    else
        @warn "Module file $file not found"
        return false
    end
end

has_sim = try_include("SimMotorController")
has_vesc = try_include("VESCMotorController")
has_utils = try_include("MotorUtils")

# fallback ramp generator
if !has_utils || !isdefined(Main, :safe_ramp_motor)
    @info "safe_ramp_motor not found; using fallback"
    function safe_ramp_motor(target, start, step, dt)
        v = start
        return Channel{Float64}() do ch
            while abs(v - target) > step
                v += step * sign(target - v)
                put!(ch, v)
                sleep(dt)
            end
            put!(ch, target)
        end
    end
end

# -------------------------------------------------------------
# MotorWrapper type
# -------------------------------------------------------------
struct MotorWrapper
    bridge
    mode::Symbol  # :sim or :vesc
end

# -------------------------------------------------------------
# Safe send helpers
# -------------------------------------------------------------
function send_speed!(mw::MotorWrapper, v)
    try
        if mw.mode == :sim
            mw.bridge.controller.speed = v
        elseif mw.mode == :vesc
            VESCMotorController.CmdSpeed!(mw.bridge, v)
        end
    catch e
        @error "send_speed! failed" error=e
    end
end

function send_enable!(mw::MotorWrapper, en)
    try
        if mw.mode == :sim
            mw.bridge.controller.enabled = en
        elseif mw.mode == :vesc
            VESCMotorController.CmdEnable!(mw.bridge, en)
        end
    catch e
        @error "send_enable! failed" error=e
    end
end

function get_feedback(mw::MotorWrapper)
    try
        if mw.mode == :sim
            return mw.bridge.controller.position, mw.bridge.controller.velocity
        elseif mw.mode == :vesc
            return VESCMotorController.sendFeedback(mw.bridge)
        end
    catch
        return 0.0, 0.0
    end
end

# -------------------------------------------------------------
# Makie Figure Setup
# -------------------------------------------------------------
function setup_figure()
    fig = Figure(resolution=(900, 500))

    ax1 = Axis(fig[1,1], title="Position", xlabel="t", ylabel="pos")
    ax2 = Axis(fig[2,1], title="Velocity", xlabel="t", ylabel="vel")

    pos_obs = Observable(Float64[])
    vel_obs = Observable(Float64[])
    t_obs   = Observable(Float64[])

    lines!(ax1, t_obs, pos_obs)
    lines!(ax2, t_obs, vel_obs)

    display(fig)
    return fig, t_obs, pos_obs, vel_obs
end

# -------------------------------------------------------------
# Motor loop
# -------------------------------------------------------------
function run_motor_loop(mw::MotorWrapper; target_duty=0.5, sample_dt=0.05)
    fig, t_obs, pos_obs, vel_obs = setup_figure()

    send_enable!(mw, true)

    t = 0.0
    duty = 0.0

    ramp = safe_ramp_motor(target_duty, 0.0, 0.02, sample_dt)

    for v in ramp
        duty = v
        send_speed!(mw, duty)

        # Update simulation if sim mode
        if mw.mode == :sim
            SimMotorController.update!(mw.bridge.controller, sample_dt)
        end

        pos, vel = get_feedback(mw)

        push!(t_obs[], t)
        push!(pos_obs[], pos)
        push!(vel_obs[], vel)
        notify.(Ref(t_obs)); notify.(Ref(pos_obs)); notify.(Ref(vel_obs))

        t += sample_dt
        sleep(sample_dt)
    end

    send_enable!(mw, false)
    return nothing
end

# -------------------------------------------------------------
# MAIN
# -------------------------------------------------------------
function main(argv)
    mode_str = length(argv) >= 1 ? argv[1] : "sim"
    target = length(argv) >= 2 ? parse(Float64, argv[2]) : 0.5

    if mode_str == "sim"
        @info "Using SIMULATION mode"
        if !has_sim
            error("SimMotorController not available!")
        end
        mw = MotorWrapper(SimMotorController.mb, :sim)

    elseif mode_str == "vesc" || mode_str == "real"
        @info "Using REAL VESC mode"
        if !has_vesc
            @warn "VESCMotorController not found; running in SIM fallback"
            mw = MotorWrapper(SimMotorController.mb, :sim)
        else
            mw = MotorWrapper(VESCMotorController.mb, :vesc)
        end

    else
        error("Unknown mode: $mode_str")
    end

    run_motor_loop(mw; target_duty=target)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
