#!/usr/bin/julia

# NOTE:
#   1. axis are the "array axis", i.e., starts from the left top, x goes down and y goes right

using Boilerplate

@async Boilerplate.load_std().web_display()

using OhMyJulia
using ImageCore
using ImageDistances

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

function battle(history=[])
    @info "preparing a battle"
    wait_scen(scen_dict.proxy_chosen, timeout=10)
    sleep(2 + .5rand()) # there is a short unresponsive time
    click(scen_dict.start_operation)
    
    s = wait_scen(scen_dict.team_preparation, timeout=10)
    if s === scen_dict.team_preparation
        sleep(.5 + .5rand())
        click(scen_dict.team_preparation)
    end
    
    battle_start_time = time()
    timeout = if length(history) > 2
        println(mean(history))
        sleep(mean(history))
        5 + 3std(history)
    end
    wait_scen(scen_dict.battle_finished_star, scen_dict.battle_finished_exp; timeout)
    sleep(2 + .5rand()) # wait for loot listing
    click(scen_dict.battle_finished_star)

    push!(history, time() - battle_start_time)
end

for i in 1:4
    battle()
end

# ==== dev utils ==== #

take_screenshot(scen::Scen) = scen.screenshot = read_screen(scen.area...)

scen = Scen("battle_finished_exp", 840, 760, 70, 160)
read_screen(scen.area...)

take_screenshot(scen)
push!(scens, scen)
serialize("scens", scens)

for s in scens
    display(md"## $(s.name) $(s.area)")
    display(s.screenshot)
end
