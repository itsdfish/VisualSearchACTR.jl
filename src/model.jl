"""
    search!(actr, ex)

Search for a target among an array of visual objects.

# Arguments

- `actr`: an ACT-R object 
- `ex`: an experiment object 
"""
function search!(actr, ex)
    status = :searching
    # search until target found or termination threshold met
    while status == :searching
        # update decay values of objects in iconic memory 
        update_decay!(actr)
        # update the finst values for return of inhabition
        update_finst!(actr)
        # update which items are in iconic memory based on what is currently visible 
        update_visibility!(actr, ex.ppi)
        # update the activations 
        compute_activations!(actr)
        ex.visible ? update_window!(actr, ex) : nothing
        # perform search sequence
        status = fixate!(actr, ex)
        ex.visible ? update_window!(actr, ex) : nothing
    end
    # add data for trial 
    add_data!(ex)
    # add fixations for trial 
    push!(ex.fixations, ex.trial_fixations)
    return nothing
end

"""
    fixate!(actr, ex)

Attempts to select the visual object with the highest visual activation and attends to it. 
If the target is found, a response is collected. If nothing exceeds threshold, then an "absent" response is collected.
If a distractor is found, the symbol "searching" is returned. 

# Arguments

- `actr`: an ACT-R object 
- `ex`: an experiment object 
"""
function fixate!(actr, ex)
    ex.trace ? print_trial(ex) : nothing
    data = ex.trial_data
    # production cycle
    cycle_time!(actr, ex)
    # select visual object with highest activation
    status = find_object!(actr, ex)
    if status == :error
        # if not objects are found, add respond time
        cycle_time!(actr, ex)
        motor_time!(actr, ex)
        # add fixation data
        add_no_fixation!(ex, actr)
        ex.trace ? print_response(actr, "absent") : nothing
        # add response to data
        add_response!(actr, data, :absent)
        return status
    end
    # Attending object in abstract-location
    # add cycle time
    cycle_time!(actr, ex)
    # add attend time
    attend_time!(actr, ex)
    # place object in visual buffer and update attend time 
    attend_object!(actr, ex)
    # add fixation to fixation data
    add_fixation!(ex, actr)
    # cycle time before response
    cycle_time!(actr, ex)
    # check if current object matches target
    status = check_object(actr, ex)
    if status == :present
        # if matches, respond present and collect data
        motor_time!(actr, ex)
        ex.trace ? print_response(actr, "present") : nothing
        add_response!(actr, data, status)
        return status
    end
    # if does not match, return "searching" and continue
    return status
end

"""
motor_time!(actr, ex)

Add motor execution time to simulated time 

# Arguments
-`actr`: an ACTR model object 
- `ex`: an experiment object
"""
function motor_time!(actr, ex)
    # mean motor time 
    tΔ = 0.210
    if actr.parms.rnd_time
        θ = gamma_parms(tΔ, actr.parms.σfactor)
        tΔ = rand(Gamma(θ...))
    end
    actr.time += tΔ
    ex.visible ? sleep(tΔ / ex.speed) : nothing
    return nothing
 end

function cycle_time!(actr, ex)
    # mean cycle time 
    tΔ = .05
    if actr.parms.rnd_time 
        θ = gamma_parms(tΔ, actr.parms.σfactor)
        tΔ = rand(Gamma(θ...))
    end
    actr.time += tΔ
    ex.visible ? sleep(tΔ / ex.speed) : nothing
    return nothing
end

function attend_time!(actr, ex)
    tΔ = saccade_time(actr, ex.ppi) + visual_encoding(actr)
    actr.time += tΔ
    ex.visible ? sleep(tΔ / ex.speed) : nothing
    return nothing
end

saccade_time(actr, ppi) = saccade_time(actr, actr.visual_location.buffer[1], ppi)

function saccade_time(actr, vo, ppi)
    (;Δexe, β₀exe) = actr.parms
    distance = compute_angular_distance(actr, vo, ppi)
    μ = β₀exe + distance * Δexe
    θ = gamma_parms(μ, actr.parms.σfactor)
    return rand(Gamma(θ...))
end

function visual_encoding(actr)
    tΔ = .05
    if actr.parms.rnd_time 
        θ = gamma_parms(tΔ, actr.parms.σfactor)
        tΔ = rand(Gamma(θ...))
    end
    return tΔ
end

function gamma_parms(μ, f = 1 / 3)
    σ = f * μ
    return (μ/σ)^2,σ^2/μ
end

uniform_parms(μ) =  (2 / 3) * μ, (4 / 3) * μ

function relevant_object(actr, vo)
    !vo.visible || vo.attended ? (return false) : (return true)
end

function find_object!(actr, ex)
    v = :_
    if actr.parms.noise
        v = find_object2!(actr, ex)
    else
        v = find_object1!(actr, ex)
    end
    return v
end

function find_object1!(actr, ex)
    (;iconic_memory) = actr.visual_location
    visible_objects = filter(x->relevant_object(actr, x), iconic_memory)
    if isempty(visible_objects)
        ex.trace ? print_abstract_location(actr, "error locating object", ex.ppi) : nothing
        return :error
    end
    p = fixation_probs(actr, actr.visicon, visible_objects)
    idx = sample(1:length(p), Weights(p))
    if idx == length(p)
        ex.trace ? print_abstract_location(actr, "termination threshold exceeded", ex.ppi) : nothing
        return :error
    end
    max_vo = visible_objects[idx]
    actr.visual_location.buffer = [max_vo]
    ex.trace ? print_abstract_location(actr, "object found", ex.ppi) : nothing
    return :searching
end

function find_object2!(actr, ex)
    visible_objects = filter(x->relevant_object(actr, x), get_iconic_memory(actr))
    if isempty(visible_objects)
        ex.trace ? print_abstract_location(actr, "error locating object", ex.ppi) : nothing
        return :error
    end
    max_vo = max_activation(visible_objects)
    if terminate(actr, max_vo)
        ex.trace ? print_abstract_location(actr, "termination threshold exceeded", ex.ppi) : nothing
        return :error
    end
    actr.visual_location.buffer = max_vo
    ex.trace ? print_abstract_location(actr, "object found", ex.ppi) : nothing
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

function terminate(actr, max_vo::AbstractVisualObject)
    τ = actr.parms.τₐ + add_noise(actr)
    τ > max_vo.activation ? (return true) : (return false)
end

function update_decay!(actr)
    map(x -> update_decay!(actr, x), get_iconic_memory(actr))
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
    attended_objects = filter(x -> x.attended, get_iconic_memory(actr))
    isempty(attended_objects) ? (return) : nothing
    map(x -> update_finst_span!(actr, x), attended_objects)
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
    sort!(vos, by=x -> x.attend_time)
    for i in 1:N
        vos[i].attended = false
        vos[i].attend_time = 0.0
    end
    return nothing
end

function compute_activations!(actr)
    (;iconic_memory) = actr.visual_location
    iconic_memory = filter(x -> x.visible, actr.visicon)
    topdown_activations!(iconic_memory, actr.goal.buffer[1])
    bottomup_activations!(iconic_memory)
    weighted_activations!(actr, iconic_memory)
    actr.parms.noise ? add_noise!(actr, iconic_memory) : nothing
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

bottomup_activations!(actr::ACTRV) = bottomup_activations!(get_iconic_memory(actr))

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
            activation += 1.0 / sqrt(distance)
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
    return activation
end

"""
    add_noise(actr)

Returns a sample of normally distributed noise with standard deviation σ.

# Arguments
- `actr`: an ACTR model object 
"""
add_noise(actr) = rand(Normal(0, actr.parms.σ))

"""
    add_noise!(actr, vo::VisualObject)

Adds normally distributed noise with standard deviation σ to visual object `vo`.

# Arguments
- `actr`: an ACTR model object 
- `vo::VisualObject`: a visual object containing features 
"""
add_noise!(actr, vo::VisualObject) = vo.activation += add_noise(actr)

"""
    add_noise!(actr, vo::VisualObject)

Adds normally distributed noise with standard deviation σ to all visual objects in iconic memory.

# Arguments
- `actr`: an ACTR model object 
- `iconic_memory`: a temporary store for all visible visual objects 
"""
add_noise!(actr, iconic_memory) = map(x -> add_noise!(actr, x), iconic_memory)

function update_visibility!(actr, ppi)
    map(x -> feature_visibility!(actr, x, ppi), get_iconic_memory(actr))
    map(x -> object_visibility!(x), get_iconic_memory(actr))
end

"""
    feature_visibility!(actr, vo, ppi)

Updates `visible` field for each feature in `vo`. A feature is visible if it is within 
the acuity threshold. 

# Arguments 

- `actr`: an ACTR model object 
- `vo`: a visual object containing features 
- `ppi`: pixels per inch
"""
function feature_visibility!(actr, vo, ppi)
    angular_distance = compute_angular_distance(actr, vo, ppi)
    for (f,v) in pairs(vo.features)
        parms = actr.parms.acuity[f]
        threshold = compute_acuity_threshold(parms, angular_distance)
        # note that objects in finst will stay visible briefly even if their size is less than threshold
        if feature_is_visible(vo, threshold)
            v.visible = true
        end
    end
    return nothing
end

"""
    feature_is_visible(vo::AbstractVisualObject, threshold) 

Tests whether a feature of a visual object is visible. A feature is visible if its angular size 
is greater than the acuity threshold. 

# Arguments
- `vo`: a visual object containing features 
- `threshold`: threshold of visiblity. Objects larger than the acuity threshold are visible
"""
feature_is_visible(vo::AbstractVisualObject, threshold) = feature_is_visible(vo.angular_size, threshold)

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

"""
    compute_distance(actr::ACTRV, vo)

Compute the distance between a visual object and the model's fixation point. 

# Arguments

- `actr`: an ACTR model object 
- `vo`: a visual object
"""
function compute_distance(actr::ACTRV, vo)
    sqrt(sum((actr.visual.focus .- vo.location).^2))
end

"""
    compute_distance(vo1, vo2)

Computes the distance in pixels between two visual objects.
"""
function compute_distance(vo1, vo2)
    sqrt(sum((vo1.location .- vo2.location).^2))
end

"""
    compute_angular_distance(actr, vo, ppi)

Angular distance in degress between the model's visual fixation point and a visual object.

- `actr`: an ACTR model object 
- `vo`: a visual object
- `ppi`: pixels per inch
"""
function compute_angular_distance(actr, vo, ppi)
    (;viewing_distance,) = actr.parms
    object_distance = compute_distance(actr, vo)
    return compute_angular_size(viewing_distance, object_distance / ppi)
end

"""
    compute_angular_size!(actr::ACTRV, ppi)

Computes the angular size of all objects in the visicon.
# Arguments

- `actr`: an ACTR model object
- `ppi`: pixels per inch
"""
function compute_angular_size!(actr::ACTRV, ppi)
    map(x -> compute_angular_size!(actr, x, ppi), get_visicon(actr))
    return nothing
end

"""
    compute_angular_size!(actr::ACTRV, vo, ppi)

Computes the angular size of an object. Inputs distance and size 
must been in the same units.

# Arguments

- `actr`: an ACTR model object
- `vo`: a visual object
- `ppi`: pixels per inch
"""
function compute_angular_size!(actr::ACTRV, vo, ppi)
    (;viewing_distance,) = actr.parms
    distance = viewing_distance * ppi
    vo.angular_size = compute_angular_size(distance, vo.width)
end

"""
    compute_angular_size(distance, size)

Compute the angular size of an object. Inputs distance and size 
must been in the same units.

# Arguments

- `distance`: distance between observer and object 
- `size`: length of object
"""
function compute_angular_size(distance, _size)
    radians = 2 * atan(_size / (2 * distance))
    return rad2deg(radians)
end

rad2deg(radians) = radians * 180 / pi

"""
    compute_acuity_threshold(parms, angular_distance)

Computes the acuity threshold of feature visibility. 

# Arguments
- `parms`: aquity parameters `a` and `b`
- `angular_distance`: angular distance between fixation point and a visual object
"""
function compute_acuity_threshold(parms, angular_distance)
    return parms.a * angular_distance^2 - parms.b * angular_distance
end

"""
    orient!(actr, ex)

Orient attention to fixation cross located at the center of the array. 

# Arguments
- `actr`: an ACTR model object 
- `ex`: an experiment object 
"""
function orient!(actr, ex)
    w = ex.array_width / 2
    actr.visual.focus = fill(w, 2)
end

function fixation_prob(actr, visicon, visible_objects, fixation)
    (;stop,idx) = fixation
    act = map(x -> x.activation, visible_objects)
    push!(act, actr.parms.τₐ)
    σ = actr.parms.σ*sqrt(2)
    vo_act = stop ? act[end] : visicon[idx].activation
    return exp(vo_act/σ)/sum(exp.(act/σ))
end

function fixation_probs(actr, visicon, visible_objects)
    act = map(x -> x.activation, visible_objects)
    push!(act, actr.parms.τₐ)
    σ = actr.parms.σ * sqrt(2)
    return exp.(act / σ) / sum(exp.(act / σ))
end


function add_fixation!(ex, actr)
    goal = get_buffer(actr, :goal)
    vision = get_buffer(actr, :visual)
    visicon = actr.visicon
    attend_time = vision[1].attend_time 
    slots = goal[1].slots
    idx = findfirst(x -> x.location == vision[1].location, visicon)
    fixation = Fixation(; attend_time, color=slots.color, 
        shape=slots.shape, idx, stop=false)
    push!(ex.trial_fixations, fixation)
    return nothing
end

function add_no_fixation!(ex, actr)
    goal = get_buffer(actr, :goal)
    vision = get_buffer(actr, :visual)
    visicon = actr.visicon
    attend_time = actr.time
    slots = goal[1].slots
    idx = length(visicon) + 1
    fixation = Fixation(; attend_time, color=slots.color, 
        shape=slots.shape, idx, stop=true)
    push!(ex.trial_fixations, fixation)
    return nothing
end

function add_data!(ex)
    push!(ex.data, ex.trial_data)
    return nothing
end

function add_response!(actr, data, status)
    data.response = status
    data.rt = actr.time
    set_trial_type!(data)
    return nothing
end


