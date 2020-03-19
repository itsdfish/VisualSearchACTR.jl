#################################################################################################
#                               Load Packages
#################################################################################################
using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots
using GLM, Random
cd(@__DIR__)
include("simulation ratio effect.jl")
Random.seed!(524184)
#################################################################################################
#                               Conjunctive Search
#################################################################################################
set_sizes = [1,2,5,10,15]
conj_results = run_simulation(set_sizes; fun=conjunctive_ratio,
    Δτ=.40, topdown_weight=.60)

pyplot()
@df conj_results plot(:distractors, :hit_rate, grid=false,
    ylims=(.5,1), leg=false,ylabel="Hit Rate", xlabel="Set Size",
    color=:grey, linewidth=2, xaxis=font(10), yaxis=font(10), size=(600,400))

#savefig("Conjunctive_hit_rate.eps")

@df conj_results plot(:distractors, :rt_mean, group=(:target_present,:response), grid=false,
     ylims=(0,3.0), linewidth=2, leg=true, ylabel="Mean RT (seconds)", xlabel="Set Size",
     size=(600,400))

#savefig("Conjunctive_set_size.eps")

df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, conj_results)
conj_ols_present = lm(@formula(rt_mean ~ distractors), df_present)

df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, conj_results)
conj_ols_absent = lm(@formula(rt_mean ~ distractors), df_absent)
