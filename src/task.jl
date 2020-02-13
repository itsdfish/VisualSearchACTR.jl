function initialize_trial!(ex::Experiment)
    target = sample_target(ex)
    rand() < ex.base_rate ? (present=:present) : (present=:absent)
    ex.current_trial = Data()
    ex.current_trial.target_present = present
    ex.current_trial.target_shape = target.shape
    ex.current_trial.target_color = target.color
    return target,present
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
        [target_color,target_shape]), width=get_width(ex)))
    end
    set_locations!(ex, visicon)
    return visicon
end

function conjunctive_set(ex, target_color, target_shape, present)
    distractor_color = setdiff(ex.colors, [target_color])[1]
    distractor_shape = setdiff(ex.shapes, [target_shape])[1]
    n = round(Int, ex.set_size/2)
    color_fun() = populate_features((:color,:shape), [distractor_color,target_shape])
    shape_fun() = populate_features((:color,:shape), [target_color,distractor_shape])
    visicon = [VisualObject(features=color_fun(), width=get_width(ex)) for _ in 1:n]
    temp = [VisualObject(features=shape_fun(), width=get_width(ex)) for _ in 1:n]
    push!(visicon, temp...)
    if present == :present
        vo = rand(visicon)
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
