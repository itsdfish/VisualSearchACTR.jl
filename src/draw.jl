function draw_object!(ex, vo)
    c = ex.canvas
    win = ex.window
    w = vo.width
    pos = vo.location
    letter = get_text(vo)
    @guarded draw(c) do widget
        ctx = getgc(c)
        select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL,
             Cairo.FONT_WEIGHT_NORMAL);
        set_font_size(ctx, pixels_to_points(vo.width))
        set_source_rgb(ctx, vo.rbg)
        extents = text_extents(cr, letter)
        x = 128.0-(extents[3]/2 + extents[1])
        y = 128.0-(extents[4]/2 + extents[2])
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

function draw_possession!(game)
    len = game.cell_size
    pos = game.possessor.position
    c = game.canvas
    win = game.window
    offset = len*.3
    @guarded draw(c) do widget
        ctx = getgc(c)
        rectangle(ctx, (pos[1]-1)*len+offset, (pos[2]-1)*len+offset,
            len-2*offset, len-2*offset)
        set_source_rgb(ctx, .9, .9, .9)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

function draw_tracked!(game, players)
    tracked = filter(x->x.track, players)
    isempty(tracked) && return
    for player in tracked
        len = game.cell_size
        pos = player.position
        c = game.canvas
        win = game.window
        offset = len*.3
        @guarded draw(c) do widget
            ctx = getgc(c)
            rectangle(ctx, (pos[1]-1)*len+offset, (pos[2]-1)*len+offset,
                len-2*offset, len-2*offset)
            set_source_rgb(ctx, 1, .08, .58)
            fill(ctx)
        end
        Gtk.showall(c)
    end
    return nothing
end

function remove_position!(game, player)
    len = game.cell_size
    pos = player.position
    c = game.canvas
    @guarded draw(c) do widget
        ctx = getgc(c)
        rectangle(ctx, (pos[1]-1)*len, (pos[2]-1)*len, len, len)
        set_source_rgb(ctx, .65, .65, .65)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

pixels_to_points(pixels) = pixels*3/4

points_to_pixels(points) = points*4/3

get_text(vo) = string(vo.features.shape.value)
