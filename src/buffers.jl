function run_condition!(ex)
    for trial in 1:ex.n_trials
        run_trial!(ex)
    end
    return nothing
end

function run_trial!(ex)
    target,present = initialize_trial!(ex)
    visicon = populate_visicon(ex, target..., present)
    model = Model(target=target, iconic_memory=visicon)
    orient!(model, ex)
    search!(model, ex)
    return nothing
end

function search!(model, ex)
    status = :searching
    while status == :searching
        update_decay!(model)
        update_visibility!(model)
        compute_activations!(model)
        status = _search!(model, ex)
    end
    add_data(ex)
end

function _search!(model, ex)
    ex.trace ? println("\n start search sequence...") : nothing
    print_trial(ex)
    data = ex.current_trial
    status = find_object!(model)
    ex.trace ? println("find object: $status") : nothing
    tΔ = cycle_time()
    model.current_time += tΔ
    if status == :error
        tΔ = cycle_time() + motor_time()
        model.current_time += tΔ
        add_response!(model, data, :absent)
        return status
    end
    attend_object!(model)
    tΔ = cycle_time() + attend_time()
    model.current_time += tΔ
    status = target_found(model)
    ex.trace ? println("attend object: $status") : nothing
    ex.trace ? print_visual_buffer(model) : nothing
    if status == :present
        tΔ = cycle_time() + motor_time()
        model.current_time += tΔ
        add_response!(model, data, status)
        return status
    end
    status = find_object!(model)
    ex.trace ? println("find object again: $status") : nothing
    tΔ = cycle_time()
    model.current_time += tΔ
    if status == :error
        tΔ = cycle_time() + motor_time()
        model.current_time += tΔ
        add_response!(model, data, :absent)
        return status
    end
    attend_object!(model)
    tΔ = cycle_time() + attend_time()
    status = target_found(model)
    ex.trace ? println("attend object again: $status") : nothing
    ex.trace ? print_visual_buffer(model) : nothing
    if status == :present
        tΔ = cycle_time() + motor_time()
        model.current_time += tΔ
        add_response!(model, data, status)
        return status
    end
    return status
end

motor_time() = rand(Gamma(1, .1))

cycle_time() = rand(Gamma(1, .05))

attend_time() = rand(Gamma(1, .085))

function add_response!(model, data, status)
    data.response = status
    data.rt = model.current_time
    return nothing
end

function add_data(ex)
    push!(ex.data, ex.current_trial)
    return nothing
end

function relevant_object(model, vo)
    if vo.attended || !vo.visible
        return false
    end
    distance = compute_distance(model, vo)
    if distance > model.distance_threshold
        return false
    end
    if vo.activation < model.activation_threshold
        return false
    end
    return true
end

function find_object!(model)
    visible_objects = filter(x->relevant_object(model, x), model.iconic_memory)
    isempty(visible_objects) ? (return :error) : nothing
    model.abstract_location = max_activation(x->x.activation, visible_objects)
    return :searching
end

function attend_object!(model)
    model.vision = model.abstract_location
    model.vision[1].attended = true
    model.focus = model.vision[1].location
    # thresholds
    return nothing
end

target_found(model) = target_found(model.vision[1], model.target)

function target_found(vo, target)
    for (f,v) in pairs(target)
        vo.features[f].value != v ? (return :searching) : nothing
    end
    return :present
end

function max_activation(f, vos)
    max_vo = similar(vos, 1)
    mv = -Inf
    for vo in vos
        if vo.activation > mv
            max_vo[1] = vo
        end
    end
    return max_vo
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

function compute_activations!(model)
    iconic_memory = filter(x->x.visible, model.iconic_memory)
    topdown_activations!(iconic_memory, model.target)
    bottomup_activations!(iconic_memory)
    weighted_activations!(model, iconic_memory)
    return nothing
end

function weighted_activations!(model, iconic_memory)
    for object in iconic_memory
        weighted_activation!(model, object)
    end
    return nothing
end

function weighted_activation!(model, object)
    object.activation = model.bottomup_weight * object.bottomup_activation +
    model.topdown_weight * object.topdown_activation + rand(Normal(0, model.noise))
    return nothing
end

bottomup_activations!(model::Model) = bottomup_activations!(model.iconic_memory)

function bottomup_activations!(iconic_memory)
    for vo1 in iconic_memory
        activation = 0.0
        for vo2 in iconic_memory
            vo1 == vo2 ? continue : nothing
            activation += bottomup_activation!(vo1, vo2)
        end
        vo1.bottomup_activation = activation
    end
    return nothing
end

function bottomup_activation!(vo1, vo2)
    distance = compute_distance(vo1, vo2)
    return bottomup_activation!(vo1.features, vo2.features, distance)
end

function bottomup_activation!(features1, features2, distance)
    activation = 0.0
    for (f,v) in pairs(features1)
        if features2[f].value != v.value
            activation += 1.0/sqrt(distance)
        end
    end
    return activation
end

function topdown_activations!(iconic_memory, target)
    for object in iconic_memory
        topdown_activation!(object, target)
    end
    return nothing
end

function topdown_activation!(object, target)
    activation = 0.0
    for (f,v) in pairs(object.features)
        if v.visible
            if v.value == target[f]
                activation += 1.0
            end
        else
            activation += .5
        end
    end
    object.topdown_activation = activation
    return nothing
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

function compute_distance(model::Model, object)
    sqrt(sum((model.focus .- object.location).^2))
end

function compute_distance(vo1, vo2)
    sqrt(sum((vo1.location .- vo2.location).^2))
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

function orient!(model, ex)
    w = ex.array_width/2
    model.focus = fill(w, 2)
end
