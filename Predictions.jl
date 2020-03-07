using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots
Random.seed!(502241)
experiment = Experiment(n_trials=10^4, populate_visicon=conjunctive_set,
    set_size=30)
run_condition!(experiment; topdown_weight=.6)

pyplot()
df = DataFrame(experiment.data)
@df df histogram(:rt, group=(:target_present,:response),
    layout=(1,3), xlims=(1,4) ,grid=false, color=:grey, size=(600,300))

by(df, [:target_present,:response], :rt=>mean,:rt=>std)



experiment = Experiment(n_trials=10^4, populate_visicon=conjunctive_set,
    set_size=30)
run_condition!(experiment; topdown_weight=1.0, bottomup_weight=0.0, Δτ=.15, noise=.5)

df = DataFrame(experiment.data)
@df df histogram(:rt, group=(:target_present,:response),
    layout=(1,3), xlims=(1,4), grid=false, color=:grey, size=(600,300))

by(df, [:target_present,:response], :rt=>mean,:rt=>std, :rt=>length)
