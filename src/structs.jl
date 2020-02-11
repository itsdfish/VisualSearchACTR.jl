mutable struct Feature{T}
    fixation_time::Float64
    visible::Bool
	value::T
end

Feature(;fixation_time=0.0, visible=false, value) = Feature(fixation_time, visible, value)

function populate_features(features, values)
	vals = [Feature(value=v) for v in values]
	return NamedTuple{features}(vals)
end

mutable struct VisualObject{F}
	features::F
    attended::Bool
    visible::Bool
	width::Float64
	activation::Float64
	bottomup_activation::Float64
	topdown_activation::Float64
	location::Vector{Float64}
end

function VisualObject(;features, attended=false, visible=false, width=0.0, location=[0.0,0.0])
	return VisualObject(features, attended, visible, width, 0.0, 0.0, 0.0, location)
end

mutable struct Model{A,B,T,F}
    iconic_memory::Vector{VisualObject{F}}
	target::T
	abstract_location::B
	vision::B
    viewing_distance::Float64
	current_time::Float64
	focus::Vector{Float64}
	topdown_weight::Float64
	bottomup_weight::Float64
	noise::Float64
	activation_threshold::Float64
	distance_threshold::Float64
	persistance::Float64
	acuity::A
end

function Model(;iconic_memory, target, viewing_distance=30.0, current_time=0.0, focus=fill(0.0, 2),
	topdownweight=.4, bottomup_weight=1.1, noise=.2, threshold=0.0, persistence=4.0, a_color=.104,
	b_color=.85, a_shape=.142, b_shape=.96)
	abstract_location = similar(iconic_memory, 0)
	vision = similar(iconic_memory, 0)
	acuity = (color = (a=a_color,b=b_color), shape = (a=a_shape,b=b_shape))
	return Model(iconic_memory, target, abstract_location, vision, viewing_distance, current_time, focus,
		topdownweight, bottomup_weight, noise, -Inf, Inf, persistence, acuity)
end

mutable struct Data
	target_present::Bool
	target_color::Symbol
	target_shape::Symbol
	response::Symbol
	rt::Float64
end

Data() = Data(false, :_, :_, :_, 0.0)

mutable struct Experiment
	array_width::Float64
	n_cells::Int64
	n_trials::Int64
	cell_width::Float64
	object_width::Float64
	n_color_distractors::Int64
	n_shape_distractors::Int64
	colors::Vector{Symbol}
	shapes::Vector{Symbol}
	base_rate::Float64
	data::Vector{Data}
	current_trial::Data
	trace::Bool
end

function Experiment(;array_width=430, object_width=30.0, n_cells=8, n_trials=20,
	n_color_distractors=20, n_shape_distractors=20, shapes=[:q,:p], colors=[:red,:blue],
	base_rate=.50, data=Data[], current_trial=Data(), trace=false)
	cell_width = array_width/n_cells
	@argcheck  cell_width > object_width
	@argcheck n_color_distractors + n_shape_distractors + 1 <= n_cells^2
	return Experiment(array_width, n_cells, n_trials, cell_width, object_width,
		n_color_distractors, n_shape_distractors, colors, shapes, base_rate, data,
		current_trial, trace)
end
