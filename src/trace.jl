function print_trial(ex)
    data = ex.current_trial
    println("Trial info: ")
    println("\t  target................ ", data.target_present)
    println("\t  stimulus.............. ", Crayon(foreground=data.target_color), data.target_shape)
    print(Crayon(foreground=:default))
end

function print_visual_buffer(model)
    object = model.vision[1]
    println("Visual Buffer")
    println("\t  stimulus.............. ", Crayon(foreground=object.features.color.value),
        object.features.shape.value)
    print(Crayon(foreground=:default))
    println("\t  location.............. ", "x: ", round(Int, object.location[1]),
        " y: ", round(Int, object.location[2]))
    println("\t  activation............ ", round(object.activation, digits=2))
end

function get_time(model)
    return round(model.current_time, digits=3)
end

function print_response(model, response)
    println(get_time(model), " Motor................. respond $response")
end

function print_abstract_location(model, status)
    println(get_time(model), " Abstract-Location..... $status")
    println("\t  iconic memory size.... ", iconic_memory_size(model), " out of ", visicon_size(model))
    status != "object found" ? (return) : nothing
    result = model.abstract_location[1]
    angular_distance = compute_angular_distance(model, result)
    angular_size = result.angular_size
    parms = model.acuity[:color]
    color_threshold = compute_acuity_threshold(parms, angular_distance)
    parms = model.acuity[:shape]
    shape_threshold = compute_acuity_threshold(parms, angular_distance)
    println("\t  model focus........... ", "x: ", round(Int, model.focus[1]),
        " y: ", round(Int, model.focus[2]))
    println("\t  color threshold....... ", round.(color_threshold, digits=2), "°")
    println("\t  shape threshold....... ", round.(shape_threshold, digits=2), "°")
    println("\t  angular size.......... ", round.(angular_size, digits=2), "°")
    println("\t  angular distance...... ", round.(angular_distance, digits=2), "°")

end

iconic_memory_size(model) = sum(x->x.visible, model.iconic_memory)
visicon_size(model) = length(model.iconic_memory)
