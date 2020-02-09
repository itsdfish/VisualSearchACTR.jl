function run_model!(model, ex)
    for trial in 1:ex.n_trials
        target,present = initialize_trial!(ex)
        visicon = populate_visicon(ex, target..., present)
        model = Model(target=target, iconic_memory=visicon)
        orient!(model, ex)
        search!(model, ex)
    end
end

function search!(model, experiment)
    status = :searching
    while status == :searching
        update_decay!(model)
        update_visibility!(model)
        #remove_nonvisible!(model)
        status = _search!(model, experiment)
    end
end

function _search!(model, experiment)
    status = find_object!(model)
    status == :error ? (return status) : nothing
    status = attend_object!(model)
    status == :error ? (return status) : nothing
    status = target_found(model, experiment)
    return status
end

function find_object!(model)

end

function update_decay!(model)
    update_decay!.(model, model.iconic_memory)
end

function update_decay!(model, object)
    for f in object.features
        if f.fixation_time < (model.current_time - model.persistance)
            f.visible = false
            f.fixation_time = 0.0
        end
    end
    return nothing
end

function compute_activation!(model)

end

function bottomup_activation!(model)

end

function topdown_activation!(model)

end

function update_visibility!(model)

end

function remove_nonvisible!(model)

end

function attend_object!(model)

end

function orient!(model, ex)
    w = ex.array_width/2
    model.focus = fill(w, 2)
end
