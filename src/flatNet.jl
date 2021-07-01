using Flux
using Cambrian
import Base: show
export FlatNetIndiv, load_weights_from_array!, build!, process, string, show

function load_weights_from_array!(model::Chain, params::Array{Float64})
    nb_params = sum(length.(Flux.params(model)))
    nb_weight = length(params)
    if nb_params > nb_weight
        throw("Your weight vector is not long enough")
    elseif nb_params < nb_weight
        @warn("Your weight vector have more element than you have parameters to change")
    end
    ps = Flux.params(model)
    layer_idx = 1
    curr_idx = 1
    for layer in ps
        for i in eachindex(layer)
            ps[layer_idx][i] = params[curr_idx]
            curr_idx += 1
        end
        layer_idx +=1
    end
end

function set_model_params!(model::Chain, params::Array{Float64})
    p = 1
    layers = Flux.params(model)
    for li in 1:length(layers)
        copyto!(layers[li], 1, params, p, length(layers[li]))
        p += length(layers[li])
    end
end


mutable struct FlatNetIndiv <: AbstractESIndividual
    genes::Array{Float64}
    fitness::Array{Float64}
    network
end

function FlatNetIndiv(genes::Array{Float64}, fitness::Array{Float64})
	FlatNetIndiv(genes, fitness, nothing)
end

function FlatNetIndiv(layers::Array, dim::Int64, fit_dim::Int64=1)
    fitness = -Inf .* ones(fit_dim)
    genes::Array{Float64} = rand(Float64, get_params_nb(layers))
    FlatNetIndiv(genes, fitness, nothing)
end

function FlatNetIndiv(cfg::NamedTuple)
	fitness = -Inf .* ones(cfg.d_fitness)
	genes::Array{Float64} = rand(Float64, cfg.n_genes)
    FlatNetIndiv(genes, fitness, nothing)
end

function FlatNetIndiv(genes::Array, cfg::NamedTuple)
    fitness = -Inf .* ones(cfg[:d_fitness])
    i = FlatNetIndiv(genes, fitness, nothing)
	i
end

function FlatNetIndiv(cfg::NamedTuple, s::String)
    dict = JSON.parse(s)
	genes = dict["Genes"]
    fitness = parse_fitness.(dict["Fitness"])
    i = FlatNetIndiv(genes, fitness, nothing)
	i
end

# function get_child(parent::FlatNetIndiv, genes::Array{Float64})
#     layers = Integer.(length.(parents.neurons))
#     dim = length(parents.neurons[1][1])
#     fitness=-Inf * ones(length(parent.fitness))
#     FlatNetIndiv(genes, fitness, nothing)
# end

function build!(ind::FlatNetIndiv, cfg::NamedTuple)
    func = flux_active_dict[cfg[:activ_func]]

    # Create the network
    layers = []
    for i in 1:length(cfg.layers)-1
        d = Dense(cfg.layers[i], cfg.layers[i+1], func)
        push!(layers, d)
    end
    ind.network = Chain(layers...)
	# Set weights
	set_model_params!(ind.network, ind.genes)
    ind
end

function process(ind::FlatNetIndiv, X::AbstractArray)
    process(ind.network, X)
end

function process(net, X::AbstractArray)
    net(X)
end

function Base.string(indiv::FlatNetIndiv)
	if isnothing(indiv.network)
		d = Dict(
		"Type"=>"FlatNet",
	    "Genes"=>indiv.genes,
	    "Fitness"=>fitness_value.(indiv.fitness),
	    "Layers"=>[],
		"Activ_func"=>"No network"
	    )
	else
		layers = layers_size(indiv.network)
		dim = length(indiv.genes) / sum(layers)
		d = Dict(
		"Type"=>"FlatNet",
	    "Genes"=>indiv.genes,
	    "Fitness"=>fitness_value.(indiv.fitness),
	    "Layers"=> layers,
		"Activ_func"=>get_name(indiv.network[1].σ)
	    )
	end
    JSON.json(d)
end

function show(io::IO, ind::FlatNetIndiv)
    print(io, Base.string(ind))
end
