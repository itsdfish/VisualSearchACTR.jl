cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, PAAV, Plots, Statistics, StatsPlots

experiment = Experiment(n_trials=10, trace=true, visible=true, speed =.2)
model = run_trial!(experiment)