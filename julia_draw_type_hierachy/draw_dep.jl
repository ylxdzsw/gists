using InteractiveUtils: subtypes

function draw_dep(T::Type; package_name::Bool=false, upper_bound::Bool=true)
    _draw(T) = for t in subtypes(T)
        print(g, "  \"")
        format_type(T)
        print(g, "\" -> \"")
        format_type(t)
        println(g, '\"')
        _draw(t)
    end

    format_type(t::Type) = format_type(Meta.parse(string(t)))
    format_type(s::Symbol) = print(g, s)
    format_type(i::Int) = print(g, i)
    format_type(q::QuoteNode) = print(g, q.value)
    format_type(e::Expr) = format_type(e, Val{e.head}())
    format_type(e, ::Val{:curly}) = begin
        format_type(e.args[1])
        print(g, '{')
        format_type(e.args[2])
        for i in e.args[3:end]
            print(g, ',')
            format_type(i)
        end
        print(g, '}')
    end
    format_type(e, ::Val{:.}) = begin
        if package_name
            format_type(e.args[1])
            print(g, '.')
        end
        format_type(e.args[2])
    end
    format_type(e, ::Val{:<:}) = begin
        format_type(e.args[1])
        if upper_bound
            print(g, "<:")
            format_type(e.args[2])
        end
    end

    g = IOBuffer()
    println(g, "digraph dep {")
    _draw(T)
    println(g, "}")
    String(take!(g))
end

using Fire
@main function main(name::Symbol)
    draw_dep(eval(:Number)) |> println
end
