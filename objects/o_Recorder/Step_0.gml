if draw
{
	x=mouse_x
	y=mouse_y
	PathRecord(mouse_x,mouse_y)
	if _guide != undefined
	{
		with _guide
		{
			path_end()	
		}
		instance_destroy(_guide)
		_guide = undefined
	}
}
else
{
	path_plus = PathRecordStop()
	if path_plus != undefined
	{
		if _guide == undefined
		{
			_guide = instance_create_layer(x,y,layer,guide)
			with _guide
			{
				path_start(other.path_plus.path,other.path_plus.path_speed, path_action_reverse,true)}
			}
	}
}