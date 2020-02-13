#################################################################################################
#                               Load Packages
#################################################################################################
using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots
using GLM, Random
cd(@__DIR__)
include("simulation.jl")
Random.seed!(52484)
#################################################################################################
#                               Conjunctive Search
#################################################################################################
set_sizes = [1:5...,10,15,20,25,30]
conj_results = run_simulation(set_sizes, fun=conjunctive_set)

pyplot()
hit = @df conj_results plot(:distractors, :hit_rate, grid=false,
    ylims=(.5,1), leg=false,ylabel="Hit Rate", xlabel="N Distractors",
    color=:grey, linewidth=2, xaxis=font(10), yaxis=font(10))

@df conj_results plot(:distractors, :rt_mean, group=(:target_present,:response), grid=false,
     ylims=(0,2), linewidth=2, leg=true, ylabel="Mean RT (seconds)", xlabel="N Distractors")

df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, conj_results)
conj_ols_present = lm(@formula(rt_mean ~ distractors), df_present)

df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, conj_results)
conj_ols_absent = lm(@formula(rt_mean ~ distractors), df_absent)
#################################################################################################
#                               Feature Search
#################################################################################################
set_sizes = [1:5...,10,15,20,25,30]
feature_results = run_simulation(set_sizes, fun=feature_set)

pyplot()
hit = @df feature_results plot(:distractors, :hit_rate, grid=false,
    ylims=(.5,1), leg=false,ylabel="Hit Rate", xlabel="N Distractors",
    color=:grey, linewidth=2, xaxis=font(10), yaxis=font(10))

@df feature_results plot(:distractors, :rt_mean, group=(:target_present,:response), grid=false,
     ylims=(0,2), linewidth=2, leg=true, ylabel="Mean RT (seconds)", xlabel="N Distractors")

df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, feature_results)
feature_ols_present = lm(@formula(rt_mean ~ distractors), df_present)

df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, feature_results)
feature_ols_absent = lm(@formula(rt_mean ~ distractors), df_absent)