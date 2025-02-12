// Transforms a path into a PathPlus with Catmull-Rom interpolation

pathplus = new PathPlus(Path2)
pathplus.SetCatmullRom(0,0)


//pathplus.SetBezier()
//pathplus.BakeToPath()

_guide = instance_create_layer(x,y,layer,guide)
with _guide
{
	follow = new PathPlusFollower(other.pathplus) 
	follow.SetActionOnEnd(PP_FOLLOW.BOUNCE).SetSpeed(1,10)
			}
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

RemakeSelectablePoints()

