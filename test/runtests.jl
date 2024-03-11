using OrderedBinning: ordered_bins, OrderedBinning, bin_range, make_increasing
using Test

@testset "error, zero halo" begin
    boundaries = 0:3
    ob = ordered_bins(boundaries)
    @test @inferred bin_range(ob) == 1:3
    @test_throws DomainError ob(-1) == 0
    @test @inferred ob(0) == 1
    @test ob(0.5) == 1
    @test ob(1) == 2
    @test ob(2) == 3
    @test ob(2.1) == 3
    @test ob(3) == 3
    @test_throws DomainError ob(4)
    for _ in 1:100
        x = rand(Bool) ? rand(0:3) : rand() * 3.0
        i = ob(x)
        @test boundaries[i] ≤ x ≤ boundaries[i + 1]
        if x < 3
            @test x < boundaries[i + 1]
        end
    end
end

@testset "don't error, asymmetric tolerance, break to left" begin
    boundaries = 0:3
    ob = ordered_bins(boundaries, :left;
                      halo_below = 0.5, error_below = false,
                      halo_above = 2, error_above = false)
    @test @inferred bin_range(ob) == 0:4
    @test ob(-1) == 0
    @test ob(-0.5) == 1
    @test ob(0) == 1
    @test ob(0.5) == 1
    @test ob(2) == 2
    @test ob(3.5) == 3
    @test ob(6) == 4
    for _ in 1:100
        x = rand(Bool) ? rand(0:3) : rand() * 3.0
        i = ob(x)
        @test boundaries[i] ≤ x ≤ boundaries[i + 1]
        if x > 0
            @test x > boundaries[i]
        end
    end
end

@testset "make_increasing" begin
    @test make_increasing([1,2,3]) == [1,2,3]
    @test make_increasing([1,1,2,1,3]) == [1,2,3]
    @test make_increasing([1,1,2,2,3]) == [1,2,3]
end

using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(OrderedBinning, target_modules=(OrderedBinning,))))
end

@testset "QA with Aqua" begin
    import Aqua
    Aqua.test_all(OrderedBinning; ambiguities = false)
    # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
    Aqua.test_ambiguities(OrderedBinning)
end
