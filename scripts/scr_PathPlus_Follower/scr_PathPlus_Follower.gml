/// Feather ignore all
#macro PP_FOLLOWER_VERSION "1.1"
__pathplus_show_debug($"▉✦✧✦ Using PathPlus Follower v {PP_FOLLOWER_VERSION} - by Delfos ✦✧✦▉")
enum PP_FOLLOW { FORWARD=1, BACKWARD=-1, BOUNCE ,STOP,CYCLE,CONTINUE }

function PathPlusFollower(pathplus,_xoffset = 0,_yoffset = 0) constructor
{
	if !is_instanceof(pathplus,PathPlus) 
	{
		__pathplus_show_debug("▉╳▉ ✦PathPlus✦ Error ▉╳▉: PathPlusFollower requires a PathPlus attached to it.")
	} 
	else
	{
		path = pathplus
	}
	
	x					= _xoffset
	y					= _yoffset 
	x_start				= _xoffset
	y_start				= _yoffset 
	direction			= PP_FOLLOW.FORWARD
	on_end				= PP_FOLLOW.STOP
	location_on_path	= 0
	curr_speed			= path.polyline[0].speed /100
	speed				= 10
	min_speed			= 1
	normal				= path.polyline[0].normal
	transversal			= path.polyline[0].transversal
	
	/// Sets the speed for the follower.
	/// @arg {Real} _min :  The minimum speed of the follower when the path speed equals 0.
	/// @arg {Real} _max :  The maximum speed of the follower when the path speed equals 100.
	static SetSpeed = function(_min,_max)
	{
		speed				= _max
		min_speed				= _min
		return self
	}
	/// Sets the position of the follower along the path.
	/// @arg {Real} _n :  The position on the path, from 0 to 
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
	
	static SetOffsetPosition = function( _xoffset=x_start, _yoffset=y_start)
	{
		x_start				= _xoffset ;
		y_start				= _yoffset ;
		GetCurrentPosition();
	}
	/// Sets the direction of the follower along the path.
	/// @arg {Real} _dir :  The direction to follow, can be either PP_FOLLOW.FORWARD (1) or PP_FOLLOW.BACKWARD (-1).
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
		/// Sets the action to take when the follower reaches either end of the path. 
	/// @arg {Real} _action :  The action to perform at either end of the path. Can be one of the following: BOUNCE, STOP, CYCLE, CONTINUE
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
	/// Updates the position at the current point in path without moving the follower. Changes the variables x, y , normal and transversal, and returns the point struct from the path, where user variables might be stored.
	/// @return {Struct}
	static GetCurrentPosition = function() 
	{
		var _point = _cache ? path.SampleFromCache(location_on_path) : path.Sample(location_on_path)
		curr_speed = _point.speed / 100
		x = x_start + _point.x
		y = y_start + _point.y
		normal = _point.normal
		transversal = direction == PP_FOLLOW.FORWARD ? _point.transversal : (_point.transversal+180)%360
		
		return _point	
	}
	///Advances the follower one "step". A step is determined by the speed at the current path point. Changes the variables x, y , normal and transversal, and returns the point struct from the path, where user variables might be stored.
	/// @arg {Real} _step_length : A full step (1) will move the follower to 100% the speed at the current path point. DEFAULT: 1
	///@arg {[Bool]} _cache : Whether to generate the cache when the function is called or not. DEFAULT: True
	static StepForward = function(_step_length = 1, _cache = true){
	
		if _cache && !path._cache_gen && PP_AUTO_GEN_CACHE
		{
			path.GenerateCache()
		}
	
		var _spd = lerp(min_speed,speed,curr_speed)
		_step_length = (  _spd / path.pixel_length) * (_step_length*direction)
	
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
	/// Regresses the follower one "step". A step is determined by the speed at the current path point. It keeps the follower's current direction and orientation. Changes the variables x, y , normal and transversal, and returns the point struct from the path, where user variables might be stored.
	/// @arg {Real} _step_length : A full step (1) will move the follower to 100% the speed at the current path point. DEFAULT: 1
	///@arg {[Bool]} _cache : Whether to generate the cache when the function is called or not. DEFAULT: True
	static StepBackward = function(_step_length = 1, _cache = true){
	
		_step_length *= -1
		
		return StepForward(_step_length, _cache )
	}
	/// Generates an animation curve based on the current Follower settings. The curve contains the channels "x","y","normal" and "transversal"
	///@arg {String} _curve_name : The name of the new curve, as a string.
	///@arg {[Bool]} _cache : Whether to generate the cache when the function is called or not. DEFAULT: True
	static GenerateACurve = function(_curve_name ,_cache = true)
	{
		var _step_length , 
		_location = direction == PP_FOLLOW.FORWARD ? 0 : 1 ,
		_curr_speed = direction == PP_FOLLOW.FORWARD? path.polyline[0].speed /100 : path.polyline[path.l-1].speed
		
		if _cache && !path._cache_gen && PP_AUTO_GEN_CACHE
		{
			path.GenerateCache()
		}
	
		var content = {
			curve_name : string(_curve_name) , 
			channels : [{name:"x" , type : animcurvetype_linear , iterations : 8},
						{name:"y" , type : animcurvetype_linear , iterations : 8},
						{name:"normal" , type : animcurvetype_linear , iterations : 8},
						{name:"transversal" , type : animcurvetype_linear , iterations : 8}]
		}
	
		var _animcurve = animcurve_really_create(content),
			_points_x_array = [],
			_points_y_array = [],
			_points_normal_array = [],
			_points_transversal_array = []
			
		
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
			animcurve_point_add(_points_x_array,_location,x)
			animcurve_point_add(_points_y_array,_location,y)
			animcurve_point_add(_points_normal_array,_location,normal)
			animcurve_point_add(_points_transversal_array,_location,transversal)
		}
		
		animcurve_points_set(_animcurve,"x",_points_x_array)
		animcurve_points_set(_animcurve,"y",_points_y_array)
		animcurve_points_set(_animcurve,"normal",_points_normal_array)
		animcurve_points_set(_animcurve,"transversal",_points_transversal_array)
		
		return _animcurve
	}
	
}

