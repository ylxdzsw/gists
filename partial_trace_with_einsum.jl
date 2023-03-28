using LinearAlgebra
using SparseArrays

function _term(x, j, sys, dims)
    a = sparse(1.0I, 1, 1)
    b = sparse(1.0I, 1, 1)
    for (i_sys, dim) in enumerate(dims)
        if i_sys == sys
            v = spzeros(dim, 1)
            v[j] = 1
            a = kron(a, v')
            b = kron(b, v)
        else
            a = kron(a, sparse(1.0I, dim, dim))
            b = kron(b, sparse(1.0I, dim, dim))
        end
    end
    return a * x * b
end

partial_trace(x, sys, dims) = sum(j -> _term(x, j, sys, dims), 1:dims[sys])

using OMEinsum

function my_ptrace(x, sys, dims)
    simplified_dims = prod(dims[sys+1:end]), dims[sys], prod(dims[1:sys-1])
    r = ein"abcdbf->acdf"(reshape(x, simplified_dims..., simplified_dims...))
    reshape(r, prod(dims) ÷ dims[sys], prod(dims) ÷ dims[sys])
end

dims = [2, 4, 2];
x = rand(ComplexF64, 16, 16);
sys = 2;

partial_trace(x, sys, dims)
my_ptrace(x, sys, dims)

a = rand(2,2);
b = rand(2,2);
c = kron(a, b);

my_ptrace(c, 1, [2,2])
partial_trace(c, 1, [2,2])
tr(a) .* b

a = rand(2,2);
b = rand(4,4);
c = rand(2,2);
d = reduce(kron, (a, b, c));

partial_trace(d, 1, [2,4,2])
my_ptrace(d, 1, [2,4,2])
tr(a) * kron(b, c)

using BenchmarkTools

dims = 13, 17, 19;
x = rand(ComplexF64, prod(dims), prod(dims));
@btime partial_trace(x, 2, dims);
@btime my_ptrace(x, 2, dims);

