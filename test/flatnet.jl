using Flux

@testset "Flat net" begin
    cfg = get_config("cfg/test_ES.yaml")
    p = get_params_nb(cfg.layers)
    println(cfg.layers, " -> ", p)

    cfg_2::NamedTuple = (n_genes=p, )
    cfg = merge(cfg, cfg_2)
    println(cfg)
    ind = FlatNetIndiv(cfg)
    println(length(ind.genes))
    build!(ind, cfg)

    p = collect(Base.Iterators.flatten(Flux.params(ind.network)))
    println(p)
    println(ind.genes)
    delta = 0.0001
    @test abs(sum(p) - sum(ind.genes)) <= delta
    @test all(abs.(p .- ind.genes) .<= delta)

    x = [1, 2]
    y = process(ind, x)
    @test length(y)==cfg.layers[end]
end

include("../scripts/gym.jl")

@testset "Gym Flat" begin
    cfg = get_config("cfg/gym.yaml")
    cfg1 = (individual="flatnet", )
    cfg = merge(cfg, cfg1)

    e = set_gym(cfg)
    config_i::NamedTuple = (n_gen=3, n_genes=get_params_nb(e.config.layers), optimizer="snes")
    e.config = merge(e.config, config_i)
    println(e.config)

    @test typeof(e.population[1]) == FlatNetIndiv
    @test length(e.population[1].genes) == e.config.n_genes
    println(length(e.population[1].genes), " genes")
    println("Layers: ", e.config.layers)
    run!(e)
end
