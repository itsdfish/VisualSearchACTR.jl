module PAAV
    using Distributions, StatsBase, ArgCheck
    export Experiment, Model, VisualObject, Feature, Data
    export populate_features, populate_visicon, initialize_trial!
    export feature_visibility!, compute_angular_distance, compute_acuity_threshold
    export compute_angular_size, update_visibility!, run_trial!, run_condition!
    export orient!, compute_activations!, update_decay!
    include("structs.jl")
    include("buffers.jl")
    include("task.jl")
    include("trace.jl")
end
