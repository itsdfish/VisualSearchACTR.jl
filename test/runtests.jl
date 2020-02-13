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

@safetestset "Testing Feature Search" begin
    using PAAV, Test, DataFrames, GLM, Random, Statistics
    include("simulation.jl")
    Random.seed!(95025181)
    set_sizes = [1,2,5,10,20,30]
    results = run_simulation(set_sizes, fun=feature_set)

    df_present = filter(x->x[:target_present] ==:present && x[:response] ==:present, results)
    ols_present = lm(@eval(@formula(rt_mean ~ distractors)), df_present)
    β0,β1 = coef(ols_present)
    @test β0 ≈ 0.40 rtol = .05
    @test β1 ≈ 0.0 atol = .01
    df_absent = filter(x->x[:target_present] ==:absent && x[:response] ==:absent, results)
    ols_absent = lm(@eval(@formula(rt_mean ~ distractors)), df_absent)
    β0,β1 = coef(ols_absent)
    @test β0 ≈ 0.43 rtol = .05
    @test β1 ≈ 0.0 atol = .01
end
