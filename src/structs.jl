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

mutable struct VisualObject{F,T} <:AbstractVisualObject
	features::F
    attended::Bool
    visible::Bool
	width::Float64
	angular_size::Float64
	activation::T
	bottomup_activation::Float64
	topdown_activation::Float64
	location::Vector{Float64}
	attend_time::Float64
	target::Bool
end

function VisualObject(;features, attended=false, visible=false, width=0.0, angular_size=0.0, location=[0.0,0.0],
		attend_time=0.0, target=false, activation=0.0)
	return VisualObject(features, attended, visible, width, 0.0, activation, 0.0, 0.0, location, attend_time,
		target)
end

"""
* `viewing_distance`: distance between model and screen in inches (30 inches)
* `current_time`: current model processing time during a trial
* `topdown_weight`: a weight for the influence of top-down activation (1.1)
* `bottomup_weight`: a weight for the influence of bottom-up activation (0.4)
* `noise`: noise added to visual activation
* `persistence`: time during which visible visual objects can stay in iconic memory
* `acuity`: NamedTuple of acuity parameters
* `n_finst`: number of visual objects in finst
* `finst_span`: the duration of finst
* `τₐ`: activation threshold for terminating search
*  `Δτ`: activation threshold increment following a fixation to a distractor
"""
mutable struct Parm{A,T,T1} <: AbstractParms
    viewing_distance::Float64
	topdown_weight::T1
	bottomup_weight::Float64
	noise::Bool
	rnd_time::Bool
	σ::Float64
	persistence::Float64
	acuity::A
	n_finst::Int64
	finst_span::Float64
	β₀exe::Float64
	Δexe::Float64
	τₐ::Float64
	Δτ::Float64
	misc::T
end

function Parm(;viewing_distance=30.0, topdown_weight=.66, bottomup_weight=1.1, noise=false, rnd_time=false, 
	σ=.2*π/sqrt(3), persistence=4.0, a_color=.104, b_color=.85, a_shape=.142, b_shape=.96, n_finst=4, 
	finst_span=3.0, β₀exe=.02, Δexe=.002, τₐ=0.0, Δτ=0.39, args...)
	acuity = (color = (a=a_color,b=b_color), shape = (a=a_shape,b=b_shape))
	return Parm(viewing_distance, topdown_weight, bottomup_weight, 
		noise, rnd_time, σ, persistence, acuity, n_finst, finst_span, β₀exe, Δexe, τₐ, Δτ, args.data)
end

"""
**ACTRV**

ACTR model object
- `declarative`: declarative memory module
- `imaginal`: imaginal memory module
- `visual`: visual module
- `goal`: goal module
- `visual_location`: visual location module
- `parms`: model parameters
- `time`: model time

Constructor
````julia 
ACTRV(;declarative=Declarative(), imaginal=Imaginal(), goal = Goal(), 
    scheduler=nothing, visual=nothing, visual_location=nothing, time=0.0, parms...) 
````
"""
mutable struct ACTRV{T1,T2,T3,T4,T5,T6,T7} <: AbstractACTR
    declarative::T1
    imaginal::T2
    visual::T3
    visual_location::T4
    goal::T5
    parms::T6
    time::T7
end

function ACTRV(;declarative=Declarative(), imaginal=Imaginal(), goal = Goal(), 
    scheduler=nothing, visual=nothing, visual_location=nothing, time=0.0, parms...) 
    parms′ = Parm(;parms...)
    ACTRV(declarative, imaginal, visual, visual_location, goal, parms′, time)
end

mutable struct Fixation
	target_color::Symbol
	target_shape::Symbol
	attend_time::Float64
	idx::Int
	stop::Bool
end

Fixation(;color, shape, attend_time, idx, stop) = Fixation(color, shape, attend_time, idx, stop)

mutable struct Data
	target_present::Symbol
	target_color::Symbol
	target_shape::Symbol
	trial_type::Symbol
	response::Symbol
	rt::Float64
end

Data() = Data(fill(:_,5)..., 0.0)


"""
** Experiment **

* `array_width`: with of visual array in pixels
* `n_cells`: number of cells in visual array grid
* `n_trials`: number of trials in simulation
* `cell_width`: width of cell that contains ≤ 1 visual objects
* `object_width`: width of visual object in pixels
* `n_color_distractors`: number of distractors for color
* `n_shape_distractors`: number of distractors for shape
* `set_size`: number of elements in visual array
* `colors`: tuple of colors
* `shapes`: tuple of shapes
* `base_rate`: probability that target is present
* `data`: Array of Data for all trials
* `trial_data`: Data for current trial
* `fixations`: Array of fixations for all trials
* `trial_fixations`: fixations for current trial
* `trace`: displays trace if true
* `window`: GUI window
* `canvas`: GUI canvas
* `visible`: displays GUI if true
* `speed`: how quickly to simulate the model if trace is on
* `populate_visicon`: a function that populates the visicon
"""
mutable struct Experiment{T1,T2,F<:Function}
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
	trial_data::Data
	fixations::Vector{Vector{Fixation}}
	trial_fixations::Vector{Fixation}
	trace::Bool
	window::T1
	canvas::T2
	visible::Bool
	speed::Float64
	populate_visicon::F
end

function Experiment(;array_width=428., object_width=32.0, n_cells=8, n_trials=20,
	n_color_distractors=20, set_size=40, n_shape_distractors=20, shapes=[:p,:q], colors=[:red,:blue],
	base_rate=.50, data=Data[], trial_data=Data(), fixations=Vector{Vector{Fixation}}(), trial_fixations=Fixation[],
	trace=false, window=nothing, canvas=nothing, visible=false, speed=1.0, populate_visicon=conjunctive_ratio)
	cell_width = array_width/n_cells
	@argcheck  cell_width > object_width
	@argcheck n_color_distractors + n_shape_distractors + 1 <= n_cells^2
	visible ? ((canvas,window) = setup_window(array_width)) : nothing
    visible ? Gtk.showall(window) : nothing
	return Experiment(array_width, n_cells, n_trials, cell_width, object_width,
		n_color_distractors, n_shape_distractors, set_size, colors, shapes, base_rate,
		data, trial_data, fixations, trial_fixations, trace, window, canvas, visible, speed, populate_visicon)
end

function import_gui()
    path = @__DIR__
    include(path*"/draw.jl")
end