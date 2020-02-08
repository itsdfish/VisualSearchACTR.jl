function run_model!(model, ex)
    for trial in 1:ex.n_trials
        target = initialize_trial!(ex)
        orient!(model, ex)
        search!(model, ex)
    end
end

function search!(model, experiment)
    status = :searching
    while status == :searching
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
    w = ex.width/2
    model.focus = fill(w, 2)
end
