using OrderedBinning
using Test

@testset "non-strinct, zero tolerance" begin
    boundaries = 0:3
    ob = ordered_bins(boundaries; strict = false)
    @test ob(-1) == 0
    @test ob(0) == 1
    @test ob(0.5) == 1
    @test ob(3) == 3
    @test ob(4) == 4
    for _ in 1:100
        x = rand(Bool) ? rand(0:3) : rand() * 3.0
        i = ob(x)
        @test boundaries[i] ≤ x ≤ boundaries[i + 1]
        if x < 3
            @test x < boundaries[i + 1]
        end
    end
end

@testset "strint, 0.5 tolerance" begin
    boundaries = 0:3
    ob = ordered_bins(boundaries; strict = true, tolerance = 0.5)
    @test_throws DomainError ob(-1)
    @test ob(0) == 1
    @test ob(0.5) == 1
    @test ob(3) == 3
    @test ob(3.5) == 3
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
