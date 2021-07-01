# println("> Threads: ", Threads.nthreads())

using Pkg
Pkg.activate(".")
using Cambrian
using GENE
using HTTP
using Dates
using EvolutionaryStrategies
using Random
include("scripts/atari_ram.jl")

file_name = "cfg.txt"

function parse_txt(name)
    cfg = []
    open(name) do file
        for ln in eachline(file)
            l = split(ln)
            if length(l)>0 && l[1][1]!= '#'
                push!(cfg, l)
            end
        end
    end
    cfg
end

function generate_cfg(s::String, i=0)
    # Generate 1 config from 1 line and a seed
    l = split(s)
    if length(l)>0 && l[1][1]!= '#'
        if i!=0
            l[end]=i
        end
        c = generate_cfg(l, i)
    end
    c
end

function generate_cfg(l::Array)
    # Generate all the configs from 1 line
    cfgs = []
    # Generate a config for each run
    i0 = parse(Int,l[10])
    imax = i0 + parse(Int,l[9]) -1
    for i in i0:imax
        push!(cfgs, generate_cfg(l, i))
    end
    cfgs
end

function generate_cfg(l::Array, seed=0, dim=2)
    # Generate 1 config from a parsed line and its seed
    cfg=(layers=[0, parse(Int,l[5]), parse(Int,l[6]), 0],
        activ_func=string(l[7]),
        d_space=dim,
        d_bias=1,
        var"function"="exp_decay",
        optimizer=string(l[2]),
        individual=string(l[1]),
        n_genes=0,
        seed=seed,
        d_fitness=1,
        n_elite=5,
        n_gen=parse(Int,l[8]),
        log_gen=1,
        save_gen=30,
        m_rate=0.3,
        env_name = string(l[4]),
        env_lib = string(l[3]),
        id=string(replace(string(Dates.now()), r"[]\.:]" => "_"), "-run_", seed),
        a=10,
        b=-5
    )
    cfg
end

function run_config(c::NamedTuple, log_suffix="")
    machine = gethostname()
    println(" > ", c.env_name)
    # println(c)
    # e::AbstractEvolution
    if c.env_lib == "atari"
        e = set_atari(c, log_suffix=string(log_suffix, "-run_", c.seed))
    elseif c.env_lib == "gym"
        e = set_gym(c, log_suffix=string(log_suffix, "-run_", c.seed))
    else
        e = set_gym(c, log_suffix=string(log_suffix, "-run_", c.seed))
        print(c.env_lib, " not recognised")
    end
    run!(e)
end


function run_config(s::String, i=0)
    c = generate_cfg(s, i)
    run_config(c)
end

function start_run(file_name)
    machine = gethostname()

    l = parse_txt(file_name)
    cfg=[]
    for i in 1:length(l)
        cfg = vcat(cfg, generate_cfg(l[i]))
    end

    println(" > ", length(cfg), " runs")

    a::Array{Any,1} = zeros(length(cfg))
    Threads.@threads for i in 1:length(cfg)
        a[i] = Threads.threadid()
        c = cfg[i]
        run_config(c)

    end
    print(a)
end




## Main

if abspath(PROGRAM_FILE) == @__FILE__
    println(ARGS)
    if length(ARGS)==0
        start_run(file_name)
    else
        l = length(ARGS)
        seed = ARGS[l-1]
        dim = ARGS[l]
        println("SEED ", seed, " | DIM ", dim)
        c = generate_cfg(ARGS, parse(Int64, seed), parse(Int64, dim))
        # println(c)
        suffix = ""
        if ARGS[1] != "flatnet"
            suffix = string("dim-", dim)
        end
        run_config(c, suffix)
    end

end
