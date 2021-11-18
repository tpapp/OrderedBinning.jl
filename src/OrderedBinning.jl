"""
Flexible binning of univariate arguments. See `ordered_bins`.
"""
module OrderedBinning

export ordered_bins

using ArgCheck: @argcheck
using UnPack: @unpack
using DocStringExtensions: SIGNATURES

struct OrderedBins{V<:AbstractVector,T}
    boundaries::V
    strict::Bool
    tolerance::T
    function OrderedBins(boundaries::V, strict::Bool,
                         tolerance::T) where {V<:AbstractVector,T}
        @argcheck issorted(boundaries)
        @argcheck tolerance ≥ 0
        new{V,T}(boundaries, strict, tolerance)
    end
end

"""
$(SIGNATURES)

Return a callable that places its argument in to bins according to `boundaries`, which
should be sorted.

Specifically, let `mi = first(x)` and `ma = last(x)`, and `i` is the value returned by the
callable. Then

- if `mi ≤ x ≤ ma`, `boundaries[i] ≤ x ≤ boundaries[i + 1]` holds. The last inequality is
  strict when `x < ma`.

- otherwise, `tolerance` extends the bins on the edge, ie if `x ≥ mi - tolerance`,
  `i == firstindex(boundaries)`, while if `x ≤ ma + tolerance`,
  `i == lastindex(boundaries) - 1`.

- finally, outside these ranges an error is thrown if `strict == true`, otherwise
  `i == firstindex(boundaries) - 1` or `i == lastindex(boundaries)`.

`tolerance` is meant for containing floating point error.

# Examples

```jldoctest
julia> ob = ordered_bins(0:3; strict = true, tolerance = 0.5)
OrderedBinning.OrderedBins{UnitRange{Int64}, Float64}(0:3, true, 0.5)

julia> ob(0)
1

julia> ob(3.5)
3
"""
function ordered_bins(boundaries; strict::Bool = true, tolerance = 0)
    OrderedBins(boundaries, strict, tolerance)
end

function (ob::OrderedBins)(x)
    @unpack boundaries, strict, tolerance = ob
    lo, hi = firstindex(boundaries), lastindex(boundaries)
    mi, ma = first(boundaries), last(boundaries)
    if x < mi
        if x ≥ mi - tolerance
            lo
        else
            strict && throw(DomainError(x, "below lowest boundary - tolerance"))
            lo - oftype(lo, 1)
        end
    elseif x ≥ ma
        if x ≤ ma + tolerance
            hi - 1
        else
            strict && throw(DomainError(x, "above highest boundary + tolerance"))
            hi
        end
    else
        searchsortedlast(ob.boundaries, x)
    end
end

end # module
