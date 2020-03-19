# {letter17=(letter17 kind letter color gray shape p screen-x 511 screen-y 136 value p :attended nil bottom-up activation 0.19 top-down activation 1 activation 0.42),
# letter18=(letter18 kind letter color black shape q screen-x 511 screen-y 338 value q :attended nil bottom-up activation 0.19 top-down activation 1 activation 1.29),
# letter19=(letter19 kind letter color black shape p screen-x 132 screen-y 457 value p :attended nil bottom-up activation 0.1 top-down activation 2 activation 1.68)}
# time: 2.6009866538579667 location: 269 269
# Iconic Memory Size: 3

using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots

experiment = Experiment(n_trials=10^1,
    trace=true, visible=true, speed =.2)

target = (color=:black,shape=:p)
visicon = [VisualObject(features=(color=Feature(;value=:gray), shape=Feature(;value=:p)), width=32.0, location=[511.0,136.0]),
VisualObject(features=(color=Feature(;value=:black), shape=Feature(;value=:q)), width=32.0, location=[511.0,338.0]),
VisualObject(features=(color=Feature(;value=:black), shape=Feature(;value=:p)), width=32.0, location=[132.0,457.0])
]

model = Model(;target=target, iconic_memory=visicon)
PAAV.compute_angular_size!(model)
model.focus = [269.0,269.0]
PAAV.update_decay!(model)
PAAV.update_finst!(model)
PAAV.update_visibility!(model)
PAAV.compute_activations!(model)

map(x->(bottomup=x.bottomup_activation,topdown=x.topdown_activation),visicon)
