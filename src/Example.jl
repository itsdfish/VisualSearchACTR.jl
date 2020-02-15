using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots
# visualize only visible features
# add emma

experiment = Experiment(set_size=10,  n_trials=10^4,
    trace=true, visible=true, populate_visicon=feature_set)
run_condition!(experiment)
df = DataFrame(experiment.data)




# x = map(x->x.location[1], visicon)
# y = map(x->x.location[2], visicon)
# scatter(x, y, yerror=17.5, xerror=17.5, grid=false, leg=false)
#
# using BenchmarkTools
# run_condition1!() = run_condition!(Experiment(n_trials=100))
# @btime run_condition1!()
