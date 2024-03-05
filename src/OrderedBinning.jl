"""
Flexible and robust binning of real numbers.

Public API is `ordered_bins` and `default_halo`, neither are exported.
"""
module OrderedBinning

using ArgCheck: @argcheck
using DocStringExtensions: SIGNATURES

"""
Edge specifications we accept. Internal.
"""
const VALID_EDGES = (:left, :right)

"""
$(SIGNATURES)

Bins assigned to values below and above boundaries. Internal.
"""
function bins_below_above(boundaries::AbstractVector)
    (firstindex(boundaries) - 1, lastindex(boundaries))
end

struct OrderedBins{E,V<:AbstractVector,T}
    boundaries::V
    halo_below::T
    halo_above::T
    error_below::Bool
    error_above::Bool
    @doc """
    $(SIGNATURES)

    This function is internal, use [`ordered_bins`](@ref).
    """
    function OrderedBins{E}(boundaries::V,
                            halo_below::T, halo_above::T,
                            error_below::Bool, error_above::Bool,
                            ) where {E,V<:AbstractVector,T<:Real}
        @argcheck E ∈ VALID_EDGES
        @argcheck halo_below ≥ 0
        @argcheck halo_above ≥ 0
        for i in firstindex(boundaries):(lastindex(boundaries)-1)
            @argcheck(boundaries[i] < boundaries[i + 1],
                      "Boundaries need to be strictly increasing.")
        end
        new{E,V,T}(boundaries, halo_below, halo_above, error_below, error_above)
    end
end

function Base.show(io::IO, ob::OrderedBins{E}) where E
    (; boundaries, halo_below, halo_above, error_below, error_above,) = ob
    function _print_halo(dir, halo, error, bin)
        print(io, "\n  halo $dir: $halo, values $dir ")
        error ? print(io, "error") : print(io, "bin to $bin")
    end
    b, a = bins_below_above(boundaries)
    print(io, "OrderedBins{$E} with boundaries ", boundaries)
    _print_halo("below", halo_below, error_below, b)
    _print_halo("above", halo_above, error_above, a)
end

"""
Default halo radius.
"""
default_halo(span::T) where {T <: AbstractFloat} = √eps(span)

default_halo(span::Real) = 0

"""
$(SIGNATURES)

Return a callable that places its argument in to bins according to `boundaries`, which
should be sorted (strictly increasing).

Specifically, let

1. `MIN = first(boundaries)`
2. `MAX = last(boundaries)`
3. `FIRST = firstindex(boundaries)`
4. `LAST = lastindex(boundaries) - 1` (note: one less bin than boundaries).

and `i` is value returned by the callable. Then

- if `MIN ≤ x ≤ MAX`, `boundaries[i] ≤ x ≤ boundaries[i + 1]` holds. Values that coincide
  with boundaries (other than `MIN` or `MAX`) are assigned to the adjacent bin according
  to `edge` (valid values: $VALID_EDGES, default: `:right`).

- otherwise, `halo_below` and `halo_above` (cf [`default_halo`](@ref) extends the first
  and last bins, ie
    1. if `x ≥ mi - halo_above`, `i == FIRST`,
    2. while if `x ≤ ma + halo_below`, `i == LAST`.

- finally, outside these ranges an error is thrown if `error_below` or `error_above` is
  true, otherwise `FIRST - 1` and `LAST + 1` are returned, respectively.

Generalized indexing is supported: eg `boundaries` can be an
`OffsetArrays.OffsetVector`, and bin indices will be adjusted accordingly.

# Examples

```jldoctest
julia> ob = ordered_bins(1:5)
OrderedBins{right} with boundaries 1:5
  halo below: 0, values below error
  halo above: 0, values above error

julia> ob(1.1)                  # first bin
1

julia> ob(2.0)                  # second bin, because it is on boundary
2

julia> ob(5.1)                  # outside boundaries
ERROR: DomainError with 5.1:
above highest boundary + halo
"""
function ordered_bins(boundaries, edge = :right;
                      halo_below = default_halo(boundaries[end] - boundaries[begin]),
                      halo_above = halo_below, error_below = true, error_above = true)
    OrderedBins{edge}(boundaries isa AbstractVector ? boundaries : collect(boundaries),
                      promote(halo_below, halo_above)..., error_below, error_above)
end

_inner_bin_index(::Val{:left}, boundaries, x) =  searchsortedfirst(boundaries, x)::Int - 1

_inner_bin_index(::Val{:right}, boundaries, x) =  searchsortedlast(boundaries, x)::Int

function (ob::OrderedBins{E})(x) where E
    (; boundaries, halo_below, halo_above, error_below, error_above) = ob
    mi, ma = first(boundaries), last(boundaries)
    b, a = bins_below_above(boundaries)
    if x ≤ mi
        if x ≥ mi - halo_below
            firstindex(boundaries)
        elseif error_below
            throw(DomainError(x, "below lowest boundary - halo"))
        else
            b
        end
    elseif x ≥ ma
        if x ≤ ma + halo_above
            lastindex(boundaries) - 1
        elseif error_above
            throw(DomainError(x, "above highest boundary + halo"))
        else
            a
        end
    else
        _inner_bin_index(Val(E), boundaries, x)
    end
end

end # module
