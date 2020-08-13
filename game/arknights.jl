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
Base.isapprox(a::Image, b::Image) = mae(a, b) <= .02

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

scens = deserialize(rel"scens")
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

        @info "running out sanity and budget"
        click(scen_dict.restore_sanity_cancel_button, delay=.5)
        return false
    end

    battle_start_time = time()
    timeout, timespan = if length(history) > 2
        sleep(mean(history) - 3std(history))
        5 + 6std(history), 2
    else
        sleep(60)
        nothing, 5
    end
    @label on_finished
    s = wait_scen(
        scen_dict.battle_finished_star,
        scen_dict.battle_finished_exp,
        scen_dict.battle_finished_trust_background,
        scen_dict.battle_finished_level_up,
        scen_dict.extermination_finished_fan,
        scen_dict.extermination_finished_update,
        scen_dict.extermination_finished_jade;
        timeout, timespan)
    if s === scen_dict.battle_finished_level_up
        click(scen_dict.battle_finished_level_up, delay=2)
        @goto on_finished
    end
    if s in (scen_dict.extermination_finished_fan, scen_dict.extermination_finished_update)
        click(scen_dict.extermination_finished_update, delay=.5)
        @goto on_finished
    end
    push!(history, time() - battle_start_time)
    @info "battle finished in $(round(Int, time() - battle_start_time))s"

    click(scen_dict.battle_finished_star, delay=2)
    return true
end

function daily_task()
    @info "collecting daily task"
    wait_scen(scen_dict.navigator_icon, timeout=10)
    click(scen_dict.navigator_icon, delay=.5)

    wait_scen(scen_dict.navigator_task_button, timeout=10)
    click(scen_dict.navigator_task_button, delay=.5)

    wait_scen(scen_dict.daily_task_tab, timeout=10)
    click(scen_dict.daily_task_tab, delay=2)

    while true
        try
            wait_scen(scen_dict.daily_task_claim_first, timeout=10)
        catch
            break
        end

        click(scen_dict.daily_task_claim_first, delay=2)
        click(scen_dict.daily_task_claim_first, delay=5)
    end

    @info "all daily task claimed"
    click(scen_dict.navigator_back_icon, delay=2)
end

# ==== entry ==== #

function main()
    arg = try ARGS[1] catch; "" end
    claim_daily_task = '!' in arg
    arg = filter(x->x != '!', arg)

    budget = Ref(count(x->x == '+', arg))
    arg = filter(isdigit, arg)

    remaining = isempty(arg) ? -1 : parse(Int, arg)
    history = []

    while remaining != 0
        battle(budget, history) || break
        remaining -= 1
    end

    if claim_daily_task
        daily_task()
    end

    notify_desktop("finished!")
end

main()
exit()

# ==== dev utils ==== #

Boilerplate.web_display()

take_screenshot(scen::Scen) = scen.screenshot = read_screen(scen.area...)

read_screen(scen_dict.proxy_chosen)

scen = Scen("navigator_back_icon", 40, 45, 45, 180)
read_screen(scen.area...)

take_screenshot(scen)
push!(scens, scen)
serialize("scens", scens)

for s in scens
    display(md"## $(s.name) $(s.area)")
    display(s.screenshot)
end