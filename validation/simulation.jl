function run_simulation(set_sizes; fun=conjunctive_set, kwargs...)
    results = DataFrame[]
    for n in set_sizes
        experiment = Experiment(set_size=n, populate_visicon=fun,
            n_trials=10^4)
        run_condition!(experiment; kwargs...)
        df = DataFrame(experiment.data)
        df_present = filter(x->x.target_present == :present, df)
        hit_rate = mean(df_present.response .== :present)
        temp = by(df, [:target_present,:response], :rt=>mean)
        temp[!,:distractors] .= n
        temp[!,:hit_rate] .= hit_rate
        push!(results, temp)
    end
    return vcat(results...)
end
