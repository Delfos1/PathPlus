
PathRecordDraw()
if pathplus != undefined 
{
	pathplus.DebugDraw(0,0,true,false,false)
}

if stage != 3
{
	draw_self()
	draw_set_halign(fa_center)
	draw_text(700,200,"Hold click on the moon and move it around to record the motion")

}
if stage == 3
{
	draw_text(700,200,"Click on the points and move them around to change the path.")
	draw_text(700,250,"Double-Click on the line to insert points")
	draw_text(700,300,"Press Delete Key to remove points. Press + Key and Double Click anywhere to add a new point")
	
	pathplus.DebugDraw(0,0,true)

	LassoDraw()

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
}

draw_sprite(mouse_sprite,0,mouse_x,mouse_y)

