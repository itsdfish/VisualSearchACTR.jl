cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, DifferentialEvolutionMCMC, PAAV, Random
include("KDE.jl")

Random.seed!(50225)

function loglike(topdown_weight, conditions)
    return compute_LL(conditions; topdown_weight=topdown_weight)
end

priors = (
    topdown_weight=(Truncated(Normal(.6, 1.0), 0.0, Inf),),
)

bounds = ((0.0,Inf),)

set_sizes = [5]
conditions = generate_data(;set_sizes=set_sizes, n_trials=100)

model = DEModel(priors=priors, model=x->loglike(x..., conditions))

de = DE(bounds=bounds, burnin=1000, priors=priors)
n_iter = 2000
chains = sample(model, de, MCMCThreads(), n_iter, progress=true)
println(chains)
