cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, PAAV, Statistics

experiment = Experiment(n_trials=10, trace=true, visible=true, speed =.2)
model = run_trial!(experiment)