export save_gen, load_gen!, string, show
using JSON
import Base: show

## Indiv to JSON
function get_name(func)
    for (name, f) in pairs(flux_active_dict)
        if f == func
            return name
        end
    end
end

function get_name(dict::Dict)
    new_dict = Dict()
    for (k, v) in pairs(dict)
        new_dict[k]=get_name(v)
    end
    new_dict
end

function fitness_value(f::Float64)
	if f == -Inf
		"-Inf"
	end
	string(f)
end

function Base.string(indiv::GENEIndiv)
	if isnothing(indiv.network)
		d = Dict(
		"Type"=>"GENE",
	    "Genes"=>indiv.genes,
	    "Fitness"=>fitness_value.(indiv.fitness),
	    "Layers"=>[],
		"Dim"=>1,
		"Activ_func"=>"No network"
	    )
	else
		layers = layers_size(indiv.network)
		dim = length(indiv.genes) / sum(layers)
		d = Dict(
		"Type"=>"GENE",
	    "Genes"=>indiv.genes,
	    "Fitness"=>fitness_value.(indiv.fitness),
	    "Layers"=> layers,
		"Dim"=> dim,
		"Activ_func"=>get_name(indiv.network[1].σ)
	    )
	end
    JSON.json(d)
end

function show(io::IO, ind::GENEIndiv)
    print(io, Base.string(ind))
end

## Load
"""
Function to load an entire population from a gen folder.
The evolution need to be initialized first.
"""
function load_ES_gen!(e::AbstractEvolution, path::String)
	individualNameList = readdir("gens/$path")

	indString = read("gens/$path/$(individualNameList[1])", String)
	dict = JSON.parse(indString)
	if e.config.layers != dict["Layers"]
		cfg_2::NamedTuple = (layers=dict["Layers"], )
	    e.config = merge(e.config, cfg_2)
	end

	T=GENEIndiv
	if e.config.individual == "flatnet"
		T = FlatNetIndiv
	end

	individualList::Array{AbstractESIndividual} = []
	for i in eachindex(individualNameList)
		indString = read("gens/$path/$(individualNameList[i])", String)
		ind = T(e.config, indString)
		build!(ind, e.config)
		push!(individualList,ind)
	end
	e.elites = individualList
end

function load_gen!(e::xNES, path::String)
	load_ES_gen!(e, path)
end

function load_gen!(e::sNES, path::String)
	load_ES_gen!(e, path)
end

function load_gen!(e::CMAES, path::String)
	load_ES_gen!(e, path)
end
