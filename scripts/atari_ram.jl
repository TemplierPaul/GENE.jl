using ArcadeLearningEnvironment
import Random

export run_atari, render_atari_elite, play_atari, set_atari

```
Playing Atari games using NES on RAM values
If an individual is provided using --ind, an evaluation loop with rendering will
be performed. Otherwise, an evolution is launched. By default this uses seed=0
for each evaluation for a deterministic environment, but this can be removed for
a stochastic and more realistic result.
Code adapted from https://github.com/d9w/CartesianGeneticProgramming.jl/blob/master/scripts/atari_ram.jl
```

# Play one game of Atari
function play_atari(ind::AbstractESIndividual, rom_name::String; seed=0, max_frames=18000, render=false)
  ale = ALE_new()
  setInt(ale, "random_seed", Cint(seed))
  if render
      setBool(ale, "display_screen", true)
      setBool(ale, "sound", true)
  end
  loadROM(ale, rom_name)
  actions = getMinimalActionSet(ale)
  reward = 0.0
  frames = 0
  while ~game_over(ale)
      ram = getRAM(ale) ./ typemax(UInt8)
      output = process(ind, ram)
      action = actions[argmax(output)]
      reward += act(ale, action)
      frames += 1
      if frames > max_frames
          break
      end
  end
  ALE_del(ale)
  [reward]
end

function concat(sep::String)
    function f(a, b)
        string(a, sep, b)
    end
    f
end

function set_evo(cfg::NamedTuple, fitness::Function; log_suffix::String="")
    cfg = set_cfg(cfg) # update gene number

    T, cfg = chose_individual(cfg.individual, cfg)
    println(" >>>>> Experiment configuration <<<<<")
    println(cfg)

    #Clear log file
    filename_params = [cfg.individual, cfg.optimizer, cfg.env_name, foldl(concat("-"), cfg.layers), cfg.activ_func]
    if :file_id in keys(cfg)
        push!(filename_params, cfg.file_id)
    end
    if log_suffix != ""
        push!(filename_params, log_suffix)
    end

    configname = foldl(concat("_"), filename_params)
    logfile = string("logs/", configname, ".csv")
    io = open(logfile, "w")
    close(io)

    println("Logs > ", logfile)

    cfg_2::NamedTuple = (configname=configname, id=string(cfg.id, configname))
    cfg = merge(cfg, cfg_2)

    evo_T::Type = chose_evolution(cfg.optimizer)
    e = evo_T(cfg, fitness;T=T, logfile=logfile)

    e
end

function set_atari(cfg::NamedTuple; seed::Int64=0, log_suffix::String="")
    ale = ALE_new()
    loadROM(ale, cfg.env_name)
    n_in = length(getRAM(ale))
    n_out = length(getMinimalActionSet(ale))
    ALE_del(ale)

    cfg.layers[1]=n_in
    cfg.layers[end]=n_out
    Random.seed!(seed)

    fit(i::AbstractESIndividual) = play_atari(i, cfg.env_name)
    set_evo(cfg, fit; log_suffix=log_suffix)
end



function run_atari(cfg::NamedTuple; log_suffix::String="")
    e = set_atari(cfg, log_suffix=log_suffix)
    println(length(e.population[1].genes), " genes")
    println("Layers: ", e.config.layers)
    run!(e)
    e
end

function run_atari()
    cfg = get_config("cfg/atari_ram.yaml")
    run_atari(cfg)
end

function multithread_atari(cfg::NamedTuple, n::Int64=2; log_suffix::String="")
    evos = []
    for i in 1:n
        cfg_i::NamedTuple = (id=string(cfg.id, "-run_", i), )
        cfg_i = merge(cfg, cfg_i)
        e = set_atari(cfg, log_suffix=string(log_suffix, "_", i), seed=i)
        push!(evos, e)
        println(length(e.population[1].genes), " genes")
        println("Layers: ", e.config.layers)
    end
    Threads.@threads for i in 1:n
        run!(evos[i])
   end
   evos
end

function render_atari_elite(e::AbstractEvolution)
    println("Fitness of the last Elite")
    env_name = e.config.env_name
    i = e.elites[end]
    println("Fitness: ", i.fitness)
    play_atari(i, env_name; render=true)
end
