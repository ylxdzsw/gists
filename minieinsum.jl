function minieinsum(code, args...)
    dims = Dict() # code -> size

    inputs_code, output_code = split(code, "->")
    inputs_code = map(strip, split(inputs_code, ","))

    for (input_code, input_tensor) in zip(inputs_code, args)
        for (dim, size) in zip(input_code, size(input_tensor))
            dims[dim] = size
        end
    end

    output_tensor = zeros((dims[dim] for dim in output_code)...)

    indices = [1 for _ in dims]
    sizes = [dims[dim] for dim in keys(dims)]
    code_map = Dict(zip(keys(dims), 1:length(dims)))
    while true
        output = 1
        for (input_code, input_tensor) in zip(inputs_code, args)
            input_indices = [code_map[dim] for dim in input_code]
            output *= input_tensor[indices[input_indices]...]
        end
        output_tensor[indices[[code_map[dim] for dim in output_code]]...] += output

        i = findfirst(i -> indices[i] < sizes[i], 1:length(sizes))
        if i == nothing
            break
        end

        indices[i] += 1
        indices[1:i-1] .= 1
    end

    return output_tensor
end

A, B, C = rand(2,3), rand(3,4), rand(4,5)
minieinsum("ij,jk,kl->kik", A, B, C)

using OMEinsum
ein"ij,jk,kl->kik"(A, B, C)
