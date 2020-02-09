using Revise, PAAV, Plots

experiment = Experiment()
target,present = initialize_trial!(experiment)
@time visicon = populate_visicon(experiment, target..., present)
model = Model(target=target, iconic_memory=visicon, viewing_distance=30.0)
orient!(model, experiment)
# 70.196 μs (1667 allocations: 82.09 KiB)
x = map(x->x.location[1], visicon)
y = map(x->x.location[2], visicon)
scatter(x, y, yerror=17.5, xerror=17.5, grid=false, leg=false)
