cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, VisualSearchACTR, Statistics, DataFrames
import_gui()

ppi = 72
letter_in = 0.314961
array_in = 5.9
array_width = array_in * ppi 
object_width = letter_in * ppi 
viewing_distance = 36.5
n_color_distractors=5 
set_size=10
n_shape_distractors=5


experiment = Experiment(;n_trials=1000, trace=false, visible=false,
    array_width, object_width, ppi, n_color_distractors, set_size, n_shape_distractors);
stimuli = generate_stimuli(experiment)
model = run_condition!(experiment; viewing_distance);
df = DataFrame(experiment.data)
groups = groupby(df, [:trial_type])
combine(groups, :rt => mean => :rt)
temp = combine(groupby(df, [:target_present,:response]), nrow => :count)
temp = combine(groupby(temp, [:target_present]), :count => (x -> x / sum(x)) => :prop)