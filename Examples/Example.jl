cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, VisualSearchACTR, Statistics
import_gui()

experiment = Experiment(n_trials=2, trace=true, visible=true, speed=1.0);
stimuli = generate_stimuli(experiment)
model = run_trial!(experiment, stimuli...);