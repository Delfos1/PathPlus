// Transforms a path into a PathPlus with Catmull-Rom interpolation

pathplus = new PathPlus(Path2)
//pathplus.SetCatmullRom(.5,0.5)


pathplus.SetBezier()

//pathplus.BakeToPath()


gpu_set_texfilter(true)
gpu_set_tex_mip_filter(tf_anisotropic)

prev_mouse_x			= mouse_x
prev_mouse_y			= mouse_y

enum MOUSE_MODE {NORMAL, LASSO, HOVER, DRAG, ADD, INSERT}
enum MOUSE_COLL {NONE, POINT, LINE, HANDLE}
mouse_mode				= MOUSE_MODE.NORMAL
points_selected			= []
points_selectable		= []
handle_selected			= undefined
handles_selectable		= []
point_modification_mode = false
hovered_on				= undefined

mouse_colliding			= MOUSE_COLL.NONE

window_set_cursor(cr_none)
mouse_sprite = spr_pointer_a_ol



function RemakeSelectablePoints()
{
	points_selectable = []
	var _target = pathplus.polyline
	for(var _i2=0 ;_i2<array_length(_target) ;  _i2++)
	{
		var _x = _target[_i2].x,
			_y = _target[_i2].y
	
		array_push(points_selectable,[_i2,[_x,_y]])
	}
	if pathplus.type == PATHPLUS.BEZIER
	{
		handles_selectable		= []
		for(var _i2=0 ;_i2<array_length(_target) ;  _i2++)
		{
			if _target[_i2][$"h1"] != undefined
			{
				_x = _target[_i2].h1.x
				_y = _target[_i2].h1.y
				array_push(handles_selectable,[[_i2,true],[_x,_y]])
			}
			if _target[_i2][$"h2"] != undefined
			{
				_x = _target[_i2].h2.x
				_y = _target[_i2].h2.y
				array_push(handles_selectable,[[_i2,false],[_x,_y]])
			}

		}
	}
	
}

LassoSelection(x,y)
LassoEnd(0)

RemakeSelectablePoints()