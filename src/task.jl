function run_condition!(ex; parms...)
    for trial in 1:ex.n_trials
        run_trial!(ex; parms...)
    end
    return nothing
end

function initialize_model(;parms...)
    target,present = initialize_trial!(ex)
    visual_objects = ex.populate_visicon(ex, target..., present)
    T = typeof(visual_objects)(undef,1)
    visual_location = VisualLocation(buffer=T)
    visual_location.visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTR(;goal=goal, visual_location=visual_location, visual=visual, parms...)
end

function run_trial!(ex; parms...)
    actr = initialize_model(;parms...)
    compute_angular_size!(actr)
    orient!(actr, ex)
    ex.visible ? draw_cross!(actr, ex) : nothing
    ex.trace ? println("\n", get_time(actr), " start search sequence") : nothing
    search!(actr, ex)
    return actr
end

function initialize_trial!(ex::Experiment)
    target = sample_target(ex)
    rand() < ex.base_rate ? (present=:present) : (present=:absent)
    data = Data()
    data.target_present = present
    data.target_shape = target.shape
    data.target_color = target.color
    ex.current_trial = data
    return target,present
end

function set_trial_type!(data)
    if data.target_present == :present
        if data.response == :present
            return data.trial_type = :hit
        else
            return data.trial_type = :miss
        end
    end
    if data.target_present == :absent
        if data.response == :present
            return data.trial_type = :fa
        else
            return data.trial_type = :cr
        end
    end
end

get_width(ex) = ex.object_width

function conjunctive_ratio(ex, target_color, target_shape, present)
    distractor_color = setdiff(ex.colors, [target_color])[1]
    distractor_shape = setdiff(ex.shapes, [target_shape])[1]
    color_fun() = populate_features((:color,:shape), [distractor_color,target_shape])
    shape_fun() = populate_features((:color,:shape), [target_color,distractor_shape])
    visicon = [VisualObject(features=color_fun(), width=get_width(ex)) for _ in 1:ex.n_color_distractors]
    temp = [VisualObject(features=shape_fun(), width=get_width(ex)) for _ in 1:ex.n_shape_distractors]
    push!(visicon, temp...)
    if present == :present
        push!(visicon, VisualObject(features=populate_features((:color,:shape),
        [target_color,target_shape]), width=get_width(ex), target=true))
    end
    set_locations!(ex, visicon)
    return visicon
end

function conjunctive_set(ex, target_color, target_shape, present)
    distractor_color = setdiff(ex.colors, [target_color])[1]
    distractor_shape = setdiff(ex.shapes, [target_shape])[1]
    n = round(Int, ex.set_size/2)
    n = max(n, 1)
    color_fun() = populate_features((:color,:shape), [distractor_color,target_shape])
    shape_fun() = populate_features((:color,:shape), [target_color,distractor_shape])
    visicon = [VisualObject(features=color_fun(), width=get_width(ex)) for _ in 1:n]
    temp = [VisualObject(features=shape_fun(), width=get_width(ex)) for _ in 1:n]
    push!(visicon, temp...)
    n == 1 ? (visicon = [rand(visicon)]) : nothing
    if present == :present
        vo = rand(visicon)
        vo.target = true
        vo.features = populate_features((:color,:shape),
        [target_color,target_shape])
    end
    set_locations!(ex, visicon)
    return visicon
end

function feature_set(ex, target_color, target_shape, present)
    distractor_color = setdiff(ex.colors, [target_color])[1]
    color_fun() = populate_features((:color,:shape), [distractor_color,target_shape])
    visicon = [VisualObject(features=color_fun(), width=get_width(ex)) for _ in 1:ex.set_size]
    if present == :present
        vo = rand(visicon)
        vo.target = true
        vo.features = populate_features((:color,:shape),
        [target_color,target_shape])
    end
    set_locations!(ex, visicon)
    return visicon
end

function set_locations!(ex::Experiment, visicon)
    n = length(visicon)
    indices = [[r,c] for r in 1:ex.n_cells for c in 1:ex.n_cells]
    locations = sample(indices, n; replace=false)
    for (l,v) in zip(locations, visicon)
        set_location!(ex, v, l)
    end
end

"""
set location of visual object at center of object
"""
function set_location!(ex::Experiment, visual_object, indices)
    center = visual_object.width/2
    lb = @. ex.cell_width*(indices-1) + center
    ub = @. ex.cell_width*indices - center
    location = @. rand(Uniform(lb, ub))
    visual_object.location = location
    return nothing
end

function sample_target(ex)
    target_color = rand(ex.colors)
    target_shape = rand(ex.shapes)
    return (color=target_color,shape=target_shape)
end