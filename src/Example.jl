using PAAV, Revise, Plots

experiment = Experiment()
@time initialize_trial!(experiment)
# 70.196 μs (1667 allocations: 82.09 KiB)
x = map(x->x.location[1], experiment.visicon)
y = map(x->x.location[2], experiment.visicon)
scatter(x, y, yerror = .25, xerror=.25, grid=false, leg=false)
