var _selected_l =  array_length(points_selected),
	_add_to_sel	=	false

// if mouse is not in the process of dragging an element or Lassoing a selection, check for collisions
if mouse_mode!= MOUSE_MODE.DRAG &&  mouse_mode!= MOUSE_MODE.LASSO && mouse_mode!= MOUSE_MODE.ADD
{	
	var _check = false

	mouse_colliding	= MOUSE_COLL.NONE
	mouse_mode		= MOUSE_MODE.NORMAL
	
	if _selected_l >0
	{
		for(var _i=0;_i<_selected_l;_i++)
		{
			var _current_point = points_selectable[points_selected[_i]]
			_check = point_in_circle(mouse_x,mouse_y,_current_point[1][0],_current_point[1][1],10)	
			if _check
			{
				hovered_on =  _i
				break
			}
		}
		mouse_colliding = _check ?  MOUSE_COLL.POINT : MOUSE_COLL.NONE
	}
	if !_check
	{
		for(var _i=0;_i<array_length(points_selectable);_i++)
		{
			var _current_point = points_selectable[_i]
			_check = point_in_circle(mouse_x,mouse_y,_current_point[1][0],_current_point[1][1],8)	
			if _check 
			{
				_add_to_sel	=	true
				hovered_on = _i
				break
			}
			hovered_on = undefined
		}
		mouse_colliding = _check ?  MOUSE_COLL.POINT : MOUSE_COLL.NONE
	}
	if pathplus.type == PATHPLUS.BEZIER && !_check
	{
		for(var _i=0;_i<array_length(handles_selectable);_i++)
		{
			var _current_point = handles_selectable[_i]
			_check = point_in_circle(mouse_x,mouse_y,_current_point[1][0],_current_point[1][1],8)	
			if _check 
			{
				hovered_on =  handles_selectable[_i][0]
				mouse_colliding = MOUSE_COLL.HANDLE
				_add_to_sel = true
				break
			}
				hovered_on = undefined
		}
	}

	mouse_mode= _check ? MOUSE_MODE.HOVER : MOUSE_MODE.NORMAL
	
	 var _i = 0

}

if input_check_pressed("left_click")
{
	// If clicking when hovering over a slectable element, dragging an element or colliding witha  point
	if mouse_mode ==  MOUSE_MODE.HOVER && (mouse_colliding	== MOUSE_COLL.POINT  ||  mouse_colliding	== MOUSE_COLL.HANDLE)
	{
		if keyboard_check(vk_shift) && mouse_colliding	== MOUSE_COLL.POINT // If altering the current selection
		{
			if hovered_on != undefined 
			{
				if _add_to_sel
				{ 
					array_push(points_selected,hovered_on)
				}
				else 
				{
					array_delete(points_selected,hovered_on,1)
				}
				hovered_on = undefined
			}
		}
		else
		{
			if hovered_on != undefined && _add_to_sel
			{
				points_selected = [hovered_on]
				hovered_on = undefined
			}
			mouse_mode = MOUSE_MODE.DRAG
		}
	
	}
	else if mouse_mode== MOUSE_MODE.ADD
	{
		pathplus.AddPoint(mouse_x,mouse_y)
		RemakeSelectablePoints()
	}
}
if keyboard_check_pressed(vk_add)
{
	 mouse_mode= mouse_mode==MOUSE_MODE.ADD ? MOUSE_MODE.NORMAL: MOUSE_MODE.ADD
}

if input_check("left_click")
{
	if mouse_mode ==  MOUSE_MODE.DRAG && (mouse_colliding	== MOUSE_COLL.POINT  ||  mouse_colliding	== MOUSE_COLL.HANDLE)
	{
		var _dx = mouse_x-prev_mouse_x
		var _dy = mouse_y-prev_mouse_y
		
		if  mouse_colliding	== MOUSE_COLL.HANDLE
		{
			var _break = input_check("alt")
			var _sym = keyboard_check(vk_shift)
			var _handle = points_selected[0][1]
			pathplus.TranslateBezierHandle(points_selected[0][0],_dx,_dy,_handle,_break,_sym)
			RemakeSelectablePoints()
		}
		else
		{
			for(var _i=0;_i<array_length(points_selected);_i++)
			{
				 pathplus.TranslatePoint(points_selected[_i],_dx,_dy)
				 RemakeSelectablePoints()
			}
		}
	}
	else if  mouse_mode ==  MOUSE_MODE.NORMAL || mouse_mode ==  MOUSE_MODE.LASSO
	// Enter lasso mode
	{
		mouse_mode =  MOUSE_MODE.LASSO
		LassoSelection(mouse_x,mouse_y)	
	}
}

if input_check_released("left_click") 
{
	if mouse_mode ==  MOUSE_MODE.LASSO
	{
		points_selected = LassoEnd(points_selectable)
	}
	if mouse_colliding	== MOUSE_COLL.HANDLE 
	{
		points_selected = []
	}
	if mouse_mode	!= MOUSE_MODE.ADD
	{
		mouse_mode = MOUSE_MODE.NORMAL
	}
	
}

// DELETE SELECTED POINTS
if input_check_pressed("del")
{
	if array_length(points_selected)>0 
	{
		// sort the selected points array (which contains the array indexes) from higher to lower
		array_sort(points_selected, function(_a,_b){return _b-_a})
		
		for(var _i=0;_i<array_length(points_selected);_i++)
		{
			pathplus.RemovePoint(points_selected[_i],1)
		}
		//clear selection array
		points_selected = []
		//Regenerate the possible selectable points
		RemakeSelectablePoints()
	}		
}

// CHANGE CURSOR APPEARANCE
switch(mouse_mode){
	
case MOUSE_MODE.NORMAL :
	mouse_sprite = spr_pointer_a_ol
	break
case MOUSE_MODE.HOVER :
	if mouse_colliding == MOUSE_COLL.LINE {mouse_sprite = spr_hand_point_ol}
	else if mouse_colliding == MOUSE_COLL.POINT {mouse_sprite = spr_hand_open_ol}
	else if mouse_colliding == MOUSE_COLL.HANDLE {mouse_sprite = spr_hand_open_ol}
	break
case MOUSE_MODE.DRAG :
	mouse_sprite = spr_resize_a_cross_ol
	break
case MOUSE_MODE.ADD :
	mouse_sprite = spr_pointer_k_ol
	break
case MOUSE_MODE.LASSO :
	mouse_sprite = spr_pointer_j_ol
	LassoSelection(mouse_x,mouse_y)	
	break
}
prev_mouse_x = mouse_x
prev_mouse_y = mouse_y