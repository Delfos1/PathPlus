system = pulse_make_system("system")
emitter = new pulse_local_emitter("system")

x_scale = 1
y_scale = 1
radius = 100

window_set_fullscreen(true)
display_reset(8, true);
gpu_set_texfilter(true)
gpu_set_tex_mip_filter(tf_anisotropic)

curve = animcurve_get_channel(ac_1,"curve1")

prev_mouse_x			= mouse_x
prev_mouse_y			= mouse_y

lasso					= []

enum MOUSE_MODE {NORMAL, LASSO, HOVER, DRAG}
enum MOUSE_COLL {NONE, POINT, LINE}
mouse_mode				= MOUSE_MODE.NORMAL
points_selected			= []
points_selectable		= []
point_modification_mode = false
hovered_on				= undefined

emitter_center_x		= x
emitter_center_y		= y
mouse_colliding			= MOUSE_COLL.NONE

window_set_cursor(cr_none)
mouse_sprite = spr_pointer_a_ol

//Draw properrties

line_width = 8
line_space = floor (line_width*.75)
line_total = line_width +  line_space
var _perimeter =  2*pi * (sqrt((sqr(radius*x_scale)+sqr(radius*y_scale))/2))
var shrink = floor(_perimeter / line_total) < 24 ? true : false

while shrink{

	line_width --
	line_space = floor (line_width*.75)
	line_total = line_width +  line_space
	shrink = floor(_perimeter / line_total) < 24 ? true : false

}

wedge_angle = 360 / max(floor(_perimeter / line_total),24)
space_angle = 360 / floor(_perimeter / line_space)
line_angle = 360 / floor(_perimeter / line_width)


function RemakeSelectablePoints()
{
	points_selectable = []
	for(var _i2=0 ;_i2<array_length(curve.points) ;  _i2++)
	{
		var _angle = curve.points[_i2].posx * 360,
			_height = curve.points[_i2].value,
			_x = x+ lengthdir_x((x_scale* radius * _height),_angle),
			_y = y+ lengthdir_y((y_scale* radius * _height),_angle)
	
		array_push(points_selectable,[_i2,[_x,_y]])
	}
}