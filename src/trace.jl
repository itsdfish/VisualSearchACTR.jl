function print_trial(ex)
    data = ex.current_trial
    println("trial info: ")
    println("   target present: ", data.target_present)
    println("   color: ", data.target_color)
    println("   shape: ", data.target_shape)
end

function print_visual_buffer(model)
    object = model.vision[1]
    println("visual object: ")
    println("   color: ", object.features.color.value)
    println("   shape: ", object.features.shape.value)
    println("   location: ", round.(object.location))
end

function get_time(model)
    return round(model.current_time, digits=3)
end
