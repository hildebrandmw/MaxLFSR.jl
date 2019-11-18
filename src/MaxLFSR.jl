module MaxLFSR

export LFSR, ConstLFSR

# Coefficients are taken from https://users.ece.cmu.edu/~koopman/lfsr/index.html
#
# Index by the number of bits needed. Using fewer than 4 bits is apparently not supported,
# which is fine because usually one would want longer sequences anyways.
#
# Shorter sequences are simply generated using a longer LFSR and iterating multiple times.
include("terms.jl")

function nbits(x::Integer)
    if x <= zero(x) || x > typemax(Int64)
        throw(ArgumentError("Expected `length` to be between 1 and 2^64 - 1: Got: $x"))
    end

    # Add 1 if `x` is a power of 2 because a LFSR with `n` bits generates `2^n - 1` unique
    # numbers (it cannot generate zero)
    bits = ceil(Int, log2(x)) + convert(Int, ispow2(x))
    return max(bits, 4)
end

# Include 2 types of LFRS - a type table one and an AoT one.
abstract type AbstractLFSR end
Base.eltype(::AbstractLFSR) = Int

# Constant Type LFSR
struct LFSR <: AbstractLFSR
    len::Int
    mask::Int
    seed::Int
end

function LFSR(length; seed = 1)
    # Bounds checking on `seed`
    if seed < 1 || seed > length
        throw(ArgumentError("Expected `seed` to be between 1 and `length`"))
    end

    # Find the number of bits needed to represent length
    bits = nbits(length)
    mask = FEEDBACK[bits]
    return LFSR(length, mask, seed)
end

Base.length(L::LFSR) = L.len
mask(L::LFSR) = L.mask
seed(L::LFSR) = L.seed

# Compile time LFSR
struct ConstLFSR{len, mask, seed} <: AbstractLFSR end
function ConstLFSR(length; seed = 1)
    # Bounds checking on `seed`
    if seed < 1 || seed > length
        throw(ArgumentError("Expected `seed` to be between 1 and `length`"))
    end

    # Find the number of bits needed to represent length
    bits = nbits(length)
    mask = FEEDBACK[bits]
    return ConstLFSR{length, mask, seed}()
end

Base.length(::ConstLFSR{len}) where {len} = len
mask(::ConstLFSR{len, _mask}) where {len, _mask} = _mask
seed(::ConstLFSR{len, mask, _seed}) where {len, mask, _seed} = _seed

# Iterator Interface
@inline Base.iterate(A::AbstractLFSR) = (seed(A), seed(A))
@inline function Base.iterate(A::AbstractLFSR, x)
    # Iterate until we reach a result that is within the correct range.
    while true
        m = isodd(x) ? mask(A) : 0
        x = xor(x >> 1, m)

        # If we arrive back at out seed, we're done
        (x == seed(A)) && return nothing

        # Otherwise, perform a length check and exit.
        (x <= length(A)) && return (x, x)
    end
end

end # module
