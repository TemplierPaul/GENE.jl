import Cambrian.get_config
export get_config, activ_dict, get_scripts, get_params_nb, create_model, set_cfg
using YAML
using Dates
using Flux

function Cambrian.get_config(cfg_file::String; kwargs...)
    cfg_dict = YAML.load_file(cfg_file)
    for (k, v) in kwargs
        cfg_dict[String(k)] = v
    end
    # generate id, use date if no existing id
    if ~(:id in keys(cfg_dict))
        cfg_dict["id"] = replace(string(Dates.now()), r"[]\.:]" => "_")
    end
    cfg = Cambrian.get_config(cfg_dict)
    set_cfg(cfg)
end

function set_cfg(cfg::NamedTuple)
    if :layers in keys(cfg)
        layers = cfg.layers
    else
        layers = [0, cfg.hidden_layer_1, cfg.hidden_layer_2, 0]
    end

    dim = cfg.d_space + cfg.d_bias
    n_genes=0
    if cfg.individual == "flatnet"
        n_genes = get_params_nb(layers)
    else
        n_genes = sum(layers) * dim
    end

    cfg_2::NamedTuple = (n_genes=n_genes, layers=layers, dim=dim)
    merge(cfg, cfg_2)
end

function get_params_nb(layers::Array{Int64})
    # Create the network
    model = create_model(layers, Flux.sigmoid)
    # Compute number of params
    sum(length.(Flux.params(model)))
end

function create_model(layers::Array{Int64}, func::Function)
    l = []
    len = length(layers)
    if len>2
        for i in 1:len-2
            d = Dense(layers[i], layers[i+1], func)
            push!(l, d)
        end
    end
    d = Dense(layers[len-1], layers[len], tanh) # tanh as last activation
    push!(l, d)

    Chain(l...)
end

## Activation functions

function sigmoid(x::Float64)
    1 / (1 + exp(-5 * x))
end

function ReLU(x::Float64)
    if x < 0
        0
    else
        x
    end
end

function identity_activ(x::Float64)
    x
end

function gauss(x::Float64)
    exp(-5.0 * x^2)
end

function tanh_activ(x::Float64)
    tanh(2.5 * x)
end

activ_dict = Dict(
    "sigmoid" => sigmoid,
    "ReLU" => ReLU,
    "sin" => sin,
    "cos" => cos,
    "tanh" => tanh,
    "abs" => abs,
    "identity" => identity_activ,
    "gauss" => gauss,
)

flux_active_dict = Dict(
    "sigmoid" => Flux.σ,
    "ReLU" => Flux.relu,
    "LeakyReLU" => Flux.leakyrelu,
    "sin" => sin,
    "cos" => cos,
    "tanh" => tanh,
    "abs" => abs,
    "identity" => identity_activ,
    "gauss" => gauss,
)

## Include Scripts

function get_scripts(; atari=true)
    println(pwd())
    include("scripts/gym.jl")
    atari && include("scripts/atari_ram.jl")
end
