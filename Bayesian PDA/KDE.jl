using KernelDensity, Distributions, Interpolations
import KernelDensity: kernel_dist
import Distributions: pdf

kernel_dist(::Type{Epanechnikov}, w::Float64) = Epanechnikov(0.0, w)
kernel(data) = kde(data; kernel=Epanechnikov)

struct Prob <: ContinuousUnivariateDistribution
    θ::Float64
end

pdf(dist::Prob, data) = dist.θ

function generate_data(;set_sizes, n_trials, kwargs...)
    experiments = map(x->Experiment(n_trials=n_trials,
        set_size=x, populate_visicon=conjunctive_set), set_sizes)
    map(x->run_condition!(x; kwargs...), experiments)
    return experiments
end

function condition_LL(condition; kwargs...)
    raw_preds = deepcopy(condition)
    raw_preds.n_trials = 10^3
    run_condition!(raw_preds; kwargs...)
    preds = generate_kde(raw_preds)
    LL = 0.0
    for d in condition.data
        dist = preds[d.trial_type]
        LL += max(log(pdf(dist, d.rt)), -1000.0)
    end
    return LL
end

function compute_LL(conditions; kwargs...)
    LL = 0.0
    for condition in conditions
        LL += condition_LL(condition; kwargs...)
    end
    return LL
end



generate_kde(experiment::Experiment) = generate_kde(experiment.data)

function generate_kde(data)
    T1 = typeof(kernel(rand(2)))
    preds = Dict{Symbol,Union{Prob,T1}}()
    f(present, response, x) = x.target_present==present && x.response==response
    hits = filter(x->f(:present, :present, x), data)
    misses = filter(x->f(:present, :absent, x), data)
    hits_rt = map(x->x.rt, hits)
    p_hit = length(hits)/(length(hits) + length(misses))
    dens = kernel(hits_rt)
    dens.density *= p_hit
    preds[:hit] = dens
    preds[:miss] = Prob(1-p_hit)
    # misses = filter(x->f(:present, :absent, x), data)
    # misses_rt = map(x->x.rt, misses)
    # if isempty(misses_rt)
    #     dens = kernel([0.0])
    #     dens.density *= (1-p_hit)
    #     preds[:miss] = dens
    # else
    #     dens = kernel(misses_rt)
    #     dens.density *= (1-p_hit)
    #     preds[:miss] = dens
    # end
    cr = filter(x->f(:absent, :absent, x), data)
    cr_rt = map(x->x.rt, cr)
    preds[:cr] = kernel(cr_rt)
    return preds
end
