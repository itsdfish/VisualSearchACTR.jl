import VisualSearchACTR: find_object!, relevant_object, max_activation, terminate

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

function find_object!(actr, ex)
    visible_objects = filter(x->relevant_object(actr, x), get_iconic_memory(actr))
    if isempty(visible_objects)
        ex.trace ? print_abstract_location(actr, "error locating object") : nothing
        return :error
    end
    max_vo = max_activation(visible_objects)
    if terminate(actr, max_vo)
        ex.trace ? print_abstract_location(actr, "termination threshold exceeded") : nothing
        return :error
    end
    actr.visual_location.buffer = max_vo
    ex.trace ? print_abstract_location(actr, "object found") : nothing
    return :searching
end
