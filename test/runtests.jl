using MaxLFSR
using Test
using Random

# Set the seed for consistent trials
Random.seed!(123)

function _fill!(A, itr)
    A .= false
    count = 0
    for i in itr
        A[i] = true
        count += 1
    end
    return count
end

@testset "MaxLFSR.jl" begin
    # Test `nbits`
    @test MaxLFSR.nbits(1) == 4
    @test MaxLFSR.nbits(2) == 4
    @test MaxLFSR.nbits(15) == 4
    @test MaxLFSR.nbits(16) == 5
    @test MaxLFSR.nbits(32) == 6

    @test_throws ArgumentError MaxLFSR.nbits(0)
    @test_throws ArgumentError MaxLFSR.nbits(typemax(UInt64))

    # Try messing with the `seed` argument
    @test_throws ArgumentError LFSR(10; seed = 0)
    @test_throws ArgumentError LFSR(10; seed = 20)

    # Test the 1 length of 1 works
    itr = LFSR(1)
    @test collect(itr) == [1]

    # Some more argument handling erros
    @test_throws ArgumentError LFSR(0)
    @test_throws ArgumentError LFSR(typemax(UInt))

    # Iterate through powers of 2 from 2 to 30 with random seeds.
    # Then generate some random lengths in the same rangs.
    nloops = 3
    for pow in 2:30
        println("Testing Length: 2 ^ $pow")
        len = 2^pow
        A = falses(len)

        for i in 1:nloops
            if i == 1
                seed = 1
            else
                seed = rand(1:len)
            end

            # Clear the tracking array
            itr = LFSR(len; seed = seed)
            runtime = @elapsed count = _fill!(A, itr)
            if i == nloops
                @show runtime
            end

            @test count == length(itr) == len
            @test all(isequal(true), A)
        end
    end

    # Test 10000 different lengths between 2 and 2^20
    A = falses(2^20)
    total = 10000
    for i in 1:total
        if iszero(mod(i, div(total, 10)))
            println("Performing Fuzz Test $i of $total")
        end

        len = rand(1:2^20)
        seed = rand(1:len)
        resize!(A, len)

        # Normal LFSR
        itr = LFSR(len; seed = seed)
        count = _fill!(A, itr)

        @test count == length(itr) == len
        @test all(isequal(true), A)
    end

    #####
    ##### FastLFSR
    #####

    @test_throws ArgumentError MaxLFSR.FastLFSR(32)
    @test_throws ArgumentError MaxLFSR.FastLFSR(7)

    # Iterate through powers of 2 from 2 to 30 with random seeds.
    # Then generate some random lengths in the same rangs.
    nloops = 3
    for pow in 4:30
        println("Testing Length: 2 ^ $pow")
        len = 2^pow - 1
        A = falses(len)

        for i in 1:nloops
            if i == 1
                seed = 1
            else
                seed = rand(1:len)
            end

            # Clear the tracking array
            itr = FastLFSR(len; seed = seed)
            runtime = @elapsed count = _fill!(A, itr)

            # Report the time for the last iteration.
            if i == nloops
                @show runtime
            end

            @test count == length(itr) == len
            @test all(isequal(true), A)
        end
    end

end
