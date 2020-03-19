function run_condition!(ex; parms...)
    for trial in 1:ex.n_trials
        run_trial!(ex; parms...)
    end
    return nothing
end

function run_trial!(ex; parms...)
    target,present = initialize_trial!(ex)
    visicon = ex.populate_visicon(ex, target..., present)
    model = Model(;target=target, iconic_memory=visicon, parms...)
    compute_angular_size!(model)
    orient!(model, ex)
    ex.visible ? draw_cross!(model, ex) : nothing
    ex.trace ? println("\n", get_time(model), " start search sequence") : nothing
    search!(model, ex)
    return model
end

function search!(model, ex)
    status = :searching
    while status == :searching
        update_decay!(model)
        update_finst!(model)
        update_visibility!(model)
        compute_activations!(model)
        ex.visible ? update_window!(model, ex) : nothing
        status = _search!(model, ex)
        ex.visible ? update_window!(model, ex) : nothing
    end
    add_data!(ex)
    return nothing
end

function _search!(model, ex)
    # Finding object in abstract-location
    ex.trace ? print_trial(ex) : nothing
    data = ex.current_trial
    cycle_time!(model, ex)
    status = find_object!(model, ex)
    if status == :error
        cycle_time!(model, ex)
        motor_time!(model, ex)
        ex.trace ? print_response(model, "absent") : nothing
        add_response!(model, data, :absent)
        return status
    end
    # Attending object in abstract-location
    cycle_time!(model, ex)
    attend_time!(model, ex)
    attend_object!(model, ex)
    cycle_time!(model, ex)
    status = check_object(model, ex)
    if status == :present
        cycle_time!(model, ex)
        motor_time!(model, ex)
        ex.trace ? print_response(model, "present") : nothing
        add_response!(model, data, status)
        return status
    end
    return status
end

function motor_time!(model, ex)
    θ = gamma_parms(.065)
    tΔ = rand(Gamma(θ...))
    model.current_time += tΔ
    ex.visible ? sleep(tΔ/ex.speed) : nothing
    return nothing
 end

function cycle_time!(model, ex)
    θ = gamma_parms(.05)
    tΔ = rand(Gamma(θ...))
    model.current_time += tΔ
    ex.visible ? sleep(tΔ/ex.speed) : nothing
    return nothing
end

function attend_time!(model, ex)
    # tΔ = saccade_time(model) + visual_encoding(model)
    tΔ = visual_encoding(model)
    model.current_time += tΔ
    ex.visible ? sleep(tΔ/ex.speed) : nothing
    return nothing
end

saccade_time(model) = saccade_time(model, model.abstract_location[1])

function saccade_time(model, vo)
    distance = compute_angular_distance(model, vo)
    μ = model.β₀exe + distance*model.Δexe
    θ = gamma_parms(μ)
    return rand(Gamma(θ...))
end

function visual_encoding(model)
    θ = gamma_parms(.085)
    return rand(Gamma(θ...))
end

gamma_parms(μ, σ) = (μ/σ)^2,σ^2/μ

gamma_parms(μ) = gamma_parms(μ, μ/3)

function add_data!(ex)
    push!(ex.data, ex.current_trial)
    return nothing
end

function add_response!(model, data, status)
    data.response = status
    data.rt = model.current_time
    set_trial_type!(data)
    return nothing
end

function relevant_object(model, vo)
    !vo.visible || vo.attended ? (return false) : (return true)
end

function find_object!(model, ex)
    visible_objects = filter(x->relevant_object(model, x), model.iconic_memory)
    if isempty(visible_objects)
        ex.trace ? print_abstract_location(model, "error locating object") : nothing
        return :error
    end
    max_vo = max_activation(visible_objects)
    if terminate(model, max_vo)
        ex.trace ? print_abstract_location(model, "termination threshold exceeded") : nothing
        return :error
    end
    model.abstract_location = max_vo
    ex.trace ? print_abstract_location(model, "object found") : nothing
    return :searching
end

attend_object!(model, ex) = attend_object!(model, ex, model.abstract_location[1])

function attend_object!(model, ex, vo)
    ex.trace ? print_vision(model) : nothing
    model.vision = [vo]
    vo.attended = true
    vo.attend_time = model.current_time
    model.focus = vo.location
    ex.trace ? print_visual_buffer(model) : nothing
    return nothing
end

check_object(model, ex) = check_object(model, model.vision[1], ex, model.target)

function check_object(model, vo, ex, target)
    for (f,v) in pairs(target)
        if vo.features[f].value ≠ v
            ex.trace ? print_check(model, "not found") : nothing
            update_threshold!(model)
            return :searching
        end
    end
    ex.trace ? print_check(model, "found") : nothing
    return :present
end

function max_activation(vos)
    max_vo = similar(vos, 1)
    mv = -Inf
    for vo in vos
        if vo.activation > mv
            max_vo[1] = vo
            mv = vo.activation
        end
    end
    return max_vo
end

function update_threshold!(model)
    model.τₐ += model.Δτ
end

terminate(model, max_vo) = terminate(model, max_vo[1])

function terminate(model, max_vo::VisualObject)
    τ = model.τₐ + add_noise(model)
    τ > max_vo.activation ? (return true) : (return false)
end

function update_decay!(model)
    map(x->update_decay!(model, x), model.iconic_memory)
end

function update_decay!(model, object)
    for f in object.features
        if model.persistance < (model.current_time - f.fixation_time)
            f.visible = false
            f.fixation_time = 0.0
        end
    end
    return nothing
end

function update_finst!(model)
    attended_objects = filter(x->x.attended, model.iconic_memory)
    isempty(attended_objects) ? (return) : nothing
    map(x->update_finst_span!(model, x), attended_objects)
    update_n_finst!(model, attended_objects)
end

function update_finst_span!(model, vo)
    if model.finst_span < (model.current_time - vo.attend_time)
        vo.attended = false
        vo.attend_time = 0.0
    end
    return nothing
end

function update_n_finst!(model, vos)
    N = length(vos) - model.n_finst
    N <= 0 ? (return) : nothing
    sort!(vos, by=x->x.attend_time)
    for i in 1:N
        vos[i].attended = false
        vos[i].attend_time = 0.0
    end
    return nothing
end

function compute_activations!(model)
    iconic_memory = filter(x->x.visible, model.iconic_memory)
    topdown_activations!(iconic_memory, model.target)
    bottomup_activations!(iconic_memory)
    weighted_activations!(model, iconic_memory)
    add_noise!(model, iconic_memory)
    return nothing
end

function weighted_activations!(model, iconic_memory)
    for object in iconic_memory
        weighted_activation!(model, object)
    end
    return nothing
end

function weighted_activation!(model, vo)
    vo.activation = weighted_activation(model, vo)
    return nothing
end

function weighted_activation(model, vo)
    return model.bottomup_weight * vo.bottomup_activation +
    model.topdown_weight * vo.topdown_activation
end

bottomup_activations!(model::Model) = bottomup_activations!(model.iconic_memory)

function bottomup_activations!(iconic_memory)
    for vo1 in iconic_memory
        activation = 0.0
        for vo2 in iconic_memory
            vo1 == vo2 ? continue : nothing
            activation += bottomup_activation(vo1, vo2)
        end
        vo1.bottomup_activation = activation
    end
    return nothing
end

function bottomup_activation(vo1, vo2)
    distance = compute_distance(vo1, vo2)
    return bottomup_activation(vo1.features, vo2.features, distance)
end

function bottomup_activation(f1, f2, distance)
    activation = 0.0
    for (f,v) in pairs(f1)
        if (f2[f].value ≠ v.value) && v.visible && f2[f].visible
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

add_noise(model) = rand(Normal(0, model.noise))

add_noise!(model, vo::VisualObject) = vo.activation += add_noise(model)

add_noise!(model, iconic_memory) = map(x->add_noise!(model, x), iconic_memory)

function update_visibility!(model)
    map(x->feature_visibility!(model, x), model.iconic_memory)
    map(x->object_visibility!(x), model.iconic_memory)
end

function feature_visibility!(model, vo)
    angular_distance = compute_angular_distance(model, vo)
    for (f,v) in pairs(vo.features)
        parms = model.acuity[f]
        threshold = compute_acuity_threshold(parms, angular_distance)
        if feature_is_visible(vo, threshold)
            v.visible = true
        end
    end
    return nothing
end

feature_is_visible(vo::VisualObject, threshold) = feature_is_visible(vo.angular_size, threshold)

function feature_is_visible(angular_size, threshold)
    return angular_size > threshold
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

function compute_distance(model::Model, object)
    sqrt(sum((model.focus .- object.location).^2))
end

function compute_distance(vo1, vo2)
    sqrt(sum((vo1.location .- vo2.location).^2))
end

"""
Angular distance in degress. Also known as eccentricity
"""
function compute_angular_distance(model, vo)
    distance = compute_distance(model, vo)
    return pixels_to_degrees(model, distance)
end

function compute_angular_size!(model)
    map(x->compute_angular_size!(model, x), model.iconic_memory)
    return nothing
end

function compute_angular_size!(model, vo)
    ppi = 72 # pixels per inch
    distance = model.viewing_distance*ppi
    vo.angular_size = compute_angular_size(distance, vo.width)
end

function compute_angular_size(distance, width)
    radians = 2*atan(width/(2*distance))
    return rad2deg(radians)
end

rad2deg(radians) = radians*180/pi

function compute_acuity_threshold(parms, angular_distance)
    return parms.a*angular_distance^2 - parms.b*angular_distance
end

function pixels_to_degrees(model, pixels)
    ppi = 72 # pixels per inch
    radians = atan(pixels/ppi, model.viewing_distance)
    return rad2deg(radians)
end

function orient!(model, ex)
    w = ex.array_width/2
    model.focus = fill(w, 2)
end

# visual_encoding(model) = visual_encoding(model, model.abstract_location[1])
#
# function visual_encoding(model, vo)
#     frequency = model.init_freq
#     distance = compute_angular_distance(model, vo)
#     μ = model.K_encode*-log(frequency)*exp(distance*model.κ_encode)
#     θ = gamma_parms(μ)
#     # vo.encode_start = model.current_time
#     # vo.encode_time = rand(Gamma(a, b))
#     return rand(Gamma(θ...))
# end
