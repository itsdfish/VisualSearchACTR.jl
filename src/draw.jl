function update_window!(model, ex)
    refresh!(ex)
    draw_target!(model, ex)
    draw_focus!(model, ex)
    bounds = get_min_max(model)
    for vo in model.iconic_memory
        heat = compute_heat(vo, bounds...)
        draw_object!(ex, vo, heat)
    end
end

function draw_cross!(model, ex)
    refresh!(ex)
    draw_focus!(model, ex)
    ex.visible ? sleep(.30/ex.speed) : nothing
    return nothing
end

function draw_object!(ex, vo, heat)
    !vo.visible ? (return) : nothing
    c = ex.canvas
    w = vo.width
    x,y = vo.location
    color = get_color(vo)
    letter = get_text(vo)
    @guarded draw(c) do widget
        ctx = getgc(c)
        circle(ctx, x, y, w/2)
        if vo.attended
            α = get(ColorSchemes.Greys_3, heat)
            set_source_rgba(ctx, α.r, α.g, α.b , .4)
        else
            α = get(ColorSchemes.coolwarm, heat)
            set_source_rgba(ctx, α.r, α.g, α.b , .4)
        end
        fill(ctx)
        select_font_face(ctx, "Arial", Cairo.FONT_SLANT_NORMAL,
             Cairo.FONT_WEIGHT_BOLD);
        set_font_size(ctx, pixels_to_points(vo.width))
        set_source(ctx, Cairo.alphacolor(color,.5))
        extents = text_extents(ctx, letter)
        x′ = x - (extents[3]/2 + extents[1])
        y′ = y - (extents[4]/2 + extents[2])
        move_to(ctx, x′, y′)
        show_text(ctx, letter)
    end
    Gtk.showall(c)
    return nothing
end

function draw_focus!(model, ex)
    c = ex.canvas
    w = model.iconic_memory[1].width
    x,y = model.focus
    @guarded draw(c) do widget
        ctx = getgc(c)
        circle(ctx, x, y, w/2)
        set_line_width(ctx, 4);
        set_source_rgba(ctx, 0, 0, 0, 1)
        Cairo.stroke(ctx)
    end
    Gtk.showall(c)
    return nothing
end

function draw_target!(model, ex)
    target = filter(x->x.target, model.iconic_memory)
    isempty(target) ? (return) : nothing
    c = ex.canvas
    w = target[1].width
    x,y = target[1].location
    @guarded draw(c) do widget
        ctx = getgc(c)
        set_line_width(ctx, 4)
        circle(ctx, x, y, w/2)
        set_source_rgba(ctx, 255, 255, 179, 1)
        Cairo.stroke(ctx)
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
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

pixels_to_points(pixels) = pixels*3/4

points_to_pixels(points) = points*4/3

get_text(vo) = string(vo.features.shape.value)

get_color(vo) = Colors.parse(Colorant, string(vo.features.color.value))

get_min_max(model::Model) = get_min_max(model.iconic_memory)

function get_min_max(iconic_memory)
    mn,mx = Inf,-Inf
    for vo in iconic_memory
        vo.activation < mn ? (mn=vo.activation; continue) : nothing
        vo.activation > mx ? (mx=vo.activation; continue) : nothing
    end
    return mn,mx
end

function compute_heat(vo, lb, ub)
    lb == ub ? (return 1.0) : nothing
    return (vo.activation-lb)/(ub-lb)
end
