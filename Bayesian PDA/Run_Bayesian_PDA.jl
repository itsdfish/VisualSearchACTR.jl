cd(@__DIR__)
using Pkg
Pkg.activate("..")
using Revise, DifferentialEvolutionMCMC, VisiualSearch, Random
include("KDE.jl")

Random.seed!(50225)

function loglike(conditions, topdown_weight)
    return compute_LL(conditions; topdown_weight=topdown_weight)
end

priors = (
    topdown_weight=(Truncated(Normal(.6, 1.0), 0.0, Inf),),
)

bounds = ((0.0,Inf),)

set_sizes = [5]
data = generate_data(;set_sizes=set_sizes, n_trials=100)

model = DEModel(;priors, model=loglike, data)

de = DE(;bounds, burnin=1000, priors)
n_iter = 2000
chains = sample(model, de, MCMCThreads(), n_iter, progress=true)
println(chains)
