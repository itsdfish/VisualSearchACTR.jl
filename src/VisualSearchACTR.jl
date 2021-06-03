module VisualSearchACTR
    using Reexport, Distributions, StatsBase, ArgCheck
    using Crayons, ACTRModels
    @reexport using Random, ACTRModels
    import ACTRModels: AbstractParms, AbstractACTR
    export ACTRV, Experiment, VisualObject, Feature, Data, Fixation, Parm
    export populate_features, populate_visicon, initialize_trial!
    export feature_visibility!, compute_angular_distance, compute_acuity_threshold
    export compute_angular_size, update_visibility!, run_trial!, run_condition!
    export orient!, compute_activations!, update_decay!, draw_object!
    export conjunctive_ratio, conjunctive_set, feature_set, generate_stimuli
    export fixation_probs, fixation_prob, import_gui
    include("structs.jl")
    include("model.jl")
    include("task.jl")
    include("trace.jl")
end
