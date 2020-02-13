using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots
# highlight target
# visualize only visible features
# visualize attended objects
# color text for trace

experiment = Experiment(set_size=10,  n_trials=10^4,
    trace=false, visible=true)
run_condition!(experiment)
df = DataFrame(experiment.data)
hit_rate = mean(df[:,:target_present] .== df[:,:response])
temp = by(df, [:target_present,:response], :rt=>mean)
temp[!,:distractors] .= 2*n
temp[!,:hit_rate] .= hit_rate
push!(results, temp)
all_results = vcat(results...)
plot()




# x = map(x->x.location[1], visicon)
# y = map(x->x.location[2], visicon)
# scatter(x, y, yerror=17.5, xerror=17.5, grid=false, leg=false)
#
# using BenchmarkTools
# run_condition1!() = run_condition!(Experiment(n_trials=100))
# @btime run_condition1!()
