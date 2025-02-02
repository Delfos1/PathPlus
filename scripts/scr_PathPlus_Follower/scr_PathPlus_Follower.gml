enum PP_FOLLOW { FORWARD=1, BACKWARD=-1, BOUNCE ,STOP,CYCLE,CONTINUE }

function PathPlusFollower(pathplus,_relative = false) constructor
{
	if !is_instanceof(pathplus,PathPlus) 
	{
		__pathplus_show_debug("▉╳▉ ✦PathPlus✦ Error ▉╳▉: PathPlusFollower requires a PathPlus attached to it.")
	} 
	else
	{
		path = pathplus
	}
	
	x					= 0 
	y					= 0
	x_start				= !_relative ? 0 : other.x
	y_start				= !_relative ? 0 : other.y
	direction			= PP_FOLLOW.FORWARD
	on_end				= PP_FOLLOW.STOP
	location_on_path	= 0
	curr_speed			= path.polyline[0].speed /100
	speed				= 1
	normal				= path.polyline[0].normal
	transversal			= path.polyline[0].transversal
	
	static SetSpeed = function(_speed)
	{
		speed				= _speed
		
		return self
	}
	
	static SetPosition = function(_n)
	{
		location_on_path = clamp(_n,0,1)
		
		var _point = path.Sample(location_on_path)
		
		curr_speed = _point.speed / 100
		x = x_start + _point.x
		y = y_start + _point.y
		normal = _point.normal
		transversal = _point.transversal
	}
	
	static SetDirection = function(_dir = PP_FOLLOW.FORWARD)
	{
		if _dir != PP_FOLLOW.FORWARD && _dir != PP_FOLLOW.BACKWARD
		{
			__pathplus_show_debug("▉╳▉ ✦PathPlus✦ Error ▉╳▉: Wrong type provided")

			return self
		}
		direction = _dir
		
		return self
	}
	
	static SetActionOnEnd = function(_action = PP_FOLLOW.BOUNCE)
	{
		if _action != PP_FOLLOW.BOUNCE && _action != PP_FOLLOW.STOP && _action != PP_FOLLOW.CONTINUE && _action != PP_FOLLOW.CYCLE 
		{
			__pathplus_show_debug("▉╳▉ ✦PathPlus✦ Error ▉╳▉: Wrong type provided")

			return self
		}
		on_end = _action
		
		return self
	}
	
	static StepForward = function(_step_length = 1, _cache = true){
	
		if _cache && !path._cache_gen && PP_AUTO_GEN_CACHE
		{
			path.GenerateCache()
		}
	
		_step_length = ( (speed*curr_speed )/ path.pixel_length) * (_step_length*direction)
	
		location_on_path += _step_length

		if ( location_on_path > 1 && direction == PP_FOLLOW.FORWARD) || (location_on_path < 0  && direction == PP_FOLLOW.BACKWARD)
		{
			switch(on_end)
			{
				case PP_FOLLOW.BOUNCE:
					location_on_path = clamp(location_on_path,0,1)
					direction *= -1
					break
				case PP_FOLLOW.STOP:
					{
						location_on_path = clamp(location_on_path,0,1)
						return
					}
				case PP_FOLLOW.CONTINUE:
				
					if !path.closed
					{
						x_start = x 
						y_start = y 
					}
				case PP_FOLLOW.CYCLE:
					location_on_path = direction == PP_FOLLOW.FORWARD ? 0 : 1
					break

			}
		}


		var _point = _cache ? path.SampleFromCache(location_on_path) : path.Sample(location_on_path)
		curr_speed = _point.speed / 100
		x = x_start + _point.x
		y = y_start + _point.y
		normal = _point.normal
		transversal = direction == PP_FOLLOW.FORWARD ? _point.transversal : (_point.transversal+180)%360
		
		return _point
	
	}
	
	static StepBackward = function(_step_length = 1, _cache = true){
	
		_step_length *= -1
		
		return StepForward(_step_length, _cache )
	}
	
	static GenerateACurve = function(_cache = true)
	{
		var _step_length , 
		_location = direction == PP_FOLLOW.FORWARD ? 0 : 1 ,
		_curr_speed = direction == PP_FOLLOW.FORWARD? path.polyline[0].speed /100 : path.polyline[path.l-1].speed
		
		if _cache && !path._cache_gen && PP_AUTO_GEN_CACHE
		{
			path.GenerateCache()
		}
	
		while (_location > 1 && direction == PP_FOLLOW.FORWARD) || (_location < 0  && direction == PP_FOLLOW.BACKWARD)
		{
			_step_length = ( (speed*_curr_speed )/ path.pixel_length) * direction
	
			_location += _step_length
		
			var _point = _cache ? path.SampleFromCache(_location) : path.Sample(_location)
			_curr_speed = _point.speed / 100
			x = x_start + _point.x
			y = y_start + _point.y
			normal = _point.normal
			transversal = direction == PP_FOLLOW.FORWARD ? _point.transversal : (_point.transversal+180)%360
			
			// Add points
		}
	}
	
}