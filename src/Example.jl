using PAAV, Revise, Plots

experiment = Experiment()
@time populate_visicon!(experiment)

x = map(x->x.location[1], experiment.visicon)
y = map(x->x.location[2], experiment.visicon)
scatter(x, y, yerror = .25, xerror=.25, grid=false, leg=false)
