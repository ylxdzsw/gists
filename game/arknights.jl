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
Base.isapprox(a::Image, b::Image) = similarity(a, b) <= .02

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

click(args...; delay=rand()) = begin sleep(delay + .2rand()); click(args...) end
click(x, y) = run(`adb shell input tap $y $x`)
click(x, y, h, w) = run(`adb shell input tap $(rand(y:y+w-1)) $(rand(x:x+h-1))`)
click(s::Scen) = click(s.area...)

notify_desktop(msg::String) = run(`notify-send Arknights $msg`)

# get similarity by predicting b using 3x3 squares from a
# because sometimes it has 1 pixel offset (especially when rotated the screen)
function similarity(a::Image, b::Image)
    A = zeros(f32, *((size(a).-2)...), 27)
    B = zeros(f32, *((size(a).-2)...), 3)
    for i in 2:car(size(a))-1, j in 2:cadr(size(a))-1
        n = (i - 2) * (cadr(size(a)) - 2) + j - 1
        A[n, 1:9] = [ a[i+oi, j+oj].r for oi in -1:1 for oj in -1:1 ]
        A[n, 10:18] = [ a[i+oi, j+oj].g for oi in -1:1 for oj in -1:1 ]
        A[n, 19:27] = [ a[i+oi, j+oj].b for oi in -1:1 for oj in -1:1 ]
        B[n, :] = [ b[i, j].r, b[i, j].g, b[i, j].b ]
    end
    X = A \ B
    B̂ = A * X
    mae(B, B̂)
end

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
        sleep(minimum(history) - 5)
        15 + 3std(history), 2
    else
        sleep(60)
        nothing, 5
    end
    @label on_finished
    s = wait_scen(
        scen_dict.battle_finished_exp,
        scen_dict.battle_finished_fest,
        scen_dict.battle_finished_trust,
        scen_dict.battle_finished_level_up,
        scen_dict.extermination_finished_fan,
        scen_dict.extermination_finished_update,
        scen_dict.extermination_finished_jade;
        timeout, timespan)
    if s === scen_dict.battle_finished_level_up
        @info "level up"
        click(scen_dict.battle_finished_level_up, delay=2)
        @goto on_finished
    end
    if s in (scen_dict.extermination_finished_fan, scen_dict.extermination_finished_update)
        click(scen_dict.extermination_finished_update, delay=.5)
        @goto on_finished
    end
    push!(history, time() - battle_start_time)
    @info "battle finished in $(round(Int, time() - battle_start_time))s"

    click(scen_dict.battle_finished_trust, delay=2)
    return true
end

function daily_task()
    @info "collecting daily task"
    wait_scen(scen_dict.navigator_icon, timeout=10)
    click(scen_dict.navigator_icon, delay=.5)

    wait_scen(scen_dict.navigator_task_button, timeout=10)
    click(scen_dict.navigator_task_button, delay=.5)

    wait_scen(scen_dict.daily_task_tab, timeout=10)
    click(scen_dict.daily_task_tab, delay=1)

    retry = false
    while true
        try
            wait_scen(scen_dict.daily_task_claim_first, timeout=5)
            retry = true # when the reward pops up
        catch
            if retry
                retry = false
            else
                break
            end
        end

        click(scen_dict.daily_task_claim_first, delay=2)
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

read_screen(scen_dict.restore_sanity_cancel_button)

scen = Scen("restore_sanity_cancel_button", 825, 1085, 85, 170)
read_screen(scen.area...)

take_screenshot(scen)
push!(scens, scen)
serialize("scens", scens)

for (i, s) in enumerate(scens)
    display(md"## $i. $(s.name) $(s.area)")
    display(s.screenshot)
end
