using OhMyJulia
using Fire

"""
Crop a pdf file to fit iPad screen (3:4).
Optionally trim the margin left, bottom, right, top in %
"""
@main function crop(file; trim::Vector{f32}=f32[5,5,5,5])
    size = read(`sh -c "pdfinfo $file | awk '/Page size/{print \$3,\$5}'"`, String)
    w, h = parse.(f32, split(size))
    l, b, r, t = trim .* [w, h, w, h] ./ 100

    if (w - l - r) / (h - b - t) < .75
        d = (h - b - t) - (w - l - r) / .75
        b += .5d
        t += .5d
    elseif (w - l - r) / (h - b - t) > .75
        d = (w - l - r) - .75(h - b - t)
        l += .5d
        r += .5d
    end

    open("main.tex", "w") do f
        f << """
            \\documentclass{article}
            \\usepackage{pdfpages}
            \\usepackage[paperwidth=$(w - l - r)bp,paperheight=$(h - b - t)bp]{geometry}
            \\begin{document}
            \\includepdf[pages=-, scale=1, trim=$(l)bp $(b)bp $(r)bp $(t)bp]{$file}
            \\end{document}
        """
    end
    run(`pdflatex main`)
end
