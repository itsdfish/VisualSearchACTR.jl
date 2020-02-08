mutable struct Feature{T}
    time_elapsed::Float64
    visible::Bool
	value::T
	a::Float64
	b::Float64
end

Feature(;time_elapsed=0.0, visible=false, value, a=0.0, b=0.0) = Feature(time_elapsed, visible, value, a, b)

function populate_features(features, values)
	vals = [Feature(value=v) for v in values]
	return NamedTuple{features}(vals)
end

mutable struct VisualObject{F}
	features::F
    attended::Bool
    visible::Bool
	diameter::Float64
	location::Vector{Float64}
end

function VisualObject(;features, attended=false, visible=false, diameter=0.0, location=[0.0,0.0])
	return VisualObject(features, attended, visible, diameter, location)
end

mutable struct Model
    iconic_memory::Vector{<:VisualObject}
    viewing_distance::Float64
	current_time::Float64
	attention_x::Float64
	attention_y::Float64
	topdown_weight::Float64
	bottomup_weight::Float64
	noise::Float64
	threashold::Float64
	duration::Float64
end

function Model(;iconcic_memory, viewing_distance=40.0, current_time=0.0, attention_x=0.0, attention_y=0.0,
	topdown_weight=.40, buttomup_weight=1.1, noise=.2, threshold=0.0, duration=0.0)
	return Model(iconcic_memory, viewing_distance, current_time, attention_x, attention_y,
		topdown_weight, buttomup_weight, noise, threshold, duration)
end

mutable struct Data
	target_present::Bool
	target_color::Symbol
	target_shape::Symbol
	choice::String
	rt::Float64
end

Data() = Data(false, "", 0.0, :_, :_)

mutable struct Experiment
	visicon::Vector{<:VisualObject}
	width::Float64
	n_cells::Int64
	n_trials::Int64
	cell_width::Float64
	n_color_distractors::Int64
	n_shape_distractors::Int64
	colors::Vector{Symbol}
	shapes::Vector{Symbol}
	base_rate::Float64
	diameter::Float64
	data::Vector{Data}
	current_trial::Data
end

function Experiment(;visicon=VisualObject[], width=15.0, n_cells=10, n_trials=20,
	n_color_distractors=20, n_shape_distractors=20, shapes=[:q,:p], colors=[:red,:blue],
	base_rate=.50, diameter=.5, data=Data[], current_trial=Data())
	cell_width = width/n_cells
	@argcheck  cell_width > diameter
	@argcheck n_color_distractors + n_shape_distractors + 1 <= n_cells^2
	return Experiment(visicon, width, n_cells, n_trials, cell_width, n_color_distractors,
	 n_shape_distractors, colors, shapes, base_rate, diameter, data,current_trial)
end
