function run_simulation(set_sizes; fun=conjunctive_set)
    results = DataFrame[]
    for n in set_sizes
        experiment = Experiment(set_size=n, populate_visicon=fun,
            n_trials=10^4)
        run_condition!(experiment)
        df = DataFrame(experiment.data)
        hit_rate = mean(df[:,:target_present] .== df[:,:response])
        temp = by(df, [:target_present,:response], :rt=>mean)
        temp[!,:distractors] .= n
        temp[!,:hit_rate] .= hit_rate
        push!(results, temp)
    end
    return vcat(results...)
end
