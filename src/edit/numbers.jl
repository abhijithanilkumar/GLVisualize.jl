
drag_x(drag_id) = drag_id[1][1]

printforslider(io::IOBuffer, x::AbstractFloat, numberwidth::Int=5) = print(io, @sprintf("%0.5f", x)[1:numberwidth])
printforslider(io::IOBuffer, x::Integer, numberwidth::Int=5) = print(io, @sprintf("%5d", x)[1:numberwidth])
printforslider(x::Integer, numberwidth::Int=5) = @sprintf("%5d", x)[1:numberwidth]
printforslider(x::AbstractFloat, numberwidth::Int=5) = @sprintf("%0.5f", x)[1:numberwidth]
function printforslider(x::FixedVector, numberwidth=5)
    io = IOBuffer()
    for elem in x
        printforslider(io, elem, numberwidth)
        print(io, " ")
    end
    takebuf_string(io)
end
function num2glstring(x, numberwidth)
    str   = printforslider(x, numberwidth)
    atlas = get_texture_atlas()
    font  = DEFAULT_FONT_FACE
    Vec4f0[glyph_uv_width!(atlas, c, font) for c=str]
end

FixedSizeArrays.unit{T <: Real}(::Type{T}, _) = one(T)


function add_mouse_drags(t0, mouse_down1, mouseposition1, objectid, id_tolookfor, glyph_width)
    accum, mouse_down0, draggstart, idstart, v0, index0 = t0
    VT = typeof(v0)
    if (!mouse_down0 && mouse_down1) && (objectid[1] == id_tolookfor) #drag starts
        return (accum, mouse_down1, mouseposition1, id_tolookfor, accum, objectid[2]) # reset values
    elseif (mouse_down0 && mouse_down1) && (idstart == id_tolookfor)
        diff = eltype(VT)(Vec2f0(mouseposition1-draggstart)[1])
        # lets act as if the text glyph array is 2d, with numberwidth as width, and height is the amount of numbers
        zero_indexed        = index0-1 #linear index from glyph array
        number_glyph_group  = div(zero_indexed, glyph_width) #
        i = number_glyph_group+1#to 1 based index
        return (v0 + (unit(VT, i)*diff), mouse_down1, draggstart, id_tolookfor, v0, index0)
    end
    (accum, mouse_down1, Vec2f0(0), 0, accum, 0)
end

Base.clamp(x, r::Range) = clamp(x, first(r), last(r))

function slide(startvalue, slide_pos, range::Range)
    val = startvalue + (slide_pos*step(range))
    clamp(val, range)
end

vizzedit{T <: Union{FixedVector, Real}}(x::T, inputs, numberwidth=5) = vizzedit(typemin(T):eps(T):typemax(T), inputs, numberwidth; start_value=x)

function range_default{T<:AbstractFloat}(::Type{T})
    T(-10):T(0.01):T(10)
end
function range_default{T<:Integer}(::Type{T})
    T(-100):T(1):T(100)
end

function calc_val{T<:AbstractFloat}(sval::T, val, range)
    clamp(sval+(val*step(range)), first(range), last(range))
end
function calc_val{T<:Integer}(sval::T, val, range)
    clamp(sval+(round(T, val)*step(range)), first(range), last(range))
end
function vizzedit{T <: Union{FixedVector, Real}}(slider_value::Signal{T}, window; numberwidth=5, range=range_default(T))
    @materialize mouse_buttons_pressed, mouseposition = window.inputs
    startvalue        = value(slider_value)
    slider_value_str  = map(printforslider, slider_value)
    vizz              = visualize(slider_value_str)
    slider_robj       = vizz.children[]
    # current tuple of renderobject id and index into the gpu array
    m2id = GLWindow.mouse2id(window)
    hovers_slider = const_lift(is_same_id, m2id, slider_robj)
    # inputs are a dict, materialize gets the keys out of it (equivalent to mouseposition = w.inputs[:mouseposition])
    # single left mousekey pressed (while no other mouse key is pressed)
    key_pressed = const_lift(GLAbstraction.singlepressed, mouse_buttons_pressed, GLFW.MOUSE_BUTTON_LEFT)
    # dragg while key_pressed. Drag only starts if hovers_slider is true
    mousedragg  = GLAbstraction.dragged(mouseposition, key_pressed, hovers_slider)
    preserve(foldp(startvalue, droprepeats(mousedragg)) do v0, dragg
        if dragg == Vec2f0(0) # just started draggin'
            return value(slider_value)
        end
        push!(slider_value, calc_val(v0, dragg[1], range))
        v0
    end)
    return slider_value, vizz
end
