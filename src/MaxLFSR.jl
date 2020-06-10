module MaxLFSR

export LFSR, FastLFSR

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

abstract type AbstractLFSR end

#####
##### Generic Length LFSR
#####
struct LFSR <: AbstractLFSR
    len::Int
    mask::Int
    seed::Int
end

function Base.show(io::IO, A::T) where {T <: AbstractLFSR}
    print(io, "$(string(T)) for 1:$(length(A)) starting at $(seed(A))")
end


"""
    LFSR(length; seed = 1)

Construct a maximum length shift register that will randomly cycle once through the numbers
`1` to `length`.

Keyword argument `seed` defines the starting point for the LFSR.

Example
-------
```julia
# Standard LFSR
julia> A = LFSR(10)
LFSR for 1:10 starting at 1

julia> for i in A
           println(i)
       end
1
9
7
10
5
6
3
8
4
2

# Change the starting location
julia> A = LFSR(10; seed = 7)
LFSR for 1:10 starting at 7

julia> for i in A
           println(i)
       end
7
10
5
6
3
8
4
2
1
9
```
"""
function LFSR(length::Integer; seed = 1)
    # Bounds checking on `seed`
    if seed < 1 || seed > length
        throw(ArgumentError("Expected `seed` to be between 1 and `length`"))
    end

    # Find the number of bits needed to represent length
    bits = nbits(length)
    mask = FEEDBACK[bits]
    return LFSR(length, mask, seed)
end

Base.eltype(L::AbstractLFSR) = Int
Base.length(L::AbstractLFSR) = L.len
mask(L::AbstractLFSR) = L.mask
seed(L::AbstractLFSR) = L.seed

# Iterator Interface
@inline Base.iterate(A::AbstractLFSR) = (seed(A), seed(A))
@inline function Base.iterate(A::AbstractLFSR, x)
    # Iterate until we reach a result that is within the correct range.
    while true
        x = step(A, x)

        # If we arrive back at out seed, we're done
        (x == seed(A)) && return nothing

        # Otherwise, perform a length check and exit.
        (x <= length(A)) && return (x, x)
    end
end

@inline function step(A::AbstractLFSR, x)
    m = isodd(x) ? mask(A) : 0
    return xor(x >> 1, m)
end

#####
##### Fast LFSR
#####
struct FastLFSR <: AbstractLFSR
    len::Int
    mask::Int
    seed::Int
end

"""
    FastLFSR(length; seed = 1)

Construct a **fast** maximum length shift register that will randomly cycle once through the numbers
`1` to `length`.
**NOTE:** This type requires `ispow2(length + 1) == true`.

Keyword argument `seed` defines the starting point for the LFSR.

Example
-------
```julia
# Standard FastLFSR
julia> A = FastLFSR(15)
LFSR for 1:10 starting at 1

julia> println.(A);
1
9
13
15
14
7
10
5
11
12
6
3
8
4
2

# Change the starting location
julia> A = LFSR(15; seed = 7)
FastLFSR for 1:15 starting at 7

julia> println.(A);
7
10
5
11
12
6
3
8
4
2
1
9
13
15
14

# Errors if length is incorrect.
julia> FastLFSR(10)
ERROR: ArgumentError: FastLFSR expects `ispow2(length + 1) == true`
```
"""
function FastLFSR(length::Integer; seed = 1)
    # Check that `length` is a power of 2
    if !ispow2(length + 1)
        throw(ArgumentError("FastLFSR expects `ispow2(length + 1) == true`"))
    end

    # Because we're restricted to a minimum of 4 bits, the minimum length we can provide
    # is 15
    if length < 15
        throw(ArgumentError("Length must be greater than 15!"))
    end

    # Bounds checking on `seed`
    if seed < 1 || seed > length
        throw(ArgumentError("Expected `seed` to be between 1 and `length`"))
    end

    # Find the number of bits needed to represent length
    bits = nbits(length)
    mask = FEEDBACK[bits]
    return FastLFSR(length, mask, seed)
end

@inline function Base.iterate(A::FastLFSR, x)
    x = step(A, x)
    return (x == seed(A)) ? nothing : (x, x)
end

end # module
