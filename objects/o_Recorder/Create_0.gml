image_xscale = .5
image_yscale = .5

stage = 0

draw=false
trigger = false
pathplus = undefined
_guide = undefined
PathRecord(mouse_x,mouse_y)
var _nothing = PathRecordStop()

////////////////

gpu_set_texfilter(true)
gpu_set_tex_mip_filter(tf_anisotropic)

prev_mouse_x			= mouse_x
prev_mouse_y			= mouse_y


mouse_mode				= MOUSE_MODE.NORMAL
points_selected			= []
points_selectable		= []
handle_selected			= undefined
handles_selectable		= []
point_modification_mode = false
hovered_on				= undefined
closest					= undefined
mouse_colliding			= MOUSE_COLL.NONE

window_set_cursor(cr_none)
mouse_sprite = spr_pointer_a_ol

LassoSelection(x,y)
LassoEnd(0)



