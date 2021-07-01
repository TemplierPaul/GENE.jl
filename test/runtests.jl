using GENE
using Test
using Cambrian
using JSON
using EvolutionaryStrategies

cd("..")
println(pwd())

include("individual.jl")
include("build.jl")
include("evolution.jl")
include("flatnet.jl")
# include("scripts.jl")
