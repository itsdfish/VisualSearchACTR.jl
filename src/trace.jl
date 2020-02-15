function print_trial(ex)
    data = ex.current_trial
    println("Trial info: ")
    println("   \ttarget................ ", data.target_present)
    println("   \tstimulus.............. ", Crayon(foreground=data.target_color), data.target_shape)
    print(Crayon(foreground=:default))
end

function print_visual_buffer(model)
    object = model.vision[1]
    println("Visual Buffer")
    println("   \tstimulus.............. ", Crayon(foreground=object.features.color.value),
        object.features.shape.value)
    print(Crayon(foreground=:default))
    println("   \tlocation.............. ", round.(object.location))
    println("   \tactivation............ ", round.(object.activation, digits=2))
end

function get_time(model)
    return round(model.current_time, digits=3)
end

function print_response(model, response)
    println(get_time(model), " Motor............... respond $response")
end

function print_abstract_location(model, status)
    println(get_time(model))
    println(get_time(model), " Abstract-Location... object $status")
    status != "found" ? (return) : nothing
    result = model.abstract_location
    println("  \tangular size.......... ", round.(compute_angular_distance(model, result[1]),
        digits=2), "°")
end
