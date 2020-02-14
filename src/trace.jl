function print_trial(ex)
    data = ex.current_trial
    println("trial info: ")
    println("   target present: ", data.target_present)
    println("   stimulus: ", Crayon(foreground=data.target_color), data.target_shape)
    print(Crayon(foreground=:default))
end

function print_visual_buffer(model)
    object = model.vision[1]
    println("visual buffer: ")
    println("   stimulus: ", Crayon(foreground=object.features.color.value),
        object.features.shape.value)
    print(Crayon(foreground=:default))
    println("   location: ", round.(object.location))
end

function get_time(model)
    return round(model.current_time, digits=3)
end

function print_response(model, response)
    println(get_time(model), " response: $response")
end
