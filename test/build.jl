@testset "Split genome" begin
    cfg = get_config("cfg/test_ES.yaml")
    ind = GENEIndiv(cfg)

    s = split_genome(ind.genes, cfg.layers, cfg.dim)
    @test length(s) == length(cfg.layers)
    @test all(length.(s)==cfg.layers)
end

@testset "Connect" begin
    cfg = get_config("cfg/test_ES.yaml")
    ind = GENEIndiv(cfg)
    s = split_genome(ind.genes, cfg.layers, cfg.dim)

    w = connectDense(s[1], s[2])
    @test size(w) == (cfg.layers[2], cfg.layers[1])

    w = connectDenseNoBias(s[1], s[2])
    @test size(w) == (cfg.layers[2], cfg.layers[1])

    input = [1, 2]
    @test size(input) == (cfg.layers[1], )
    out = w * input
    @test size(out) == (cfg.layers[2], )
end

@testset "Build" begin
    cfg = get_config("cfg/test_ES.yaml")
    ind = GENEIndiv(cfg)
    build!(ind, cfg)
    test_consistent_indiv(ind, cfg, true)
end

@testset "Process" begin
    cfg = get_config("cfg/test_ES.yaml")
    ind = GENEIndiv(cfg)
    build!(ind, cfg)

    X = [1, 2]
    y = process(ind, X)
    test_consistent_indiv(ind, cfg, true)
    @test typeof(y) == Array{Float64,1}
    @test length(y) == cfg.layers[end]
end
