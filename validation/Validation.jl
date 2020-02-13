using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots
using GLM
distractors = [1,2,4,8,16]

pyplot()
hit = @df all_results plot(:distractors, :hit_rate, grid=false,
    ylims=(.5,1), leg=false,ylabel="Hit Rate", xlabel="N Distractors",
    color=:grey, linewidth=2, xaxis=font(10), yaxis=font(10))

@df all_results plot(:distractors, :rt_mean, group=(:target_present,:response), grid=false,
     ylims=(0,2), linewidth=2, leg=true, ylabel="Mean RT (seconds)", xlabel="N Distractors")

df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, all_results)
ols_present = lm(@formula(rt_mean ~ distractors), df_present)

df_absebt = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, all_results)
ols_absent = lm(@formula(rt_mean ~ distractors), df_absebt)




# x = map(x->x.location[1], visicon)
# y = map(x->x.location[2], visicon)
# scatter(x, y, yerror=17.5, xerror=17.5, grid=false, leg=false)
#
# using BenchmarkTools
# run_condition1!() = run_condition!(Experiment(n_trials=100))
# @btime run_condition1!()
