using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots

experiment = Experiment(n_trials=10^1,
    trace=true, visible=true, speed =.3)
run_trial!(experiment)




# x = map(x->x.location[1], visicon)
# y = map(x->x.location[2], visicon)
# scatter(x, y, yerror=17.5, xerror=17.5, grid=false, leg=false)
#
# using BenchmarkTools
# run_condition1!() = run_condition!(Experiment(n_trials=100))
# @btime run_condition1!()
