using PAAV, Revise, Plots

experiment = Experiment()
@time target,present = initialize_trial!(experiment)
visicon = populate_visicon(experiment, target..., present)
model = Model(target=target, iconic_memory=visicon)
# 70.196 μs (1667 allocations: 82.09 KiB)
x = map(x->x.location[1], visicon)
y = map(x->x.location[2], visicon)
scatter(x, y, yerror = .25, xerror=.25, grid=false, leg=false)
