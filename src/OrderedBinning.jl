"""
Flexible and robust binning of real numbers.

Public API is `ordered_bins` and `default_halo`, neither are exported.
"""
module OrderedBinning

using ArgCheck: @argcheck
using DocStringExtensions: SIGNATURES

"""
Edge specifications we accept. For internal use.
"""
const VALID_EDGES = (:left, :right)

struct OrderedBins{E,V<:AbstractVector,T,B,A}
    boundaries::V
    # handling of values below lowest boundary
    halo_below::T
    error_below::Bool
    bin_below::B
    # handling of values above the lowest boundary
    halo_above::T
    error_above::Bool
    bin_above::A
    @doc """
    $(SIGNATURES)

    This function is internal, use [`ordered_bins`](@ref).
    """
    function OrderedBins{E}(boundaries::V,
                            halo_below::T, error_below::Bool, bin_below::B,
                            halo_above::T, error_above::Bool, bin_above::A,
                            ) where {E,V<:AbstractVector,T<:Real,B,A}
        @argcheck E ∈ VALID_EDGES
        @argcheck halo_below ≥ 0
        @argcheck halo_above ≥ 0
        for i in firstindex(boundaries):(lastindex(boundaries)-1)
            @argcheck(boundaries[i] < boundaries[i + 1],
                      "Boundaries need to be strictly increasing.")
        end
        new{E,V,T,B,A}(boundaries,
                       halo_below, error_below, bin_below,
                       halo_above, error_above, bin_above)
    end
end

function Base.show(io::IO, ob::OrderedBins{E}) where E
    (; boundaries,
     halo_below, error_below, bin_below,
     halo_above, error_above, bin_above) = ob
    function _print_halo(dir, halo, error, bin)
        print(io, "\n  halo $dir: $halo, values $dir ")
        error ? print(io, "error") : print(io, "bin to $bin")
    end
    print(io, "OrderedBins{$E} with boundaries ", boundaries)
    _print_halo("below", halo_below, error_below, bin_below)
    _print_halo("above", halo_above, error_above, bin_above)
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

Specifically, let `mi = first(boundaries)` and `ma = last(boundaries)`, and `i` is the
value returned by the callable. Then

- if `mi ≤ x ≤ ma`, `boundaries[i] ≤ x ≤ boundaries[i + 1]` holds. Values that coincide
  with boundaries (other than `mi` or `ma`) are assigned to the adjacent bin according
  to `edge` (valid values: $VALID_EDGES, default: `:right`).

- otherwise, `halo_below` and `halo_above` (cf [`default_halo`](@ref) extends the first
  and last bins, ie
    1. if `x ≥ mi - halo_above`, `i == firstindex(boundaries)`,
    2. while if `x ≤ ma + halo_below`, `i == lastindex(boundaries) - 1`.

- finally, outside these ranges an error is thrown if `error_below` or `error_above` is
  true, otherwise `bin_below` and `bin_above` are returned, respectively.

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
                      # below
                      halo_below = default_halo(boundaries[end] - boundaries[begin]),
                      error_below = true,
                      bin_below = firstindex(boundaries) - 1,
                      # above
                      halo_above = halo_below,
                      error_above = true,
                      bin_above = lastindex(boundaries))
    halo_below, halo_above = promote(halo_below, halo_above)
    OrderedBins{edge}(boundaries isa AbstractVector ? boundaries : collect(boundaries),
                      halo_below, error_below, bin_below,
                      halo_above, error_above, bin_above)
end

_inner_bin_index(::Val{:left}, boundaries, x) =  searchsortedfirst(boundaries, x)::Int - 1

_inner_bin_index(::Val{:right}, boundaries, x) =  searchsortedlast(boundaries, x)::Int

function (ob::OrderedBins{E})(x) where E
    (; boundaries,
     halo_below, error_below, bin_below,
     halo_above, error_above, bin_above) = ob
    mi, ma = first(boundaries), last(boundaries)
    if x ≤ mi
        if x ≥ mi - halo_below
            firstindex(boundaries)
        elseif error_below
            throw(DomainError(x, "below lowest boundary - halo"))
        else
            bin_below
        end
    elseif x ≥ ma
        if x ≤ ma + halo_above
            lastindex(boundaries) - 1
        elseif error_above
            throw(DomainError(x, "above highest boundary + halo"))
        else
            bin_above
        end
    else
        _inner_bin_index(Val(E), boundaries, x)
    end
end

end # module
