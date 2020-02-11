function update_window!(model, ex)
    # for vo in model.iconic_memory
    #     draw_object!(ex, vo)
    # end
    refresh!(ex)
    draw_focus!(model, ex)
end

function draw_object!(ex, vo)
    c = ex.canvas
    win = ex.window
    w = vo.width
    x,y = vo.location
    color = get_color(vo)
    letter = get_text(vo)
    @guarded draw(c) do widget
        ctx = getgc(c)
        select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL,
             Cairo.FONT_WEIGHT_NORMAL);
        set_font_size(ctx, pixels_to_points(vo.width))
        #set_source(ctx, Cairo.alphacolor(@colorant_str @eval color,.5))
        extents = text_extents(ctx, letter)
        # x = 128.0-(extents[3]/2 + extents[1])
        # y = 128.0-(extents[4]/2 + extents[2])
        move_to(ctx, x, y - w/2)
        show_text(ctx, letter)

        circle(ctx, x + w/4, y - 15/4, w/2)
        set_source_rgba(ctx, 1, 0, 0, .5)
        # set_source(ctx, Cairo.alphacolor(colorant"red",.5))
        fill(ctx)
        restore(ctx)
    end
    Gtk.showall(c)
    return nothing
end

function draw_focus!(model, ex)
    c = ex.canvas
    win = ex.window
    w = model.iconic_memory[1].width
    x,y = model.focus
    println("draw focus: ", x, " ", y)
    @guarded draw(c) do widget
        ctx = getgc(c)
        circle(ctx, x + w/4, y - 15/4, w/2)
        set_source_rgba(ctx, 1, 0, 0, .5)
        # set_source(ctx, Cairo.alphacolor(colorant"red",.5))
        fill(ctx)
        #restore(ctx)
    end
    Gtk.showall(c)
    return nothing
end

function refresh!(ex)
    c = ex.canvas
    w = ex.array_width
    @guarded draw(c) do widget
        ctx = getgc(c)
        rectangle(ctx, 0, 0, w, w)
        set_source_rgb(ctx, .65, .65, .65)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

pixels_to_points(pixels) = pixels*3/4

points_to_pixels(points) = points*4/3

get_text(vo) = string(vo.features.shape.value)

get_color(vo) = string(vo.features.color.value)