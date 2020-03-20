# (letter10 kind letter color gray shape q screen-x 338 screen-y 515 value q :attended nil bottom-up activation 0.6 top-down activation 1 activation 1.26)
# (letter11 kind letter color gray shape q screen-x 351 screen-y 193 value q :attended nil bottom-up activation 1.1 top-down activation 1 activation 1.81)
# (letter12 kind letter color gray shape q screen-x 511 screen-y 462 value q :attended nil bottom-up activation 0.6 top-down activation 1 activation 1.26)
# (letter13 kind letter color gray shape q screen-x 233 screen-y 303 value q :attended nil bottom-up activation 0.85 top-down activation 1 activation 1.54)
# (letter14 kind letter color gray shape q screen-x 305 screen-y 350 value q :attended nil bottom-up activation 0.81 top-down activation 1 activation 1.49)
# (letter15 kind letter color gray shape p screen-x 301 screen-y 193 value p :attended t bottom-up activation 0.92 top-down activation 2 activation 2.22)
# (letter16 kind letter color black shape p screen-x 296 screen-y 134 value p :attended nil bottom-up activation 0.84 top-down activation 1 activation 1.52)
# (letter17 kind letter color black shape p screen-x 135 screen-y 136 value p :attended nil bottom-up activation 0.66 top-down activation 1 activation 1.33)
# (letter18 kind letter color black shape p screen-x 236 screen-y 186 value p :attended nil bottom-up activation 0.85 top-down activation 1 activation 1.54)
# (letter19 kind letter color black shape p screen-x 398 screen-y 300 value p :attended nil bottom-up activation 0.89 top-down activation 1 activation 1.58)
# (letter20 kind letter color black shape p screen-x 400 screen-y 133 value p :attended nil bottom-up activation 0.79 top-down activation 1 activation 1.47)
# time: 2.6009866538579667 location: 324 324
# Iconic Memory Size: 3

vals = [(color = :gray, shape = :q, x = 338, y =515, value = :q),
(color = :gray, shape = :q, x = 351 , y = 193, value = :q),
(color = :gray, shape = :q, x = 511 , y = 462, value = :q),
(color = :gray, shape = :q, x = 233 , y = 303, value = :q),
(color = :gray, shape = :q, x = 305 , y = 350, value = :q),
(color = :gray, shape = :p,  x = 301 , y = 193, value = :p),
(color = :black, shape = :p,  x = 296 , y = 134, value = :p),
(color = :black, shape = :p,  x = 135 , y = 136, value = :p),
(color = :black, shape = :p,  x = 236 , y = 186, value = :p),
(color = :black, shape = :p,  x = 398 , y = 300, value = :p),
(color = :black, shape = :p,  x = 400 , y = 133, value = :p)]

using Revise, PAAV, Plots, DataFrames, Statistics, StatsPlots

experiment = Experiment(n_trials=10^1,
    trace=true, visible=true, speed=.2)

target = (color=:gray,shape=:p)
visicon = [VisualObject(features=(color=Feature(;value=x.color), shape=Feature(;value=x.shape)), width=32.0,
location=[x.x-0.,x.y-0.]) for x in vals ]

model = Model(;target=target, iconic_memory=visicon, noise=0.0)
PAAV.compute_angular_size!(model)
model.focus = [324.0,324.0]
#PAAV.orient!(model, experiment)
PAAV.update_decay!(model)
PAAV.update_finst!(model)
PAAV.update_visibility!(model)
PAAV.compute_activations!(model)

map(x->(bottomup=x.bottomup_activation,topdown=x.topdown_activation), visicon)
#run_trial!(experiment)
