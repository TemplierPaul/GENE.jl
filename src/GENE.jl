module GENE

using LinearAlgebra
using Statistics
using Cambrian
using Logging
using Random
using EvolutionaryStrategies

import Formatting

include("utils.jl")
include("individual.jl")

include("weight_functions.jl")
include("network.jl")

include("evolution.jl")
include("flatNet.jl")

include("loader.jl")

end
