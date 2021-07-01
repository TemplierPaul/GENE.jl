function test_consistent_indiv(ind::GENEIndiv, cfg::NamedTuple, built::Bool)
    @test length(ind.genes) == sum(cfg.layers) * cfg.dim
    if built
        @test !isnothing(ind.network)
        n = ind.network
        # Layers
        @test length(n) == length(cfg.layers) - 1
        @test all(layers_size(n) .== cfg.layers)
    end
end


@testset "Individual" begin
    layers = [2, 4, 3]
    dim = 2
    d_fitness=1
    ind = GENEIndiv(layers, dim, d_fitness)

    cfg::NamedTuple=(layers=layers, dim=dim, d_fitness=d_fitness)

    test_consistent_indiv(ind, cfg, false)
end

@testset "Individual from cfg" begin
    cfg = get_config("cfg/test_ES.yaml")
    ind = GENEIndiv(cfg)

    test_consistent_indiv(ind, cfg, false)
end

@testset "Save" begin
    cfg = get_config("cfg/test_ES.yaml")
    ind = GENEIndiv(cfg)
    build!(ind, cfg)
    show(IOBuffer(), ind)
end
