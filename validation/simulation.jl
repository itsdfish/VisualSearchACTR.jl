function conjunctive_search(n_objects; args...)
    results = DataFrame[]
    for n in n_objects
        experiment = Experiment(set_size=n, populate_visicon=conjunctive_set, n_trials=10^4)
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
