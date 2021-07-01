function random_fitness(i::GENEIndiv)
    @test !isnothing(i.network)
    x = [0.0, 0.0]
    y = process(i, x)
    [randn()]
end

@testset "xNES" begin
    cfg = get_config("cfg/test_ES.yaml")
    e = xNES(cfg, random_fitness; T=GENEIndiv, logfile="logs/test.csv")

    evaluate(e)
    populate(e)
    run!(e)
end

@testset "sNES" begin
    cfg = get_config("cfg/test_ES.yaml")
    e = sNES(cfg, random_fitness; T=GENEIndiv, logfile="logs/test.csv")

    evaluate(e)
    populate(e)
    run!(e)
end

@testset "CMAES" begin
    cfg = get_config("cfg/test_ES.yaml")
    e = CMAES(cfg, random_fitness; T=GENEIndiv, logfile="logs/test.csv")

    evaluate(e)
    populate(e)
    run!(e)
end
