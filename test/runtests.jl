using SafeTestsets

@safetestset "Testing Finsts" begin
    using  PAAV, Test
    ex = Experiment()
    target,present = initialize_trial!(ex)
    iconic_memory = ex.populate_visicon(ex, target..., present)
    model = Model(;target=target, iconic_memory=iconic_memory, current_time=4.0)
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

@safetestset "Testing Feature Search" begin
    using PAAV, Test, DataFrames, GLM, Statistics
    include("simulation.jl")
    Random.seed!(95025181)
    set_sizes = [1,2,5,10,20,30]
    results = run_simulation(set_sizes, fun=feature_set, Δτ=.8, topdownweight=.60)

    df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, results)
    ols_present = lm(@eval(@formula(rt_mean ~ distractors)), df_present)
    β0,β1 = coef(ols_present)
    @test β0 ≈ 0.36 rtol = .05
    @test β1 ≈ 0.0 atol = .01
    df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, results)
    ols_absent = lm(@eval(@formula(rt_mean ~ distractors)), df_absent)
    β0,β1 = coef(ols_absent)
    @test β0 ≈ 0.43 rtol = .05
    @test β1 ≈ 0.0 atol = .01
end

@safetestset "Testing Conjunctive Search" begin
    using PAAV, Test, DataFrames, GLM, Statistics
    include("simulation.jl")
    Random.seed!(52484)
    set_sizes = [1,2,5,10,20,30]
    results = run_simulation(set_sizes, fun=conjunctive_set, Δτ=.4, topdownweight=.60)

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
