using PyCall
using Cambrian
import Random

export run_gym, render_gym_elite, random_search_gym, play_env, multirun_gym, multithread_gym, set_gym, set_evo

"""
Demonstrates RL on Discrete gym problems like MountainCar, CartPole, Acrobot
Requires the Python package gym, which can be installed with Conda.jl:
> Conda.add("gym")
Pybullet environments can be used if the "--pybullet" flag is provided. These
require separate installation:
> Conda.add("pybullet")
Code adapted from https://github.com/d9w/CartesianGeneticProgramming.jl/blob/master/scripts/gym.jl
"""

gym = pyimport("gym")

function play_env(ind::AbstractESIndividual, env_name::String; seed::Int=0, render::Bool=false)
    env = gym.make(env_name)
    env.seed(seed)
    obs = env.reset()
    if render
        env.render(mode="human")
    end
    total_reward = 0.0
    done = false
    max_obs = 1
    # max_obs = Float64(max(-minimum(env.observation_space.low),
                          # maximum(env.observation_space.high)))
    while ~done
        action = process(ind, obs ./ max_obs)
        if hasproperty(env.action_space, :n)
            # discrete env, use argmax (python 0-based indexing)
            action = argmax(action) - 1
        else
            # continuous env, normalize outputs
            h = env.action_space.high
            l = env.action_space.low
            action = action .* (h - l) .+ l
            # println(action)
        end
        obs, reward, done, _ = env.step(action)
        if render
            env.render(mode="human")
        end
        total_reward += reward
    end
    env.close()
    [total_reward]
end

function set_gym(cfg::NamedTuple; log_suffix="", seed=0)
    env_name = cfg.env_name
    env = gym.make(env_name)
    obs = env.reset()
    n_in = length(env.observation_space.sample())
    n_out = length(env.action_space.sample())
    if hasproperty(env.action_space, :n)
        n_out = env.action_space.n
    end
    env.close

    cfg.layers[1]=n_in
    cfg.layers[end]=n_out
    Random.seed!(seed)

    fit(i::AbstractESIndividual) = play_env(i, env_name)
    set_evo(cfg, fit; log_suffix=log_suffix)
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
    println(" >>>>> HERE <<<<<")
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

function run_gym(cfg::NamedTuple)
    e = set_gym(cfg)
    println(length(e.population[1].genes), " genes")
    println("Layers: ", e.config.layers)
    run!(e)
    e
end

function run_gym()
    cfg = get_config("cfg/gym.yaml")
    run_gym(cfg)
end

function render_gym_elite(e::AbstractEvolution)
    println("Fitness of the last Elite")
    env_name = e.config.env_name
    i = e.elites[end]
    println("Fitness: ", i.fitness)
    play_env(i, env_name; render=true)
end
