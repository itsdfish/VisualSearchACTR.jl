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
	angular_size::Float64
	activation::Float64
	bottomup_activation::Float64
	topdown_activation::Float64
	location::Vector{Float64}
	attend_time::Float64
	target::Bool
end

function VisualObject(;features, attended=false, visible=false, width=0.0, angular_size=0.0, location=[0.0,0.0],
		attend_time=0.0, target=false)
	return VisualObject(features, attended, visible, width, 0.0, 0.0, 0.0, 0.0, location, attend_time,
		target)
end

"""
* `iconic_memory`: a vector of visible objects in iconic memory
* `target`: attributes of search target
* `abstract_location`: a buffer that holds a visual object for a "where" request
* `vision`: a buffer that holds an attended visual object following a "what" request
* `viewing_distance`: distance between model and screen in inches (30 inches)
* `current_time`: current model processing time during a trial
* `focus`: x and y coordinants of the model's current fixation point
* `top_down_weight`: a weight for the influence of top-down activation (1.1)
* `bottom_up_weight`: a weight for the influence of bottom-up activation (0.4)
* `noise`: noise added to visual activation
* `τₐ`: activation threshold for terminating search
*  `Δτ`: activation threshold increment following a fixation to a distractor
"""
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
	persistance::Float64
	acuity::A
	n_finst::Int64
	finst_span::Float64
	β₀exe::Float64
	Δexe::Float64
	τₐ::Float64
	Δτ::Float64
end

function Model(;iconic_memory, target, viewing_distance=30.0, current_time=0.0, focus=fill(0.0, 2),
	topdownweight=.4, bottomup_weight=1.1, noise=.36, persistence=4.0, a_color=.104,b_color=.85,
	a_shape=.142, b_shape=.96, n_finst=4, finst_span=3.0, β₀exe=.02, Δexe=.002, τₐ=0.0, Δτ=0.5)
	abstract_location = similar(iconic_memory, 0)
	vision = similar(iconic_memory, 0)
	acuity = (color = (a=a_color,b=b_color), shape = (a=a_shape,b=b_shape))
	return Model(iconic_memory, target, abstract_location, vision, viewing_distance, current_time,
		focus,topdownweight, bottomup_weight, noise, persistence, acuity, n_finst, finst_span, β₀exe,
		Δexe, τₐ, Δτ)
end

mutable struct Data
	target_present::Symbol
	target_color::Symbol
	target_shape::Symbol
	response::Symbol
	rt::Float64
end

Data() = Data(:_, :_, :_, :_, 0.0)

mutable struct Experiment{T1,T2,F}
	array_width::Float64
	n_cells::Int64
	n_trials::Int64
	cell_width::Float64
	object_width::Float64
	n_color_distractors::Int64
	n_shape_distractors::Int64
	set_size::Int64
	colors::Vector{Symbol}
	shapes::Vector{Symbol}
	base_rate::Float64
	data::Vector{Data}
	current_trial::Data
	trace::Bool
	window::T1
	canvas::T2
	visible::Bool
	speed::Float64
	populate_visicon::F
end

function Experiment(;array_width=428., object_width=32.0, n_cells=8, n_trials=20,
	n_color_distractors=20, set_size=40, n_shape_distractors=20, shapes=[:p,:q], colors=[:red,:blue],
	base_rate=.50, data=Data[], current_trial=Data(), trace=false, window=nothing, canvas=nothing,
	visible=false, speed=1.0, populate_visicon=conjunctive_ratio)
	cell_width = array_width/n_cells
	@argcheck  cell_width > object_width
	@argcheck n_color_distractors + n_shape_distractors + 1 <= n_cells^2
	visible ? ((canvas,window) = setup_window(array_width)) : nothing
    visible ? Gtk.showall(window) : nothing
	return Experiment(array_width, n_cells, n_trials, cell_width, object_width,
		n_color_distractors, n_shape_distractors, set_size, colors, shapes, base_rate,
		data, current_trial, trace, window, canvas, visible, speed, populate_visicon)
end

function setup_window(array_width)
	canvas = @GtkCanvas()
    window = GtkWindow(canvas, "PAAV", array_width, array_width)
    Gtk.visible(window, true)
    @guarded draw(canvas) do widget
        ctx = getgc(canvas)
        rectangle(ctx, 0.0, 0.0, array_width, array_width)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
	return canvas,window
end
