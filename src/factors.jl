#=
DataFrames are used to represent factors
https://en.wikipedia.org/wiki/Factor_graph

    :p is the column containing the probabilities, ::Float64
    Each variable has its own column corresponding to its assignments and named with its name

These can be obtained using the table() function
=#

"""
Factor multiplication
"""
function Base.(:(*))(f1::DataFrame, f2::DataFrame)
    onnames = setdiff(intersect(names(f1), names(f2)), [:p])
    finalnames = vcat(setdiff(union(names(f1), names(f2)), [:p]), :p)
    if isempty(onnames)
        j = join(f1, f2, kind=:cross)
        j[:,:p] .*= j[:,:p_1]
        return j[:,finalnames]
    else
        j = join(f1, f2, on=onnames, kind=:outer)
        j[:,:p] .*= j[:,:p_1]
        return j[:,finalnames]
    end
end

# TODO: this currently only supports binary-valued variables
# TODO: implement factoring out final value in factor table,
#       or throwing an error in that case
"""
Factor marginalization
"""
function sumout(f::DataFrame, v::Symbol)
    @assert issubset(unique(f[:,v]), [false, true])
    remainingvars = setdiff(names(f), [v, :p])
    g = groupby(f, v)
    if length(g) == 1
        return f[:,vcat(remainingvars, :p)]
    end
    j = join(g..., on=remainingvars)
    j[:,:p] += j[:,:p_1]
    j[:,vcat(remainingvars, :p)]
end
function sumout(f::DataFrame, v::AbstractVector{Symbol})
    while !isempty(v)
        f = sumout(f, pop!(v))
    end
    f
end

"""
Factor normalization
Ensures that the :p column sums to one
"""
function normalize(f::DataFrame)
    f[:,:p] /= sum(f[:,:p])
    f
end

"""
Given a DataFrame representation of a factor,
extract the rows which match the given assignment
"""
function Base.select(f::DataFrame, a::Assignment)
    commonNames = intersect(names(f), keys(a))
    mask = trues(size(f,1))
    for s in commonNames
        mask &= (f[s] .== a[s])
    end
    f[mask, :]
end

"""
takes a factor represented as a DataFrame
or a set of data samples (without :p),
takes the unique assignments,
and estimates the associated probability of each assignment
based on its frequency of occurrence.
"""
function estimate(f::DataFrame)
    w = ones(size(f, 1))
    t = f
    if haskey(f, :p)
        t = f[:, names(t) .!= :p]
        w = f[:p]
    end
    # unique samples
    tu = unique(t)
    # add column with probabilities of unique samples
    tu[:p] = Float64[sum(w[Bool[tu[j,:] == t[i,:] for i = 1:size(t,1)]]) for j = 1:size(tu,1)]
    tu[:p] /= sum(tu[:p])
    tu
end

"""
TODO: what is this for?
"""
function estimate_convergence(f::DataFrame, a::Assignment)

    n = size(f, 1)
    p = zeros(n)
    w = ones(n)
    if haskey(f, :p)
        w = f[:p]
    end

    dfindex = find([haskey(a, n) for n in names(f)])
    dfvalues = [a[n] for n in names(f)[dfindex]]'

    cumWeight = 0.0
    cumTotalWeight = 0.0
    for i in 1:n
        if convert(Array, f[i, dfindex]) == dfvalues
            cumWeight += w[i]
        end
        cumTotalWeight += w[i]
        p[i] = cumWeight / cumTotalWeight
    end
    p
end