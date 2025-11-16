// Transforms a path into a PathPlus with Catmull-Rom interpolation

pathplus = new PathPlus(Path3)
//pathplus.SetCatmullRom(0,0)

pathplus.SetPrecision(4)
//pathplus.SetBezier()
//pathplus.BakeToPath()
pathplus.GenerateCache()
/*
_guide = instance_create_layer(x,y,layer,guide)
with _guide
{
	follow = new PathPlusFollower(other.pathplus) 
	follow.SetActionOnEnd(PP_FOLLOW.BOUNCE).SetSpeed(1,10)
			}*/
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


sprite = new PathPlusSpriter(pathplus,sp_road,64) 

//sprite.AddThickness(0,0,0).AddThickness(.5,1,1).AddThickness(1,0,0).
//sprite.AddColor(0,c_aqua).AddColor(.05,c_red).AddColor(.45,c_white,1).AddColor(.95,c_teal,1).AddColor(1,c_aqua)
sprite.RegenCache()

frame = 0