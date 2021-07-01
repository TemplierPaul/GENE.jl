include("../scripts/gym.jl")

 @testset "Load" begin
    cfg = get_config("cfg/gym.yaml")
    e = set_gym(cfg)
    load_gen!(e, "2020-10-13T12_40_05_816/0100")
    println(get_best(e).fitness)
    render_elite(e)
end
