export Neuron, Network, connectDense, connectDenseNoBias, build!, process, layers_size

## Neuron
mutable struct Neuron
    coordinates::Array{Float64}
end

function Neuron(dim::Int64)
    Neuron(rand(Float64, dim))
end

## Network
function connectDense(layer_1::Array{Neuron}, layer_2::Array{Neuron}, func::String="debug")
    dim = length(layer_1[1].coordinates) - 1
    l1 = length(layer_1)
    l2 = length(layer_2)
    dist = weight_func[func]
    weights=[]
    for j in 1:l2
        col=[dist(layer_1[i].coordinates[1:dim], layer_2[j].coordinates[1:dim]) for i=1:l1]
        # println(col)
        if weights == []
            weights = col
        else
            weights = hcat(weights, col)
        end
    end
    weights'
end

function connectDenseNoBias(layer_1::Array{Neuron}, layer_2::Array{Neuron}, func::String="debug")
    l1 = length(layer_1)
    l2 = length(layer_2)
    dist = weight_func[func]
    weights=[]
    for j in 1:l2
        col=[dist(layer_1[i].coordinates, layer_2[j].coordinates) for i=1:l1]
        # println(col)
        if weights == []
            weights = col
        else
            weights = hcat(weights, col)
        end
    end
    weights'
end

function layers_size(C::Chain)
    layers = []
    s::Tuple = (0, 0)
    for d in C
        s = size(d.W) # get size of the weights matrix
        push!(layers, s[2])
    end
    push!(layers, s[1]) # output layer
    layers
end


function build!(ind::GENEIndiv, cfg::NamedTuple)
    neurons = split_genome(ind.genes, cfg.layers, cfg.dim)
    func = flux_active_dict[cfg.activ_func]
    layers = []
    dist = cfg.function
    if cfg.d_bias == 1
        # Create the network
        for i in 1:length(cfg.layers)-1
            w = connectDense(neurons[i], neurons[i+1], dist)
            b = [n.coordinates[end] for n in neurons[i+1]]
            d = Dense(w, b, func)
            push!(layers, d)
        end
    elseif cfg.d_bias == 0
        # Create the network
        for i in 1:length(cfg.layers)-1
            w = connectDenseNoBias(neurons[i], neurons[i+1], dist)
            b = zeros(cfg.layers[i+1])
            d = Dense(w, b, func)
            push!(layers, d)
        end
    else
        throw(ArgumentError("Invalid d_bias argument"))
    end
    ind.network = Chain(layers...)
    ind
end

function process(ind::GENEIndiv, X::AbstractArray)
    process(ind.network, X)
end

function process(net, X::AbstractArray)
    net(X)
end
