function run_simulation(set_sizes; fun = conjunctive_set, kwargs...)
    results = DataFrame[]
    for n in set_sizes
        experiment = Experiment(set_size = n, populate_visicon = fun,
            n_trials = 10^4)
        run_condition!(experiment; kwargs...)
        df = DataFrame(experiment.data)
        hit_rate = mean(df.target_present .== df.response)
        g = groupby(df, [:target_present,:response])
        temp = combine(g, :rt => mean)
        temp[!,:distractors] .= n
        temp[!,:hit_rate] .= hit_rate
        push!(results, temp)
    end
    return vcat(results...)
end
