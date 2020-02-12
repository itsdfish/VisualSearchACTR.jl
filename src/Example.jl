using Revise, PAAV, Plots, DataFrames, Statistics
# add finsts
# add fixation
# highlight target
# visualize only visible features
# visualize attended objects
# color text for trace
experiment = Experiment(n_color_distractors=15, n_shape_distractors=15, n_trials=1000,
    trace=false, visible=true)
run_condition!(experiment)
df = DataFrame(experiment.data)
results = by(df, [:target_present,:response], :rt=>mean)
println(results)





# x = map(x->x.location[1], visicon)
# y = map(x->x.location[2], visicon)
# scatter(x, y, yerror=17.5, xerror=17.5, grid=false, leg=false)
#
# using BenchmarkTools
# run_condition1!() = run_condition!(Experiment(n_trials=100))
# @btime run_condition1!()
