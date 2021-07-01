export GENEIndiv, flatten, split_genome

## Individual
mutable struct GENEIndiv <: AbstractESIndividual
    genes::Array{Float64}
    fitness::Array{Float64}
    network
end

function GENEIndiv(genes::Array{Float64}, fitness::Array{Float64})
	GENEIndiv(genes, fitness, nothing)
end

function GENEIndiv(layers::Array, dim::Int64, fit_dim::Int64=1)
    fitness = -Inf .* ones(fit_dim)
    genes::Array{Float64} = rand(Float64, sum(layers)*dim)
    GENEIndiv(genes, fitness, nothing)
end

function GENEIndiv(cfg::NamedTuple)
    GENEIndiv(cfg.layers, cfg.dim, cfg.d_fitness)
end

function GENEIndiv(genes::Array, cfg::NamedTuple)
    fitness = -Inf .* ones(cfg.d_fitness)
    GENEIndiv(genes, fitness, nothing)
end

function get_child(parent::GENEIndiv, genes::Array{Float64})
    layers = Integer.(length.(parents.neurons))
    dim = length(parents.neurons[1][1])
    fitness=-Inf * ones(length(parent.fitness))
    GENEIndiv(genes, fitness, nothing)
end

## Parse from a dna file

function parse_fitness(s::String)
	if s == "-Inf"
		-Inf
	else
		parse(Float64, s)
	end
end

function GENEIndiv(cfg::NamedTuple, s::String)
    dict = JSON.parse(s)
	genes = dict["Genes"]
    fitness = parse_fitness.(dict["Fitness"])
    i = GENEIndiv(genes, fitness, nothing)
	i
end

## Transform from / to Array for CMA-ES

function flatten(ind::GENEIndiv, cfg::NamedTuple)
    n = collect(Iterators.flatten(ind.neurons))  # Array{Neuron}
    n = getfield.(n, :coordinates)  # Array{Array{Float64}}
    collect(Iterators.flatten(n))        # Array{Float64}
end

function split_genome(coordinates::Array, layers::Array, dim::Int64)
    # println("Genome size: ", length(coordinates))
    low_bound = 1
    up_bound = 1
    genome::Array{Array{Neuron}}=[]
    for l_size in layers
        up_bound = low_bound + l_size * dim - 1 # Max index
        # println("layer: ", low_bound, " ", up_bound)
        l_coordinates = coordinates[low_bound:up_bound]
        layer = split_genome(l_coordinates, l_size)
        push!(genome, layer)
        low_bound = up_bound+1
    end
    genome
end

function split_genome(coordinates::Array, layer_size::Int64)
    dim = Integer(length(coordinates)/layer_size)

    neurons::Array{Neuron}=[]
    for i in 1:layer_size
        # println("g > ", 1 + (i-1)*dim, " ", i * dim)
        n_coordinates = coordinates[(1 + (i-1)*dim):i*dim]
        n = Neuron(n_coordinates)
        push!(neurons, n)
    end
    neurons
end
