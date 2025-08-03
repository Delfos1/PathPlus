
//pathplus.DebugDraw(0,0,true)
LassoDraw()

sprite.Draw(floor(frame))
sprite.DebugDraw()

for(var _i2=0 ;_i2<array_length(points_selectable) ;  _i2++)
	{
		var _color = PP_COLOR_PT
		var _radius =2,
			_p = points_selectable[_i2]
	
		for(var _i3=0 ;_i3<array_length(points_selected) ;  _i3++)
		{
			if points_selected[_i3]== points_selectable[_i2][0]
			{
				_radius = 4
				_color	= PP_COLOR_PT_SEL
				break
			}
		}
	
		draw_circle_color(_p[1][0],_p[1][1],_radius,_color,_color,false)
	}

if closest != undefined
{
	draw_line(mouse_x,mouse_y,closest.x,closest.y)
}

draw_sprite(mouse_sprite,0,mouse_x,mouse_y)

