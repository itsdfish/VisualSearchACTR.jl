cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, PAAV, Statistics

experiment = Experiment(n_trials=2, trace=true, visible=true, speed=1.0)
stimuli = map(_->generate_stimuli(experiment), 1:2)
model = run_trial!(experiment, stimuli...);