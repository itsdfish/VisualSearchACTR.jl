module PAAV
    using Distributions, StatsBase, ArgCheck
    export Experiment, Model, VisualObject, Feature, Data
    export populate_features, populate_visicon!, initialize_trial!
    include("structs.jl")
    include("buffers.jl")
    include("task.jl")
end
