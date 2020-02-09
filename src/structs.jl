mutable struct Feature{T}
    fixation_time::Float64
    visible::Bool
	value::T
	a::Float64
	b::Float64
end

Feature(;fixation_time=0.0, visible=false, value, a=0.0, b=0.0) = Feature(time_elapsed, visible, value, a, b)

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

mutable struct Model{B,T,F}
    iconic_memory::Vector{<:VisualObject{F}}
	target::T
	abstract_location::B
	vision::B
    viewing_distance::Float64
	current_time::Float64
	focus::Vector{Float64}
	topdown_weight::Float64
	bottomup_weight::Float64
	noise::Float64
	threshold::Float64
	persistance::Float64

end

function Model(;iconic_memory, target, viewing_distance=40.0, current_time=0.0, focus=fill(0.0, 2),
	topdownweight=.4, bottomup_weight=1.1, noise=.2, threshold=0.0, persistence=4.0)
	abstract_location = similar(iconic_memory, 0)
	vision = similar(iconic_memory, 0)
	return Model(iconic_memory, target, abstract_location, vision, viewing_distance, current_time, focus,
		topdownweight, bottomup_weight, noise, threshold, persistence)
end

mutable struct Data
	target_present::Bool
	target_color::Symbol
	target_shape::Symbol
	choice::String
	rt::Float64
end

Data() = Data(false, :_, :_, "", 0.0)

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
end

function Experiment(;array_width=15.0, object_width=.5, n_cells=10, n_trials=20,
	n_color_distractors=20, n_shape_distractors=20, shapes=[:q,:p], colors=[:red,:blue],
	base_rate=.50, data=Data[], current_trial=Data())
	cell_width = array_width/n_cells
	@argcheck  cell_width > object_width
	@argcheck n_color_distractors + n_shape_distractors + 1 <= n_cells^2
	return Experiment(array_width, n_cells, n_trials, cell_width, object_width,
	n_color_distractors, n_shape_distractors, colors, shapes, base_rate, data,current_trial)
end
