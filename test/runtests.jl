using MaxLFSR
using Test
using Random

# Set the seed for consistent trials
seed!(123)

@testset "MaxLFSR.jl" begin
    # Test `nbits`
    @test MaxLFSR.nbits(1) == 4
    @test MaxLFSR.nbits(2) == 4
    @test MaxLFSR.nbits(15) == 4
    @test MaxLFSR.nbits(16) == 5
    @test MaxLFSR.nbits(32) == 6

    @test_throws ArgumentError MaxLFSR.nbits(0)
    @test_throws ArgumentError MaxLFSR.nbits(typemax(UInt64))

    # Iterate through powers of 2 from 2 to 30 with random seeds.
    # Then generate some random lengths in the same rangs.
    nloops = 3
    for i in 1:nloops
    end
end
