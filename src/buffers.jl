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
    map(x->update_decay!(model, x), model.iconic_memory)
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
    map(x->feature_visibility!(model, x), model.iconic_memory)
    map(x->object_visibility!(x), model.iconic_memory)
end

function feature_visibility!(model, object)
    angular_distance = compute_angular_distance(model, object)
    angular_size = compute_angular_size(model, object)
    for (f,v) in pairs(object.features)
        parms = model.acuity[f]
        threshold = compute_acuity_threshold(parms, angular_distance)
        if feature_is_visible(angular_size, threshold)
            v.visible = true
        end
    end
    return nothing
end

function feature_is_visible(angular_size, threshold)
    return angular_size > threshold
end

function compute_distance(model, object)
    sqrt(sum((model.focus .- object.location).^2))
end

function compute_angular_distance(model, object)
    distance = compute_distance(model, object)
    return pixels_to_degrees(model, distance)
end

function compute_angular_size(model, object)
    ppi = 72 # pixels per inch
    distance = compute_distance(model, object)*ppi
    radians = 2*atan(object.width/(2*distance))
    return rad2deg(radians)
end

rad2deg(radians) = radians*180/pi

function compute_acuity_threshold(parms, angular_distance)
    return parms.a*angular_distance^2 - parms.b*angular_distance
end

function pixels_to_degrees(model, pixels)
    ppi = 72 # pixels per inch
    radians = atan(pixels./ppi, model.viewing_distance)
    return rad2deg(radians)
end

function object_visibility!(object)
    for f in object.features
        if f.visible
            object.visible = true
            return nothing
        end
    end
    object.visible = false
    return nothing
end

function attend_object!(model)

end

function orient!(model, ex)
    w = ex.array_width/2
    model.focus = fill(w, 2)
end
