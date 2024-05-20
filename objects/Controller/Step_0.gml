
if mouse_mode!= MOUSE_MODE.DRAG &&  mouse_mode!= MOUSE_MODE.LASSO
{	
	var _check = false;
	mouse_colliding	= MOUSE_COLL.NONE
	mouse_mode		= MOUSE_MODE.NORMAL
	
	if array_length(points_selected)>0
	{
		for(var _i=0;_i<array_length(points_selected);_i++)
		{
			var _current_point = points_selectable[points_selected[_i]]
			_check = point_in_circle(mouse_x,mouse_y,_current_point[1][0],_current_point[1][1],10)	
			if _check break
		}
	}
	else
	{
		for(var _i=0;_i<array_length(points_selectable);_i++)
		{
			var _current_point = points_selectable[_i]
			_check = point_in_circle(mouse_x,mouse_y,_current_point[1][0],_current_point[1][1],8)	
			if _check 
			{
				hovered_on = _i
				break
			}
			hovered_on = undefined
		}
	}
	mouse_mode= _check ? MOUSE_MODE.HOVER : MOUSE_MODE.NORMAL
	mouse_colliding = _check ?  MOUSE_COLL.POINT : MOUSE_COLL.NONE
	 var _i = 0,
	 curve_on = true
	while(_i<360)
	{
	
	var 
		_ac_0		= curve_on ? animcurve_channel_evaluate(curve,_i/360) : 1,
		_x			= x+ lengthdir_x((x_scale* radius*_ac_0) ,_i),
		_y			= y+ lengthdir_y((y_scale* radius*_ac_0) ,_i),
		_new_angle	= min (_i+wedge_angle,360) ,
		_ac_1		= curve_on ? animcurve_channel_evaluate(curve,_new_angle/360) : 1,
		_x2			= x+ lengthdir_x((x_scale * radius*_ac_1),_new_angle),
		_y2			= y+ lengthdir_y((y_scale * radius*_ac_1),_new_angle),
		_i = _new_angle
	
	if point_modification_mode 
	{
		var _check = collision_line(_x,_y,_x2,_y2,o_mouse_col,false,false)
		
		if mouse_colliding == MOUSE_COLL.NONE && _check != noone
		{
			mouse_colliding	= MOUSE_COLL.LINE
			mouse_mode		= MOUSE_MODE.HOVER
		}
	}
}

	
}

if input_check("left_click")
{
	if (mouse_mode ==  MOUSE_MODE.HOVER ||  mouse_mode ==  MOUSE_MODE.DRAG) && mouse_colliding	== MOUSE_COLL.POINT
	{
		mouse_mode = MOUSE_MODE.DRAG
		if array_length(points_selected)==0 && hovered_on != undefined
		{
			array_push(points_selected,hovered_on)
			hovered_on = undefined
		}		
		
		var _prev_distance = point_distance(prev_mouse_x, prev_mouse_y,emitter_center_x ,emitter_center_y),
		_current_distance = point_distance(mouse_x, mouse_y,emitter_center_x ,emitter_center_y),
		_delta = (_current_distance-_prev_distance)/radius
		for(var _i=0;_i<array_length(points_selected);_i++)
		{
			var _p = curve.points[points_selected[_i]]
			_p.value +=_delta
			
			var _angle = _p.posx * 360,
			_height = _p.value,
			_x = x+ lengthdir_x((x_scale* radius * _height),_angle),
			_y = y+ lengthdir_y((y_scale* radius * _height),_angle)
			
			points_selectable[points_selected[_i]][1][0] = _x
			points_selectable[points_selected[_i]][1][1] = _y
		}
	}
	else 
	{
		mouse_mode =  MOUSE_MODE.LASSO
		LassoSelection(lasso,mouse_x,mouse_y)	
	}
}

if input_check_released("left_click") && point_modification_mode
{
	if mouse_mode ==  MOUSE_MODE.LASSO
	{
		points_selected = LassoEnd(lasso,points_selectable)
	}
	mouse_mode = MOUSE_MODE.NORMAL	
}

if input_check_pressed("del")
{
	if array_length(points_selected)>0 
	{
		var _pos_array = []
		for(var _i=0;_i<array_length(points_selected);_i++)
		{
			var _p = curve.points[points_selected[_i]]
			
			if _p.posx ==0 || _p.posx ==1 continue
			
			array_push(_pos_array,_p.posx)
		}
		for(var _i=0;_i<array_length(_pos_array);_i++)
		{
			var _points = curve.points
			animcurve_point_remove(_points,_pos_array[_i])
			curve.points = _points
		}
		points_selected = []
		RemakeSelectablePoints()
	}		
}

if input_check_pressed("right_click")
{
	if mouse_mode ==  MOUSE_MODE.HOVER  && mouse_colliding	== MOUSE_COLL.LINE
	{
		var _dir = point_direction(x,y,mouse_x,mouse_y)/360,
		_value = animcurve_channel_evaluate(curve,_dir),
		_points = curve.points
		animcurve_point_add(_points,_dir,_value,false)
		curve.points = _points
		RemakeSelectablePoints()
	}
}

if input_check_pressed("point_mode")
{
	point_modification_mode = !point_modification_mode

	if !point_modification_mode
	{
		points_selectable = []
		exit	
	}

	for(var _i2=0 ;_i2<array_length(curve.points) ;  _i2++)
	{
		var _angle = curve.points[_i2].posx * 360,
			_height = curve.points[_i2].value,
			_x = x+ lengthdir_x((x_scale* radius * _height),_angle),
			_y = y+ lengthdir_y((y_scale* radius * _height),_angle)
	
		array_push(points_selectable,[_i2,[_x,_y]])
	}	
	
}

switch(mouse_mode){
	
case MOUSE_MODE.NORMAL :
	mouse_sprite = spr_pointer_a_ol
	break
case MOUSE_MODE.HOVER :
	if mouse_colliding == MOUSE_COLL.LINE {mouse_sprite = spr_hand_point_ol}
	else if mouse_colliding == MOUSE_COLL.POINT {mouse_sprite = spr_hand_open_ol}
	break
case MOUSE_MODE.DRAG :
	mouse_sprite = spr_resize_a_vertical_ol
	break
}
prev_mouse_x = mouse_x
prev_mouse_y = mouse_y