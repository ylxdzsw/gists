#!/usr/bin/env julia

using OhMyJulia
using Fire

const weights = (
    ("Thin",   100),
    ("Light",  300),
    ("Medium", 500),
    ("Bold",   700),
    ("Black",  900),

    ("",       400)
)

function include_license(path, output)
    open(joinpath(path, "LICENSE.txt")) do license
        output << "/*" << read(license) << "*/"
    end
end

function parse_spec(name)
    name = splitext(name) |> car
    family, variant = split(name, '-')

    for (name, weight) in weights @when startswith(variant, name)
        return spacing_name(family), endswith(variant, "Italic"), weight
    end
end

function spacing_name(name)
    name = replace(name, r"([0-9a-z])([A-Z])", s"\1 \2")
    name = replace(name, r"([A-Z])([A-Z])([0-9a-z])", s"\1 \2\3")
end

function bundle_font(spec, input, output)
    family, italic, weight = spec

    output << """@font-face{font-family:"$family";"""
    italic && output << "font-style:italic;"
    weight != 400 && output << "font-weight:$weight;"
    output << "src:url('data:application/x-font-ttf;base64,"
    Base64EncodePipe(output) << read(input) << close
    output << "');}"
end

"""
Bundle downloaded Google fonts into a single CSS file.
"""
@main function main(paths::String...; no_license::Bool=false, output::String="./fonts.css")
    output = open(output, "w")
    for path in paths
        no_license || include_license(path, output)
        for file in readdir(path) @when endswith(file, ".ttf")
            spec = parse_spec(file)
            open(joinpath(path, file)) do input
                bundle_font(spec, input, output)
            end
        end
    end
end
