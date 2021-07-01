i = parse(Int64, ARGS[1])
println("> Run ", i)

using Pkg
Pkg.activate(".")
using Cambrian
using GENE
get_scripts()

# Config
cfg = get_config("cfg/atari_ram.yaml")
cfg_i= (id=string(cfg.id, "-run_", i), )
cfg = merge(cfg, cfg_i)

e = set_atari(cfg; log_suffix=string("_", i), seed=i)
println(length(e.population[1].genes), " genes")
println("Layers: ", e.config.layers)

run!(e)
best = e.elites[end]
println(i, " > Fitness: ", best.fitness)
