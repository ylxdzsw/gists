#!/usr/bin/julia

# NOTE:
#   1. axis are the "array axis", i.e., starts from the left top, x goes down and y goes right

using Boilerplate
using OhMyJulia
using ImageCore
using ImageDistances

Boilerplate.load_std()

const Image = Matrix{RGB{Normed{UInt8, 8}}}

import FileIO
import Base: show, display, isapprox
Base.show(io::IO, ::MIME"image/png", img::Image) = FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
Base.display(img::Image) = display(MIME"image/png"(), img)
Base.isapprox(a::Image, b::Image) = mae(a, b) <= .01

mutable struct Scen
    name::String
    area::NTuple{4, Int}
    screenshot::Union{Nothing, Image}
end
Scen(name, x...) = Scen(name, x, nothing)

read_screen() = reshape(reinterpret(RGBX{FixedPointNumbers.N0f8}, read(`adb shell screencap`)[17:end]), (1920, 1080))'
read_screen(s::Scen) = read_screen(s.area...)
read_screen(x, y, h, w) = read_screen(read_screen(), x, y, h, w)
read_screen(raw, s::Scen) = read_screen(raw, s.area...)
read_screen(raw, x, y, h, w) = RGB.(view(raw, x:x+h-1, y:y+w-1))

click(args...; delay=rand()) = begin sleep(delay + .5rand()); click(args...) end
click(x, y) = run(`adb shell input tap $y $x`)
click(x, y, h, w) = run(`adb shell input tap $(rand(y:y+w-1)) $(rand(x:x+h-1))`)
click(s::Scen) = click(s.area...)

notify_desktop(msg::String) = run(`notify-send Arknights $msg`)

function wait_scen(ss::Scen...; timeout=nothing, timespan=2)
    start_time = time()
    while timeout === nothing || time() < start_time + timeout
        cache = read_screen()
        for s in ss
            read_screen(cache, s) ≈ s.screenshot && return s
        end
        sleep(timespan)
    end

    error("timeout while waiting for $(join([s.name for s in ss], ", ", " or "))")
end

scens = deserialize("scens")
scen_dict = (; (Symbol(s.name) => s for s in scens)...)

function battle(budget=Ref(0), history=[])
    @info "preparing a battle"
    @label preparing
    wait_scen(scen_dict.proxy_chosen, timeout=10)
    click(scen_dict.start_operation, delay=2)

    s = wait_scen(
        scen_dict.team_preparation,
        scen_dict.restore_sanity_by_potion,
        scen_dict.restore_sanity_by_money,
        timeout=10
    )

    if s === scen_dict.team_preparation
        click(scen_dict.team_preparation, delay=.5)
    elseif s === scen_dict.restore_sanity_by_potion || s === scen_dict.restore_sanity_by_money
        if budget[] > 0
            @info "use a potion / money"
            budget[] -= 1
            click(scen_dict.restore_sanity_confirm_button, delay=.5)
            @goto preparing
        end

        @info "running out sanity and budget, finished"
        click(scen_dict.restore_sanity_cancel_button, delay=.5)
        notify_desktop("finished!")
        exit()
    end

    battle_start_time = time()
    timeout, timespan = if length(history) > 2
        sleep(mean(history) - 5std(history))
        5 + 10std(history), 2
    else
        sleep(60)
        nothing, 5
    end
    wait_scen(scen_dict.battle_finished_star, scen_dict.battle_finished_exp; timeout, timespan)
    push!(history, time() - battle_start_time)
    @info "battle finished in $(round(Int, time() - battle_start_time))s"

    click(scen_dict.battle_finished_star, delay=2)
end


# ==== entry ==== #

function main()
    arg = try ARGS[1] catch; "" end
    budget = Ref(count(x->x == '+', arg))
    arg = filter(isdigit, arg)
    remaining = isempty(arg) ? -1 : parse(Int, arg)
    history = []

    while remaining != 0
        battle(budget, history)
        remaining -= 1
    end
end

main()
exit()

# ==== dev utils ==== #

Boilerplate.web_display()

take_screenshot(scen::Scen) = scen.screenshot = read_screen(scen.area...)

scen = Scen("battle_finished_trust_background", 720, 1462, 30, 60)
read_screen(scen.area...)

take_screenshot(scen)
push!(scens, scen)
serialize("scens", scens)

for s in scens
    display(md"## $(s.name) $(s.area)")
    display(s.screenshot)
end
