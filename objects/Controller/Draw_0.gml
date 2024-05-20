

LassoDraw(lasso)

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
var curve_on = true


var _i = space_angle

while(_i<360)
{
	
	var 
		_ac_0		= curve_on ? animcurve_channel_evaluate(curve,_i/360) : 1,
		_x			= x+ lengthdir_x((x_scale* radius*_ac_0) ,_i),
		_y			= y+ lengthdir_y((y_scale* radius*_ac_0) ,_i),
		_new_angle	= min (_i+wedge_angle,360) ,
		_xscale		= 1,
		_ac_1		= curve_on ? animcurve_channel_evaluate(curve,_new_angle/360) : 1,
		_x2			= x+ lengthdir_x((x_scale * radius*_ac_1),_new_angle),
		_y2			= y+ lengthdir_y((y_scale * radius*_ac_1),_new_angle),
		_rot		= point_direction(_x,_y,_x2,_y2),
		_xscale		= (point_distance(_x,_y,_x2,_y2) / line_total)
	
		//if _i+wedge_angle >= 360 break
	
	if(_xscale < 0.80 || _xscale > 1.75)
	{/*
		_new_angle	= abs(calculateChordAngle(_x,_y,line_total,x,y,x_scale * radius*2,y_scale * radius*2))
		_xscale		= 1

		var 
			_ac_1		= curve_on ? animcurve_channel_evaluate(curve,_new_angle/360) : 1,
			_x2			= x+ lengthdir_x((x_scale * radius*_ac_1),_new_angle),
			_y2			= y+ lengthdir_y((y_scale * radius*_ac_1),_new_angle),
			_rot		= point_direction(_x,_y,_x2,_y2),
			_xscale		=1/// (point_distance(_x,_y,_x2,_y2) / line_total)*/
	}
	_i = _new_angle
	
	if point_modification_mode 
	{
		var _check = collision_line(_x,_y,_x2,_y2,o_mouse_col,false,false)
		
		if mouse_colliding == MOUSE_COLL.LINE && _check == noone
		{
			mouse_colliding	= MOUSE_COLL.NONE
			mouse_mode		= MOUSE_MODE.NORMAL
		}
		if mouse_colliding == MOUSE_COLL.NONE && _check != noone
		{
			mouse_colliding	= MOUSE_COLL.LINE
			mouse_mode		= MOUSE_MODE.HOVER
		}
	}
	
	draw_sprite_ext(dotted_line,0,_x,_y,_xscale*(line_width/3),1,_rot,$FF593C ,1)
}

if point_modification_mode 
{
	for(var _i2=0 ;_i2<array_length(points_selectable) ;  _i2++)
	{
		var _color = c_lime
		var _radius = clamp(max(y_scale* radius,x_scale* radius)/100*10,3,5),
				_p = points_selectable[_i2]
	
		for(var _i3=0 ;_i3<array_length(points_selected) ;  _i3++)
		{
			if points_selected[_i3]== points_selectable[_i2][0]
			{
				_color = c_yellow
				break
			}
		}
	
		draw_circle_color(_p[1][0],_p[1][1],_radius,_color,_color,false)
	}
}
draw_sprite(mouse_sprite,0,mouse_x,mouse_y)

