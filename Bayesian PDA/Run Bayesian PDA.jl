cd(@__DIR__)
using Revise, AdvancedPS, PAAV, Random
include("KDE.jl")

function loglike(topdown_weight, conditions)
    return compute_LL(conditions; topdown_weight=topdown_weight)
end

priors = (
    topdown_weight=(Truncated(Normal(.6, 1.0), 0.0, Inf),),
)

bounds = ((0.0,Inf),)

set_sizes = [1,2,10,30]
conditions = generate_data(;set_sizes=set_sizes, n_trials=100)

model = DEModel(priors=priors, model=x->loglike(x..., conditions))

de = DE(bounds=bounds, visualize=false, burnin=1000, priors=priors, progress=true)
n_iter = 2000
chains = psample(model, de, n_iter)
println(chains)
