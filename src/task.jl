function populate_visicon!(ex::Experiment)
    ex.current_trial = Data()
    target_color = rand(ex.colors)
    target_shape = rand(ex.shapes)
    rand() < ex.base_rate ? (present=true) : (present=false)
    ex.current_trial.present = present
    distractor_color = setdiff(ex.colors, target_color)[1]
    distractor_shape = setdiff(ex.shapes, target_shape)[1]
    color_fun() = populate_features((:color,:shape), [distractor_color,target_shape])
    shape_fun() = populate_features((:color,:shape), [target_color,distractor_shape])
    visicon = [VisualObject(features=color_fun(), diameter=ex.diameter) for _ in 1:ex.n_color_distractors]
    temp = [VisualObject(features=fshape_fun(), diameter=ex.diameter) for _ in 1:ex.n_shape_distractors]
    push!(visicon, temp...)
    if present
        push!(visicon, VisualObject(features=populate_features((:color,:shape),
        [target_color,target_shape]), diameter=ex.diameter))
    end
    set_locations!(visicon)
    ex.visicon = visicon
    return nothing
end

function set_locations!(ex::Experiment, visicon)
    n = length(visicon)
    indices = [(r,c) for r in 1:ex.n_grid for c in 1:ex.n_grid]
    locations = sample(indices, n; replace=false)
end
