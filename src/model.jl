function search!(actr, ex)
    status = :searching
    while status == :searching
        update_decay!(actr)
        update_finst!(actr)
        update_visibility!(actr)
        compute_activations!(actr)
        ex.visible ? update_window!(actr, ex) : nothing
        status = _search!(actr, ex)
        ex.visible ? update_window!(actr, ex) : nothing
    end
    add_data!(ex)
    return nothing
end

function _search!(actr, ex)
    # Finding object in abstract-location
    ex.trace ? print_trial(ex) : nothing
    data = ex.current_trial
    cycle_time!(actr, ex)
    status = find_object!(actr, ex)
    if status == :error
        cycle_time!(actr, ex)
        motor_time!(actr, ex)
        ex.trace ? print_response(actr, "absent") : nothing
        add_response!(actr, data, :absent)
        return status
    end
    # Attending object in abstract-location
    cycle_time!(actr, ex)
    attend_time!(actr, ex)
    attend_object!(actr, ex)
    cycle_time!(actr, ex)
    status = check_object(actr, ex)
    if status == :present
        cycle_time!(actr, ex)
        motor_time!(actr, ex)
        ex.trace ? print_response(actr, "present") : nothing
        add_response!(actr, data, status)
        return status
    end
    return status
end

function motor_time!(actr, ex)
    θ = gamma_parms(.065)
    tΔ = rand(Gamma(θ...))
    actr.time += tΔ
    ex.visible ? sleep(tΔ/ex.speed) : nothing
    return nothing
 end

function cycle_time!(actr, ex)
    θ = gamma_parms(.05)
    tΔ = rand(Gamma(θ...))
    actr.time += tΔ
    ex.visible ? sleep(tΔ/ex.speed) : nothing
    return nothing
end

function attend_time!(actr, ex)
    # tΔ = saccade_time(model) + visual_encoding(model)
    tΔ = visual_encoding(actr)
    actr.time += tΔ
    ex.visible ? sleep(tΔ/ex.speed) : nothing
    return nothing
end

saccade_time(actr) = saccade_time(actr, actr.visual_location.buffer[1])

function saccade_time(actr, vo)
    @unpack Δexe, β₀exe = actr.parms
    distance = compute_angular_distance(actr, vo)
    μ = β₀exe + distance*Δexe
    θ = gamma_parms(μ)
    return rand(Gamma(θ...))
end

function visual_encoding(actr)
    θ = gamma_parms(.085)
    return rand(Gamma(θ...))
end

gamma_parms(μ, σ) = (μ/σ)^2,σ^2/μ

gamma_parms(μ) = gamma_parms(μ, μ/3)

function add_data!(ex)
    push!(ex.data, ex.current_trial)
    return nothing
end

function add_response!(actr, data, status)
    data.response = status
    data.rt = actr.time
    set_trial_type!(data)
    return nothing
end

function relevant_object(actr, vo)
    !vo.visible || vo.attended ? (return false) : (return true)
end

function find_object!(actr, ex)
    visible_objects = filter(x->relevant_object(actr, x), get_iconic_memory(actr))
    if isempty(visible_objects)
        ex.trace ? print_abstract_location(actr, "error locating object") : nothing
        return :error
    end
    max_vo = max_activation(visible_objects)
    # act = map(x->x.bottomup_activation, visible_objects)
    # println("mean ", mean(act), " sd: ", std(act), " minimum: ", minimum(act), " maximum: ", maximum(act))
    if terminate(actr, max_vo)
        ex.trace ? print_abstract_location(actr, "termination threshold exceeded") : nothing
        return :error
    end
    actr.visual_location.buffer = max_vo
    ex.trace ? print_abstract_location(actr, "object found") : nothing
    return :searching
end

attend_object!(actr, ex) = attend_object!(actr, ex, actr.visual_location.buffer[1])

function attend_object!(actr, ex, vo)
    ex.trace ? print_vision(actr) : nothing
    actr.visual.buffer = [vo]
    vo.attended = true
    vo.attend_time = actr.time
    actr.visual.focus = vo.location
    ex.trace ? print_visual_buffer(actr) : nothing
    return nothing
end

check_object(actr, ex) = check_object(actr, actr.visual.buffer[1], ex, actr.goal.buffer[1])

function check_object(actr, vo, ex, target)
    for (f,v) in pairs(target.slots)
        if vo.features[f].value ≠ v
            ex.trace ? print_check(actr, "not found") : nothing
            update_threshold!(actr)
            return :searching
        end
    end
    ex.trace ? print_check(actr, "found") : nothing
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

function update_threshold!(actr)
    actr.parms.τₐ += actr.parms.Δτ
end

terminate(actr, max_vo) = terminate(actr, max_vo[1])

function terminate(actr, max_vo::VisualObject)
    τ = actr.parms.τₐ + add_noise(actr)
    τ > max_vo.activation ? (return true) : (return false)
end

function update_decay!(actr)
    map(x->update_decay!(actr, x), get_iconic_memory(actr))
end

function update_decay!(actr, object)
    for f in object.features
        if actr.parms.persistence < (actr.time - f.fixation_time)
            f.visible = false
            f.fixation_time = 0.0
        end
    end
    return nothing
end

function update_finst!(actr)
    attended_objects = filter(x->x.attended, get_iconic_memory(actr))
    isempty(attended_objects) ? (return) : nothing
    map(x->update_finst_span!(actr, x), attended_objects)
    update_n_finst!(actr, attended_objects)
end

function update_finst_span!(actr, vo)
    if actr.parms.finst_span < (actr.time - vo.attend_time)
        vo.attended = false
        vo.attend_time = 0.0
    end
    return nothing
end

function update_n_finst!(actr, vos)
    N = length(vos) - actr.parms.n_finst
    N <= 0 ? (return) : nothing
    sort!(vos, by=x->x.attend_time)
    for i in 1:N
        vos[i].attended = false
        vos[i].attend_time = 0.0
    end
    return nothing
end

function compute_activations!(actr)
    @unpack iconic_memory,visicon = actr.visual_location
    iconic_memory = filter(x->x.visible, visicon)
    topdown_activations!(iconic_memory, actr.goal.buffer[1])
    bottomup_activations!(iconic_memory)
    weighted_activations!(actr, iconic_memory)
    add_noise!(actr, iconic_memory)
    return nothing
end

function weighted_activations!(model, iconic_memory)
    for object in iconic_memory
        weighted_activation!(model, object)
    end
    return nothing
end

function weighted_activation!(actr, vo)
    vo.activation = weighted_activation(actr, vo)
    return nothing
end

function weighted_activation(actr, vo)
    return actr.parms.bottomup_weight * vo.bottomup_activation +
    actr.parms.topdown_weight * vo.topdown_activation
end

bottomup_activations!(actr::ACTR) = bottomup_activations!(get_iconic_memory(actr))

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

topdown_activations!(iconic_memory, chunk::Chunk) = topdown_activations!(iconic_memory, chunk.slots) 

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

add_noise(actr) = rand(Normal(0, actr.parms.noise))

add_noise!(actr, vo::VisualObject) = vo.activation += add_noise(actr)

add_noise!(actr, iconic_memory) = map(x->add_noise!(actr, x), iconic_memory)

function update_visibility!(actr)
    map(x->feature_visibility!(actr, x), get_iconic_memory(actr))
    map(x->object_visibility!(x), get_iconic_memory(actr))
end

function feature_visibility!(actr, vo)
    angular_distance = compute_angular_distance(actr, vo)
    for (f,v) in pairs(vo.features)
        parms = actr.parms.acuity[f]
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

function compute_distance(actr::ACTR, object)
    sqrt(sum((actr.visual.focus .- object.location).^2))
end

function compute_distance(vo1, vo2)
    sqrt(sum((vo1.location .- vo2.location).^2))
end

"""
Angular distance in degress. Also known as eccentricity
"""
function compute_angular_distance(actr, vo)
    distance = compute_distance(actr, vo)
    return pixels_to_degrees(actr, distance)
end

function compute_angular_size!(actr)
    map(x->compute_angular_size!(actr, x), get_visicon(actr))
    return nothing
end

function compute_angular_size!(actr, vo)
    ppi = 72 # pixels per inch
    distance = actr.parms.viewing_distance*ppi
    vo.angular_size = compute_angular_size(distance, vo.width)
end

function compute_angular_size(distance, width)
    radians = 2*atan(width/(2*distance))
    return rad2deg(radians)
end

get_iconic_memory(actr) = actr.visual_location.iconic_memory 
get_visicon(actr) = actr.visual_location.visicon

rad2deg(radians) = radians*180/pi

function compute_acuity_threshold(parms, angular_distance)
    return parms.a*angular_distance^2 - parms.b*angular_distance
end

function pixels_to_degrees(actr, pixels)
    ppi = 72 # pixels per inch
    radians = atan(pixels/ppi, actr.parms.viewing_distance)
    return rad2deg(radians)
end

function orient!(actr, ex)
    w = ex.array_width/2
    actr.visual.focus = fill(w, 2)
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
