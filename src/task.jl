function populate_visicon!(ex::Experiment)
    target_color = rand(ex.colors)
    target_shape = rand(ex.shapes)
    rand() < ex.base_rate ? (present=true) : (present=false)
    ex.current_trial = Data()
    ex.current_trial.target_present = present
    ex.current_trial.target_shape = target_shape
    ex.current_trial.target_color = target_color
    distractor_color = setdiff(ex.colors, [target_color])[1]
    distractor_shape = setdiff(ex.shapes, [target_shape])[1]
    color_fun() = populate_features((:color,:shape), [distractor_color,target_shape])
    shape_fun() = populate_features((:color,:shape), [target_color,distractor_shape])
    visicon = [VisualObject(features=color_fun(), diameter=ex.diameter) for _ in 1:ex.n_color_distractors]
    temp = [VisualObject(features=shape_fun(), diameter=ex.diameter) for _ in 1:ex.n_shape_distractors]
    push!(visicon, temp...)
    if present
        push!(visicon, VisualObject(features=populate_features((:color,:shape),
        [target_color,target_shape]), diameter=ex.diameter))
    end
    set_locations!(ex, visicon)
    ex.visicon = visicon
    return nothing
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
    radius = visual_object.diameter/2
    lb = @. ex.cell_width*(indices-1) + radius
    ub = @. ex.cell_width*indices - radius
    location = @. rand(Uniform(lb, ub))
    visual_object.location = location
    return nothing
end
