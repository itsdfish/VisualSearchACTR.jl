function print_trial(ex)
    data = ex.current_trial
    println("Trial info: ")
    println("\t  target.................... ", data.target_present)
    println("\t  stimulus.................. ", Crayon(foreground=data.target_color), data.target_shape)
    print(Crayon(foreground=:default))
end

function print_visual_buffer(actr)
    object = actr.visual.buffer[1]
    println("Visual Buffer")
    println("\t  stimulus.................. ", Crayon(foreground=object.features.color.value),
        object.features.shape.value)
    print(Crayon(foreground=:default))
    println("\t  location.................. ", "x: ", round(Int, object.location[1]),
        " y: ", round(Int, object.location[2]))
    println("\t  activation................ ", round(object.activation, digits=2))
    println("\t  attend time .............. ", round.(object.attend_time, digits=3))

end

function get_time(actr)
    return round(actr.time, digits=3)
end

function print_response(actr, response)
    println(get_time(actr), " Motor..................... respond $response")
end

function print_abstract_location(actr, status)
    println(get_time(actr), " Abstract-Location......... $status")
    println("\t  iconic memory size........ ", iconic_memory_size(actr), " out of ", visicon_size(actr))
    println("\t  termination probability... ", "≈ ", round(termination_prob(actr), digits=2))
    status != "object found" ? (return) : nothing
    result = actr.visual_location.buffer[1]
    angular_distance = compute_angular_distance(actr, result)
    angular_size = result.angular_size
    parms = actr.parms.acuity[:color]
    color_threshold = compute_acuity_threshold(parms, angular_distance)
    parms = actr.parms.acuity[:shape]
    shape_threshold = compute_acuity_threshold(parms, angular_distance)
    println("\t  model focus............... ", "x: ", round(Int, actr.visual.focus[1]),
        " y: ", round(Int, actr.visual.focus[2]))
    println("\t  color threshold........... ", round.(color_threshold, digits=2), "°")
    println("\t  shape threshold........... ", round.(shape_threshold, digits=2), "°")
    println("\t  angular size.............. ", round.(angular_size, digits=2), "°")
    println("\t  angular distance.......... ", round.(angular_distance, digits=2), "°")
end

function print_vision(actr)
    println(get_time(actr), " Vision","."^20, " object attended.")
end

print_check(actr, v) = println(get_time(actr), " Procedural","."^16, " target $v")

iconic_memory_size(actr) = sum(x->x.visible, get_iconic_memory(actr))

visicon_size(actr) = length(get_iconic_memory(actr))

function termination_prob(actr)
    σ = actr.parms.noise
    τ = actr.parms.τₐ
    vos = filter(x->relevant_object(actr, x), get_iconic_memory(actr))
    α = map(x->weighted_activation(actr, x), vos)
    push!(α, τ)
    return exp(τ/σ)/sum(exp.(α/σ))
end
