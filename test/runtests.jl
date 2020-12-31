using SafeTestsets

@safetestset "Testing Finsts" begin
    using  PAAV, Test
    ex = Experiment()
    # target,present = initialize_trial!(ex)
    # iconic_memory = ex.populate_visicon(ex, target..., present)
    # model = Model(;target=target, iconic_memory=iconic_memory, current_time=4.0)
    visual_objects = ex.populate_visicon(ex, target..., present)
    T = typeof(visual_objects)
    visual_location = VisualLocation(buffer=T)
    visual_location.visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTR(;T=Parm, goal=goal, visual_location=visual_location, visual=visual)
    map(x->x.attended=true, iconic_memory)
    map(x->x.attend_time = 0.0, iconic_memory)
    iconic_memory[1].attend_time = 1.1
    iconic_memory[2].attend_time = 1.1
    iconic_memory[3].attend_time = 1.1
    iconic_memory[4].attend_time = 1.1
    iconic_memory[6].attend_time = 2.0
    PAAV.update_finst!(model)
    @test iconic_memory[6].attend_time == 2.0
    @test iconic_memory[6].attended
    @test sum(x->x.attended, iconic_memory) == model.n_finst
    @test maximum(x->x.attend_time, iconic_memory) <= model.finst_span
end

@safetestset "Testing Iconic Decay" begin
    using  PAAV, Test
    ex = Experiment()
    target,present = initialize_trial!(ex)
    iconic_memory = ex.populate_visicon(ex, target..., present)
    model = Model(;target=target, iconic_memory=iconic_memory, current_time=4.0,
        persistence=1.0)
    visible_objects = iconic_memory[1:5]
    map(x->x.features.color.visible=true, visible_objects[1:2])
    map(x->x.features.color.fixation_time=5.0, visible_objects[1:2])
    map(x->x.features.shape.visible=true, visible_objects[3:end])
    map(x->x.features.shape.fixation_time=6.0, visible_objects[3:end])
    map(x->PAAV.object_visibility!(x), model.iconic_memory)
    @test sum(x->x.visible, iconic_memory) == 5
    PAAV.update_decay!(model)
    map(x->PAAV.object_visibility!(x), model.iconic_memory)
    @test sum(x->x.visible, iconic_memory) == 5
    model.current_time = 6.5
    PAAV.update_decay!(model)
    map(x->PAAV.object_visibility!(x), model.iconic_memory)
    @test sum(x->x.visible, iconic_memory) == 3
end

@safetestset "Testing Activation" begin
    using  PAAV, Test

    vals = [(color = :gray, shape = :p, x = 338, y =515),
            (color = :black, shape = :q, x = 351 , y = 193),
            (color = :gray, shape = :q, x = 511 , y = 462),
            (color = :black, shape = :p, x = 511 , y = 400)]

    experiment = Experiment(n_trials=10^1, trace=true, visible=false)

    target = (color=:gray,shape=:p)
    visicon = [VisualObject(features=(color=Feature(;value=x.color), shape=Feature(;value=x.shape)), 
        width=32.0, location=[x.x-0.,x.y-0.]) for x in vals]

    model = Model(;target=target, iconic_memory=visicon, noise=0.0)
    PAAV.compute_angular_size!(model)
    model.focus = [324.0,324.0]
    PAAV.update_decay!(model)
    PAAV.update_finst!(model)
    PAAV.update_visibility!(model)
    PAAV.compute_activations!(model)

    correct_top_down = [2,0,1,1]
    @test all(x->x[2].topdown_activation == x[1], zip(correct_top_down, visicon))

    iconic_memory = model.iconic_memory
    vo1 = iconic_memory[1]
    vo2 = iconic_memory[2]
    distance = PAAV.compute_distance(vo1, vo2)
    bottomup_activation1 = PAAV.bottomup_activation(vo1.features, vo2.features, distance)
    @test bottomup_activation1 == 1/sqrt(distance)*2

    vo1 = iconic_memory[1]
    vo3 = iconic_memory[3]
    distance = PAAV.compute_distance(vo1, vo3)
    bottomup_activation2 = PAAV.bottomup_activation(vo1.features, vo3.features, distance)
    @test bottomup_activation2 == 1/sqrt(distance)

    vo1 = iconic_memory[1]
    vo4 = iconic_memory[4]
    distance = PAAV.compute_distance(vo1, vo4)
    bottomup_activation3 = PAAV.bottomup_activation(vo1.features, vo4.features, distance)
    @test bottomup_activation3 == 1/sqrt(distance)

    @test vo1.bottomup_activation == (bottomup_activation1 + bottomup_activation2 + bottomup_activation3)
end

@safetestset "Testing Feature Search" begin
    using PAAV, Test, DataFrames, GLM, Statistics
    include("simulation.jl")
    Random.seed!(95025181)
    set_sizes = [1,2,5,10,20,30]
    results = run_simulation(set_sizes, fun=feature_set, Δτ=.8, topdown_weight=.60)

    df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, results)
    ols_present = lm(@eval(@formula(rt_mean ~ distractors)), df_present)
    β0,β1 = coef(ols_present)
    @test β0 ≈ 0.36 rtol = .05
    @test β1 ≈ 0.0 atol = .01
    df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, results)
    ols_absent = lm(@eval(@formula(rt_mean ~ distractors)), df_absent)
    β0,β1 = coef(ols_absent)
    @test β0 ≈ 0.45 rtol = .05
    @test β1 ≈ 0.0 atol = .01
end

@safetestset "Testing Conjunctive Search" begin
    using PAAV, Test, DataFrames, GLM, Statistics
    include("simulation.jl")
    Random.seed!(52484)
    set_sizes = [1,2,5,10,20,30]
    results = run_simulation(set_sizes, fun=conjunctive_set, Δτ=.4, topdown_weight=.60)

    df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, results)
    ols_present = lm(@eval(@formula(rt_mean ~ distractors)), df_present)
    β0,β1 = coef(ols_present)
    @test β0 ≈ 0.34 rtol = .05
    @test β1 ≈ 0.020 atol = .01
    df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, results)
    ols_absent = lm(@eval(@formula(rt_mean ~ distractors)), df_absent)
    β0,β1 = coef(ols_absent)
    @test β0 ≈ 0.38 rtol = .05
    @test β1 ≈ 0.067 atol = .01
end

@safetestset "Gamma Parms" begin
    using PAAV, Test, Distributions
    import PAAV: gamma_parms

    θ = gamma_parms(3, 2)
    @test mean(Gamma(θ...)) ≈ 3 rtol = .0005
    @test std(Gamma(θ...)) ≈ 2 rtol = .0005

    θ = gamma_parms(.2, 1)
    @test mean(Gamma(θ...)) ≈ .2 rtol = .0005
    @test std(Gamma(θ...)) ≈ 1 rtol = .0005
end

@safetestset "Run model" begin
    using PAAV, Test
    experiment = Experiment(set_size=10,  n_trials=2,
        trace=true, speed =.5)
    run_condition!(experiment)
    @test true
end
