import EvolutionaryStrategies: populate, evaluate
import Cambrian: populate, evaluate, log_gen, save_gen
export populate, evaluate, save_gen, chose_evolution, chose_individual

## Specific logging and saving methods

"log a generation, including max, mean, and std of each fitness dimension"
function log_ES_gen(e::AbstractEvolution)
    for d in 1:e.config.d_fitness
        maxs = map(i->i.fitness[d], e.elites)
        with_logger(e.logger) do
            @info Formatting.format("{1:04d},{2:e},{3:e},{4:e},{5:e}",
                                    e.gen, maximum(maxs), mean(maxs), std(maxs), e.config.n_population)
        end
    end
    flush(e.logger.stream)
end

"save the population in gens/"
function save_ES_gen(e::AbstractEvolution)
    path = Formatting.format("gens/{1}/{2:04d}", e.config.id, e.gen)
    mkpath(path)
    sort!(e.elites)
    for i in eachindex(e.elites)
        f = open(Formatting.format("{1}/{2:04d}.dna", path, i), "w+")
        write(f, string(e.elites[i]))
        close(f)
    end
    println("Saved gen ", e.gen)
end

## Adding a new optimizer:
# 1) Add the populate, evaluate, log_gen and save_gen methods like xNES/sNES
# 2) Add a load_gen! method in src/loader.jl
# 3) Add your method to chose_evolution in this file
# 4)Add a test to test/evolution.jl

function chose_evolution(name)
    n = lowercase(name)
    if n == "snes"
        sNES
    elseif n == "xnes"
        xNES
    elseif n == "cmaes"
        CMAES
    elseif n == "random"
        RandomSearch
    else
        throw(DomainError(name, "invalid optimizer name"))
    end
end

function chose_individual(name::String, cfg::NamedTuple)
    n = lowercase(name)
    T::Type=GENEIndiv
    d::String=""
    if n == "flatnet"
        T=FlatNetIndiv
        d=""
    elseif n == "gene"
        T=GENEIndiv
        d="exp_decay"
    elseif n == "xd-gene"
        T=GENEIndiv
        d="exp_decay"
    elseif n == "l2-gene"
        T=GENEIndiv
        d="euclidean"
    elseif n == "sl2-gene"
        T=GENEIndiv
        d="signed"
    elseif n == "sxd-gene"
        T=GENEIndiv
        d="signed_exp_decay"
    elseif n == "rl2-gene"
        T=GENEIndiv
        d="ratio"
    elseif n == "pl2-gene"
        T=GENEIndiv
        d="product"
    elseif n == "sc-pl2-gene"
        T=GENEIndiv
        d="scaled_product"
    elseif n == "sl2-gene"
        T=GENEIndiv
        d="signed_euclidean"
    elseif n == "tag-gene"
        T=GENEIndiv
        d="grn"
    else
        throw(DomainError(name, "invalid individual name"))
    end
    cfg_2::NamedTuple = (var"function"=d, )
    cfg = merge(cfg, cfg_2)
    T, cfg
end

function chose_individual(cfg::NamedTuple)
    chose_individual(cfg.individual, cfg)
end

## xNES
function populate(e::xNES)
    xnes_populate(e)
    build!.(e.population, Ref(e.config))
    e
end

function evaluate(e::xNES)
    if e.gen == 0 || isnothing(e.population[1].network)
        build!.(e.population, Ref(e.config))
    end
    # println(length(e.population))
    fitness_evaluate(e, e.fitness)
end

function log_gen(e::xNES)
    log_ES_gen(e)
end

function save_gen(e::xNES)
    save_ES_gen(e)
end

## sNES
function populate(e::sNES)
    snes_populate(e)
    build!.(e.population, Ref(e.config))
    e
end

function evaluate(e::sNES)
    if e.gen == 0 || isnothing(e.population[1].network)
        build!.(e.population, Ref(e.config))
    end
    # println(length(e.population))
    fitness_evaluate(e, e.fitness)
end

function log_gen(e::sNES)
    log_ES_gen(e)
end

function save_gen(e::sNES)
    save_ES_gen(e)
end

## CMAES
function populate(e::CMAES)
    CMAES_populate(e)
    build!.(e.population, Ref(e.config))
    e
end

function evaluate(e::CMAES)
    if e.gen == 0 || isnothing(e.population[1].network)
        build!.(e.population, Ref(e.config))
    end
    # println(length(e.population))
    fitness_evaluate(e, e.fitness)
end

function log_gen(e::CMAES)
    log_ES_gen(e)
end

function save_gen(e::CMAES)
    save_ES_gen(e)
end

## CMAES
function populate(e::RandomSearch)
    RandomSearch_populate(e)
    build!.(e.population, Ref(e.config))
    e
end

function evaluate(e::RandomSearch)
    if e.gen == 0 || isnothing(e.population[1].network)
        build!.(e.population, Ref(e.config))
    end
    # println(length(e.population))
    fitness_evaluate(e, e.fitness)
end

function log_gen(e::RandomSearch)
    log_ES_gen(e)
end

function save_gen(e::RandomSearch)
    save_ES_gen(e)
end
