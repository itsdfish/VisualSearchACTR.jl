using SafeTestsets

@safetestset "Testing Finsts" begin
    using VisualSearchACTR, Test
    using VisualSearchACTR: update_finst!
    ex = Experiment()
    target,present = initialize_trial!(ex)
    visual_objects = ex.populate_visicon(ex, target..., present)
    T = typeof(visual_objects)
    visual_location = VisualLocation(buffer=T)
    visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTRV(;T=Parm, goal, visual_location, visual, visicon)
    iconic_memory = get_iconic_memory(actr)
    map(x -> x.attended = true, iconic_memory)
    map(x -> x.attend_time = 0.0, iconic_memory)
    iconic_memory[1].attend_time = 1.1
    iconic_memory[2].attend_time = 1.1
    iconic_memory[3].attend_time = 1.1
    iconic_memory[4].attend_time = 1.1
    iconic_memory[6].attend_time = 2.0
    update_finst!(actr)
    @test iconic_memory[6].attend_time == 2.0
    @test iconic_memory[6].attended
    @test sum(x -> x.attended, iconic_memory) == actr.parms.n_finst
    @test maximum(x -> x.attend_time, iconic_memory) <= actr.parms.finst_span
end

@safetestset "Testing Iconic Decay" begin
    using  VisualSearchACTR, Test
    ex = Experiment()
    target,present = initialize_trial!(ex)
    visual_objects = ex.populate_visicon(ex, target..., present)
    T = typeof(visual_objects)
    visual_location = VisualLocation(buffer=T)
    visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTRV(;T=Parm, goal, visual_location, visual, persistence=1.0,
        visicon, time=4.0)
    iconic_memory = get_iconic_memory(actr)
    visible_objects = iconic_memory[1:5]
    map(x -> x.features.color.visible=true, visible_objects[1:2])
    map(x -> x.features.color.fixation_time=5.0, visible_objects[1:2])
    map(x -> x.features.shape.visible=true, visible_objects[3:end])
    map(x -> x.features.shape.fixation_time=6.0, visible_objects[3:end])
    map(x -> VisualSearchACTR.object_visibility!(x), iconic_memory)
    @test sum(x -> x.visible, iconic_memory) == 5
    VisualSearchACTR.update_decay!(actr)
    map(x -> VisualSearchACTR.object_visibility!(x), iconic_memory)
    @test sum(x -> x.visible, iconic_memory) == 5
    actr.time = 6.5
    VisualSearchACTR.update_decay!(actr)
    map(x -> VisualSearchACTR.object_visibility!(x), iconic_memory)
    @test sum(x -> x.visible, iconic_memory) == 3
end

@safetestset "Testing Activation" begin
    using VisualSearchACTR, Test
    using VisualSearchACTR: update_decay!
    using VisualSearchACTR: update_finst!
    using VisualSearchACTR: update_visibility!
    using VisualSearchACTR: compute_activations!
    using VisualSearchACTR: compute_distance
    using VisualSearchACTR: bottomup_activation
    using VisualSearchACTR: compute_angular_size!

    vals = [(color = :gray, shape = :p, x = 338, y =515),
            (color = :black, shape = :q, x = 351 , y = 193),
            (color = :gray, shape = :q, x = 511 , y = 462),
            (color = :black, shape = :p, x = 511 , y = 400)]

    ppi = 72
    experiment = Experiment(;n_trials=10^1, trace=true, visible=false, ppi)

    target = (color=:gray,shape=:p)
    visual_objects = [VisualObject(features=(color=Feature(;value=x.color), shape=Feature(;value=x.shape)), 
        width=32.0, location=[x.x-0.,x.y-0.]) for x in vals]

    T = typeof(visual_objects)
    visual_location = VisualLocation(buffer=T)
    visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTRV(;T=Parm, goal, visual_location, visual, visicon, σ=0.0)
    iconic_memory = get_iconic_memory(actr)

    # model = Model(;target=target, iconic_memory=visicon, noise=0.0)
    compute_angular_size!(actr, ppi)
    actr.visual.focus = [324.0,324.0]
    update_decay!(actr)
    update_finst!(actr)
    update_visibility!(actr, ppi)
    compute_activations!(actr)

    correct_top_down = [2,0,1,1]
    @test all(x -> x[2].topdown_activation == x[1], zip(correct_top_down, iconic_memory))

    vo1 = iconic_memory[1]
    vo2 = iconic_memory[2]
    distance = compute_distance(vo1, vo2)
    bottomup_activation1 = bottomup_activation(vo1.features, vo2.features, distance)
    @test bottomup_activation1 == 1 / sqrt(distance) * 2

    vo1 = iconic_memory[1]
    vo3 = iconic_memory[3]
    distance = compute_distance(vo1, vo3)
    bottomup_activation2 = bottomup_activation(vo1.features, vo3.features, distance)
    @test bottomup_activation2 == 1 / sqrt(distance)

    vo1 = iconic_memory[1]
    vo4 = iconic_memory[4]
    distance = compute_distance(vo1, vo4)
    bottomup_activation3 = bottomup_activation(vo1.features, vo4.features, distance)
    @test bottomup_activation3 == 1 / sqrt(distance)

    @test vo1.bottomup_activation == (bottomup_activation1 + bottomup_activation2 + bottomup_activation3)
end

@safetestset "Testing Feature Search" begin
    using VisualSearchACTR, Test, DataFrames, GLM, Statistics
    include("simulation.jl")
    Random.seed!(95025181)
    set_sizes = [1,2,5,10,20,30]
    Δτ = .8
    topdown_weight = .60
    noise = true
    rnd_time = true
    results = run_simulation(set_sizes; fun=feature_set, Δτ, topdown_weight, noise, rnd_time)

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
    using VisualSearchACTR, Test, DataFrames, GLM, Statistics
    include("simulation.jl")
    Random.seed!(52484)
    set_sizes = [1,2,5,10,20,30]
    Δτ = .4
    topdown_weight = .60
    noise = true
    rnd_time = true
    results = run_simulation(set_sizes; fun=conjunctive_set, Δτ, topdown_weight, noise, rnd_time)

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
    using VisualSearchACTR, Test, Distributions
    import VisualSearchACTR: gamma_parms

    μ = 3.0
    θ = gamma_parms(μ, .5)
    @test mean(Gamma(θ...)) ≈ 3 rtol = .0005
    @test std(Gamma(θ...)) ≈ .5 * μ rtol = .0005

    μ = .8
    θ = gamma_parms(μ, 1)
    @test mean(Gamma(θ...)) ≈ μ rtol = .0005
    @test std(Gamma(θ...)) ≈ μ rtol = .0005
end

@safetestset "angular size" begin
    # https://www.1728.org/angsize.htm
    # https://rechneronline.de/sehwinkel/angular-diameter.php
    using VisualSearchACTR, Test
    using VisualSearchACTR: compute_angular_size

    angular_size = compute_angular_size(10, .5)
    @test angular_size ≈ 2.8642 atol = 4

    angular_size = compute_angular_size(.5, 20)
    @test angular_size ≈ 174.28 atol = 2

    angular_size = compute_angular_size(30, 2)
    @test angular_size ≈ 3.8183 atol = 4

    angular_size = compute_angular_size(300, 20)
    @test angular_size ≈ 3.8183 atol = 4
end

@safetestset "angular distance" begin
    # https://www.1728.org/angsize.htm
    # https://rechneronline.de/sehwinkel/angular-diameter.php
    using VisualSearchACTR, Test
    using VisualSearchACTR: compute_angular_distance
    using VisualSearchACTR: compute_distance

    ppi = 72
    target = (color=:blue,)
    vo = VisualObject(; features = (color=:blue,), 
                        attended = false, 
                        visible = true, 
                        width = 30., 
                        angular_size=0.0, 
                        location=[10.0,10.0])
    visual_objects = [vo]
    T = typeof(visual_objects)
    visual_location = VisualLocation(buffer=T)
    visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTRV(;T=Parm, goal, visual_location, visual, visicon, viewing_distance = 30.0)

    actr.visual.focus = [0.0,0.0]

    angular_size = compute_angular_distance(actr, vo, ppi)
    @test angular_size ≈ 0.3751 atol = 4
end

@safetestset "acuity" begin
    # https://www.1728.org/angsize.htm
    # https://rechneronline.de/sehwinkel/angular-diameter.php
    using VisualSearchACTR, Test
    using VisualSearchACTR: compute_angular_distance
    using VisualSearchACTR: compute_distance
    using VisualSearchACTR: compute_acuity_threshold
    using VisualSearchACTR: feature_visibility!
    using VisualSearchACTR: populate_features

    ppi = 72
    target = (color=:blue,)
    vo = VisualObject(; features = populate_features((:color,),(:blue,)), 
                        attended = false, 
                        visible = true, 
                        angular_size = .85, 
                        location=[250.0,250.0])
    visual_objects = [vo]
    T = typeof(visual_objects)
    visual_location = VisualLocation(buffer=T)
    visicon = visual_objects
    visual_location.iconic_memory = visual_objects
    target_chunk = Chunk(;target...)
    goal = Goal(buffer=target_chunk)
    visual = Visual(buffer=T)
    actr = ACTRV(;T=Parm, goal, visual_location, visual, visicon, viewing_distance = 30.0)

    actr.visual.focus = [0.0,0.0]

    a_parms = actr.parms.acuity[:color]

    angular_distance = compute_angular_distance(actr, vo, ppi)

    threshold = compute_acuity_threshold(a_parms, angular_distance)

    vo.angular_size = threshold + .001
    feature_visibility!(actr, vo, ppi)
    @test vo.features[:color].visible

    vo.angular_size = threshold - .001
    vo.features[:color].visible = false
    feature_visibility!(actr, vo, ppi)
    @test !vo.features[:color].visible

end

@safetestset "Run model" begin
    using VisualSearchACTR, Test
    experiment = Experiment(set_size=10,  n_trials=2,
        trace=true, speed =.5)
    run_condition!(experiment)
    @test true
end