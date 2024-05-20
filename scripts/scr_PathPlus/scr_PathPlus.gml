enum PATHPLUS {LINEAR, BEZIER,B_SPLINE ,CATMULL_ROM, GM_SMOOTH  }

function PathPlus(_path = []) constructor
{
	if is_handle(_path)
	{
		path		=	path_add()
		path_assign(path,_path)
		PathToPoly(false,true);
		l			=	path_get_number(path);
		precision	=	sqr(path_get_precision(path));
		closed		=	path_get_closed(path);
		type		=	path_get_kind(path) == true ? PATHPLUS.GM_SMOOTH : PATHPLUS.LINEAR	;
		pixel_length = path_get_length(path)
	}
	else if is_array(_path)
	{
		path		=	path_add()
		polyline	=	_path
		l			=	array_length(polyline)
		precision	=	8*8;
		closed		=	true;
		type		=	PATHPLUS.LINEAR	;
	}
	else
	{
		show_message("PATH PLUS ERROR: Provided wrong type of resource for PathPlus creation. Must be a path or an array of coordinates")
	}
	cache		=	[]
	_cache_gen  =	false
	_mismatch	=	false
	_properties = {}
	
	#region Polyline Basics
	/// Adds point to the Polyline
	static AddPoint		= function(_x,_y,_optional_vars = {}) 
	{
		l++
		
		_optional_vars.x		= _x
		_optional_vars.y		= _y

		array_push(polyline,_optional_vars)
		
		var n = l-1
		
		polyline[n].cached = false

		if n != 0 
		{
			polyline[n-1].cached = false

			if closed
			{
				polyline[0].cached = false
			}
		}
		
		_cache_gen  =	false
		
		return self
	}
	/// Inserts a point to the polyline at the n position
	static InsertPoint	= function(n,_x,_y,_optional_vars = {}) 
	{
		if polyline[n].x== _x && polyline[n].y== _y return
		if n == 0 && closed && (polyline[l-1].x== _x && polyline[l-1].y== _y)  {return}
		if n == l-1 && ((polyline[n].x== _x && polyline[n].y== _y) || (closed && (polyline[0].x== _x && polyline[0].y== _y)) ) {return}
		if polyline[n-1].x== _x && polyline[n-1].y== _y return
		
		n = clamp(n,0,l)
		_optional_vars.x		= _x
		_optional_vars.y		= _y

		l++
		array_insert(polyline,n,_optional_vars)
		var _i = n*precision
		repeat(precision)
		{
			array_insert(cache,_i,0)
			_i++
		}
		_cache_gen  =	false
		
		switch(type){
			
			case PATHPLUS.CATMULL_ROM:
			
			__catmull_rom_set(_properties.alpha, _properties.tension,min(n-2,0),max(n+2,l))
			
			break
			case PATHPLUS.BEZIER:
			
			__bezier_set_single(n)
			
			break
		}
		__generate_cache()

		
		
		return self
	}
	/// Removes the point on the polyline at the n position
	static RemovePoints	= function(n,_amount = 1) 
	{
		l--
		array_delete(polyline,n,_amount)
		_cache_gen  =	false
		
		return self
	}
	/// Changes the point on the polyline at the n position
	static ChangePoint	= function(n,_x,_y,_optional_vars = {}) 
	{
		polyline[n].x		= _x
		polyline[n].y		= _y
		polyline[n].cached	= false
		
		if closed
		{
			var _prev = n==0 ? l-1 : n-1
			var _next = n==l-1 ? 0 : n+1
		}
		else
		{
			var _prev = max(0,n-1)
			var _next = min(l-1,n+1)
		}
			polyline[_prev].cached		= false
			polyline[_next].cached		= false
		_cache_gen  =	false
		__generate_cache()
		return self
	}
	/// Changes a single variable within a point
	static ChangePointVariable	= function(n,_var_as_string,_new_value) 
	{
		if !struct_exists(polyline[n],_var_as_string) return
		polyline[n][$ _var_as_string] = _new_value
		polyline[n].cached	= false
		_cache_gen  =	false
		
		return self
	}
	//noise
	//simplify
	//closest point on path
	#endregion
	#region Path Basics
	
	static PathAddPoint		= function(x,y,speed=100)
	{
		path_add_point(path,x,y,speed)
		_mismatch	= true
		return self
	}
	static PathChangePoint	= function(n,x,y,speed=100)
	{
		path_change_point(path,n,x,y,speed)
		_mismatch	= true
		return self
	}
	static PathInsertPoint	= function(n,x,y,speed=100)
	{
		path_insert_point(path,n,x,y,speed)
		_mismatch	= true
		return self
	}
	static PathDeletePoint	= function(n)
	{
		path_delete_point(path,n)
		_mismatch	= true
		return self
	}
	static PathFlip			= function(h_or_v = false)
	{
		if !h_or_v
		{
			path_flip(path)
		}
		else
		{
			path_mirror(path)
		}
		return self
	}
	static PathScale		= function(xscale,yscale)
	{
		path_rescale(path,xscale,yscale)
		return self
	}
	static PathRotate		= function(angle)
	{
		path_rotate(path,angle)
		return self
	}
	static PathTranslate	= function(x,y)
	{
		path_shift(path,x,y)
		return self
	}
	static PathReverse		= function()
	{
		path_reverse(path)
		_mismatch	= true
		return self
	}
	static PathSet			= function(_path)
	{
		if !is_handle(_path) return
		path_assign(path,_path)
		Reset()
		return self
	}
	static PathAppend		= function(_path)
	{
		if !is_handle(_path) return
		path_append(path,_path)
		_mismatch	= true
		return self
	}
	
	#endregion
	#region Bezier Handles
	
	/// Changes the position of a bezier handle
	/// @param {Real}  _n Index of the point whose handle will change
	/// @param {Real}  x Absolute x position
	/// @param {Real}  y Absolute y position
	/// @param {Bool}  _handle The handle to change. true: handle 1 (with-flow handle) false: handle 2 (counter-flow handle)
	/// @param {Bool}  _break Whether the opposite handle will remain where it is (true) or reposition to mantain curve continuity (false)
	/// @param {Bool}  _symmetric Whether the opposite handle will reposition to remain equidistant from the changed handle (true) or keep its current length from point (false)
	static ChangeBezierHandle = function(_n,x,y,_handle=true,_break = false,_symmetric = false)
	{
		if type != PATHPLUS.BEZIER return;
		
		var _first_handle = true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		var _other_handle = _handle == true ? polyline[_n][$"h2"] : polyline[_n][$"h1"]
		if _first_handle == undefined return;
		
		_first_handle.x = x
		_first_handle.y = y
		
		if _other_handle == undefined return;
		
		if !_break
		{
			var _angle = point_direction(polyline[_n].x, polyline[_n].y, _first_handle.x,_first_handle.y)+180
			var _length = _symmetric ? 
							point_distance(polyline[_n].x, polyline[_n].y, _first_handle.x,_first_handle.y) : 
							point_distance(polyline[_n].x, polyline[_n].y, _other_handle.x,_other_handle.y) ;
			_other_handle.x =  polyline[_n].x+lengthdir_x(_length,_angle)
			_other_handle.y =  polyline[_n].y+lengthdir_y(_length,_angle)
		}
		_cache_gen  =	false
		__generate_cache()
		return self
	}
	/// Changes the position of a bezier handle to a position relative to its control point
	/// @param {Real}  _n Index of the point whose handle will change
	/// @param {Real}  x Relative x position
	/// @param {Real}  y Relative y position
	/// @param {Bool}  _handle The handle to change. true: handle 1 (with-flow handle) false: handle 2 (counter-flow handle)
	/// @param {Bool}  _break Whether the opposite handle will remain where it is (true) or reposition to mantain curve continuity (false)
	/// @param {Bool}  _symmetric Whether the opposite handle will reposition to remain equidistant from the changed handle (true) or keep its current length from point (false)
	static ChangeRelativeBezierHandle = function(_n,x,y,_handle=true,_break = false,_symmetric = true)
	{
		if type != PATHPLUS.BEZIER return
		
		x= polyline[_n].x+x
		y= polyline[_n].y+y
		
		ChangeBezierHandle(_n,x,y,_handle,_break,_symmetric)
		return self
	}
	/// Translates the position of a bezier handle
	/// @param {Real} _n Index of the point whose handle will change
	/// @param {Real}  x Relative x position
	/// @param {Real}  y Relative y position
	/// @param {Bool}  _handle The handle to change. true: handle 1 (with-flow handle) false: handle 2 (counter-flow handle)
	/// @param {Bool}  _break Whether the opposite handle will remain where it is (true) or reposition to mantain curve continuity (false)
	/// @param {Bool}  _symmetric Whether the opposite handle will reposition to remain equidistant from the changed handle (true) or keep its current length from point (false)
	static TranslateBezierHandle = function(_n,x,y,_handle=true,_break = false,_symmetric = true)
	{
		if type != PATHPLUS.BEZIER return
		
		var _first_handle = true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		var _other_handle = _handle == true ? polyline[_n][$"h2"] : polyline[_n][$"h1"]
		if _first_handle == undefined return;
		
		 x = _first_handle.x + x
		 y = _first_handle.y + y
		
		ChangeBezierHandle(_n,x,y,_handle,_break,_symmetric)
		return self
	}
	/// Changes the position of a bezier handle using angle and length from the control point
	/// @param {Real}  n Index of the point whose handle will change
	/// @param {Real}  _angle Angle in degrees
	/// @param {Real}  _length Length in pixels from the control point
	/// @param {Bool}  _handle The handle to change. true: handle 1 (with-flow handle) false: handle 2 (counter-flow handle)
	/// @param {Bool}  _break Whether the opposite handle will remain where it is (true) or reposition to mantain curve continuity (false)
	/// @param {Bool}  _symmetric Whether the opposite handle will reposition to remain equidistant from the changed handle (true) or keep its current length from point (false)
	static VectorBezierHandle = function(_n,_angle,_length,_handle=true,_break = false,_symmetric = true)
	{
		if type != PATHPLUS.BEZIER return;
		
		var _first_handle = true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		var _other_handle = _handle == true ? polyline[_n][$"h2"] : polyline[_n][$"h1"]
		if _first_handle == undefined return;
		
		_first_handle.x = polyline[_n].x+lengthdir_x(_length,_angle)
		_first_handle.y = polyline[_n].y+lengthdir_y(_length,_angle)
		
		if _other_handle == undefined return;
		
		if !_break
		{
			_angle += 180
			_length = _symmetric ? 
							_length : 
							point_distance(polyline[_n].x, polyline[_n].y, _other_handle.x,_other_handle.y) ;
			_other_handle.x =  polyline[_n].x+lengthdir_x(_length,_angle)
			_other_handle.y =  polyline[_n].y+lengthdir_y(_length,_angle)
		}
		_cache_gen  =	false
		__generate_cache()
		return self
	}
	
	static GetBezierHandleLength	= function(_n,_handle=true)
	{
		if type != PATHPLUS.BEZIER return;
		
		_handle =  true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		if _handle == undefined return;
		return		point_distance(polyline[_n].x, polyline[_n].y, _handle.x,_handle.y) ;
		
	}
	static GetBezierHandleAngle		= function(_n,_handle=true)
	{
		if type != PATHPLUS.BEZIER return;
		
		_handle = true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		if _handle == undefined return;
		return		point_direction(polyline[_n].x, polyline[_n].y, _handle.x,_handle.y) ;
	}
	// RotateHandle
	//Stretch handle
	#endregion
	
	// Speed changer functions
	
	static Reset	= function()
	{
		polyline = [];
		_cache_gen  =	false
	}
	/// Draws either a path, a polyline or its cached version
	static DebugDraw		= function(x,y,_path=false,_override_type=false)
	{
		if _path
		{
			draw_path(path,x,y,true)
			return
		}
		var _lines = type == PATHPLUS.LINEAR || _override_type ? polyline : cache
		
		var _c1 = draw_get_color()
		var _len = array_length(_lines)
		
		for(var _i=0; _i<_len;_i++)
		{
			draw_set_color(c_white)
			if closed && _i + 1 == _len
			{
				draw_line(_lines[_i].x,_lines[_i].y,_lines[0].x,_lines[0].y)
			}
			else if _i + 1 < _len
			{
				draw_line(_lines[_i].x,_lines[_i].y,_lines[_i+1].x,_lines[_i+1].y)
			}
			draw_set_color(c_aqua)
			draw_circle(_lines[_i].x,_lines[_i].y,2,false)
		}
		var _lines = polyline
		draw_set_color(c_red)
		for(var _i=0; _i<array_length(_lines);_i++)
		{
			draw_circle(_lines[_i].x,_lines[_i].y,3,false)
		}
		if type == PATHPLUS.BEZIER
		{
			draw_set_color(c_fuchsia)
			for(var _i=0; _i<array_length(_lines);_i++)
			{
				if _lines[_i][$"h1"] != undefined
				{
					draw_circle(_lines[_i].h1.x,_lines[_i].h1.y,2,false)
					draw_line(_lines[_i].h1.x,_lines[_i].h1.y,_lines[_i].x,_lines[_i].y)
				}
				if _lines[_i][$"h2"] != undefined
				{
					draw_circle(_lines[_i].h2.x,_lines[_i].h2.y,2,false)
					draw_line(_lines[_i].h2.x,_lines[_i].h2.y,_lines[_i].x,_lines[_i].y)
				}
			}	
		}
		
		draw_set_color(_c1)
	}
	static __generate_cache	= function()
	{
		if type == PATHPLUS.LINEAR || _cache_gen return
		
		var _t = 1/precision 
		for (var _i= 0, _n = 0 ; _i < l; _i+=_t )
		{ 
			if polyline[floor(_i)].cached == true
			{
				_n++
				continue
			}
			switch(type)
			{
				case PATHPLUS.BEZIER:
						var _point =	__bezier_point(polyline[floor(_i)],polyline[floor(_i+1)%l],frac(_i))
				break
				case PATHPLUS.CATMULL_ROM:
						if polyline[floor(_i)][$"segment"] == undefined 
						{
							var _point = 	polyline[floor(_i)]
						}
						else
						{
							var _point =	__catmull_rom_point(polyline[floor(_i)].segment,frac(_i))
						}
				break
			}
			
			if polyline[floor(_i)][$ "speed"] != undefined && polyline[floor(_i+1)%l][$ "speed"] != undefined 
			{
				_point.speed = lerp(polyline[floor(_i)].speed,polyline[floor(_i+1)%l].speed,frac(_i))
			}
					
			cache[_n]= _point
			
			if _i >= 1 polyline[floor(_i)-1].cached = true
			_n++
		}

		_cache_gen = true	
	}

	/// Gets the position of any point along the path, from 0 to 1
	static GetPosition		= function(_n)
	{
		var _length = l-1 ,
			_t = closed ? (_n* _length)% l : clamp(_n,0,1)*_length ,
		_point;
		
		switch(type)
		{
			case PATHPLUS.LINEAR:
			break;
			case PATHPLUS.BEZIER:
			{
				_point = __bezier_point(polyline[floor(_t)],polyline[floor(_t+1)%l],frac(_t))
				break;
			}
			case PATHPLUS.B_SPLINE:
			{
				break;
			}
			case PATHPLUS.CATMULL_ROM:
			{
				_point = __catmull_rom_point(polyline[floor(_t)].segment,frac(_t))
			break;
			}
		}
		return _point
	}
	/// Generates a polyline out of the path
	static PathToPoly		= function(_bake_smooth = false , _keep_speed =false)
	{
		var _l = path_get_number(path)
		polyline = []
		for(var _i= 0; _i < _l; _i++)
		{
			var _point = {}
			_point.x = path_get_point_x(path,_i)	
			_point.y = path_get_point_y(path,_i)	
			if _keep_speed _point.speed = path_get_speed(path,_i)
			
			_point.cached	= false
			array_push(polyline,_point)
		}
		_cache_gen  =	false
		
		return self
	}
	///Transforms all the points in cache into control points of a GM Path
	static BakeToPath = function()
	{
		if cache == undefined return
		
		if !_cache_gen __generate_cache()
		
		path_clear_points(path)
		path_set_closed(path,closed)
		path_set_precision(path,precision)
		path_set_kind(path,0)
		
		for (var _i= 0; _i < array_length(cache); _i++)
		{
			var _speed =  cache[_i][$ "speed"] ?? 100
			path_add_point(path,cache[_i].x,cache[_i].y,_speed)
		}
		
		return 
	}
	
	#region Catmull-Rom
		static SetCatmullRom = function(_alpha=.5,_tension=0.5)
		{
			_alpha		= clamp(_alpha,0,1)
			_tension	= clamp(_tension,0,1)
			_properties = {alpha : _alpha , tension : _tension}
			type		= PATHPLUS.CATMULL_ROM
			cache= []
			
			__catmull_rom_set(_properties.alpha,_properties.tension,0,l)
			__generate_cache()
		}
		static  __catmull_rom_set = function(_alpha,_tension,_start = 0 , _end = l)
		{
			if _end == l
			{
				var _length = closed ? l : l-1
			}
			else
			{
				var _length = _end
			}

			//Go through points and generate the coefficients for each segment
			for (var _i= _start; _i < _length; _i++)
			{ 
				var _p1= undefined , _p2 , _p3, _p4 = undefined;
			
				if _i==0 // if first point, create a phantom previous point OR pick the last point
				{
					if closed
					{
						_p1 = polyline[_length-1]
					}
					else
					{
						var _dir = point_direction(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)+180
						var _len = point_distance(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)
						_p1 =
						{
							x: lengthdir_x(_dir,_len)+polyline[0].x,
							y: lengthdir_y(_dir,_len)+polyline[0].y
						}
					}
				}
				else if _i == _length-1 && !closed // if last point, create a phantom next point OR pick the first point
				{
					var _dir = point_direction(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					var _len = point_distance(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					_p4 =
					{
						x: lengthdir_x(_dir,_len)+polyline[_i+1].x,
						y: lengthdir_y(_dir,_len)+polyline[_i+1].y
					}
				}
		
			_p1 ??= polyline[_i-1] ;
			_p2 = polyline[_i];
			if closed{
				_p3 = polyline[(_i+1)%_length];
				_p4 ??= polyline[(_i+2)%_length];
			}
			else
			{
				_p3 = polyline[(_i+1)];
				_p4 ??= polyline[(_i+2)];
			}
		
				polyline[_i].segment = __catmull_rom_coef(_p1,_p2,_p3,_p4,_alpha,_tension)
				polyline[_i].cached = false
			}
		}
		/// Based off Mika Rantanen implementation
		/// https://qroph.github.io/2018/07/30/smooth-paths-using-catmull-rom-splines.html
		static	__catmull_rom_coef = function(p0,p1,p2,p3,alpha=1,tension=0)
		{
			var
			 t01 = power(point_distance(p0.x,p0.y, p1.x,p1.y), alpha),
			 t12 = power(point_distance(p1.x,p1.y, p2.x,p2.y), alpha),
			 t23 = power(point_distance(p2.x,p2.y, p3.x,p3.y), alpha),
			m1={},m2={},segment={};
			segment.a={};segment.b={};segment.c={};segment.d={};

			m1.x = (1.0 - tension) *
			    (p2.x - p1.x + t12 * ((p1.x - p0.x) / t01 - (p2.x - p0.x) / (t01 + t12)));
			m2.x = (1.0 - tension) *
			    (p2.x - p1.x + t12 * ((p3.x - p2.x) / t23 - (p3.x - p1.x) / (t12 + t23)));
	
			m1.y = (1.0 - tension) *
			    (p2.y - p1.y + t12 * ((p1.y - p0.y) / t01 - (p2.y - p0.y) / (t01 + t12)));
			m2.y = (1.0 - tension) *
			    (p2.y - p1.y + t12 * ((p3.y - p2.y) / t23 - (p3.y - p1.y) / (t12 + t23)));

			segment.a.x = 2.0 * (p1.x - p2.x) + m1.x + m2.x;
			segment.b.x = -3.0 * (p1.x - p2.x) - m1.x - m1.x - m2.x;
			segment.c.x = m1.x;
			segment.d.x = p1.x;

			segment.a.y = 2.0 * (p1.y - p2.y) + m1.y + m2.y;
			segment.b.y = -3.0 * (p1.y - p2.y) - m1.y - m1.y - m2.y;
			segment.c.y = m1.y;
			segment.d.y = p1.y;

			return segment
		}
		static  __catmull_rom_point = function(segment,t)
		{
			var point = {},
			_2t = t*t,
			_3t= t*_2t
	
			point.x = segment.a.x * _3t +
		              segment.b.x * _2t +
		              segment.c.x * t +
		              segment.d.x;	
			point.y = segment.a.y * _3t +
		              segment.b.y * _2t +
		              segment.c.y * t +
		              segment.d.y;	
			  
			return point
		}
	#endregion
	
	#region Bezier
	static SetBezier = function()
		{
			type = PATHPLUS.BEZIER
			var _size = closed ? l*precision : ((l-1)*precision)+1
			cache= array_create(_size,0)
			__bezier_set(0,l)
			__generate_cache()
			
			return self
		}
		static  __bezier_set	  = function(_start = 0 ,  _end = 1)
		{
			if _end == l
			{
				var _length = closed ? l : l-1
			}
			else
			{
				var _length = _end % l
			}
			
			//Go through points and generate the tangents for each point
			for (var _i= _start; _i < _length; _i++)
			{ 
			
				var _p1= undefined , _p2 , _p3, _p4 = undefined;
			
				if _i==0 // if first point, create a phantom previous point OR pick the last point
				{
					if closed
					{
						_p1 = polyline[_length-1]
					}
					else
					{
						var _dir = point_direction(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)+180
						var _len = point_distance(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)
						_p1 =
						{
							x: lengthdir_x(_dir,_len)+polyline[0].x,
							y: lengthdir_y(_dir,_len)+polyline[0].y
						}
					}
				}
				else if _i == _length-1 && !closed // if last point, create a phantom next point OR pick the first point
				{
					var _dir = point_direction(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					var _len = point_distance(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					_p4 =
					{
						x: lengthdir_x(_dir,_len)+polyline[_i+1].x,
						y: lengthdir_y(_dir,_len)+polyline[_i+1].y
					}
				}
		
				_p1 ??= polyline[_i-1] ;
				_p2 = polyline[_i];
				_p3 = polyline[(_i+1)%l];
				_p4 ??= polyline[(_i+2)%l];
		
				var _tangents= __bezier_tangents(_p1,_p2,_p3,_p4)
				_p2.h1 = _tangents[0]
				_p3.h2 = _tangents[1]
				
				_p2.cached = false
			}
		}
		static  __bezier_set_single	  = function(_n)
		{
			var _i = _n
			if _n-1 >= 0
			{
				_i --
				var _p1= undefined , _p2 , _p3, _p4 = undefined;
			
				if _i==0 // if first point, create a phantom previous point OR pick the last point
				{
					if closed
					{
						_p1 = polyline[l-1]
					}
					else
					{
						var _dir = point_direction(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)+180
						var _len = point_distance(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)
						_p1 =
						{
							x: lengthdir_x(_dir,_len)+polyline[0].x,
							y: lengthdir_y(_dir,_len)+polyline[0].y
						}
					}
				}
				else if _i == l-1 && !closed // if last point, create a phantom next point OR pick the first point
				{
					var _dir = point_direction(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					var _len = point_distance(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					_p4 =
					{
						x: lengthdir_x(_dir,_len)+polyline[_i+1].x,
						y: lengthdir_y(_dir,_len)+polyline[_i+1].y
					}
				}
		
				_p1 ??= polyline[_i-1] ;
				_p2 = polyline[_i];
				_p3 = polyline[(_i+1)%l];
				_p4 ??= polyline[(_i+2)%l];
		
				var _tangents= __bezier_tangents(_p1,_p2,_p3,_p4)
				_p3.h2 = _tangents[1]
				_p2.cached = false
				_i++
			}
			if _n +1 < l
			{
				var _p1= undefined , _p2 , _p3, _p4 = undefined;
			
				if _i==0 // if first point, create a phantom previous point OR pick the last point
				{
					if closed
					{
						_p1 = polyline[l-1]
					}
					else
					{
						var _dir = point_direction(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)+180
						var _len = point_distance(polyline[0].x,polyline[0].y,polyline[1].x,polyline[1].y)
						_p1 =
						{
							x: lengthdir_x(_dir,_len)+polyline[0].x,
							y: lengthdir_y(_dir,_len)+polyline[0].y
						}
					}
				}
				else if _i == l-1 && !closed // if last point, create a phantom next point OR pick the first point
				{
					var _dir = point_direction(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					var _len = point_distance(polyline[_i].x,polyline[_i].y,polyline[_i+1].x,polyline[_i+1].y)
					_p4 =
					{
						x: lengthdir_x(_dir,_len)+polyline[_i+1].x,
						y: lengthdir_y(_dir,_len)+polyline[_i+1].y
					}
				}
		
				_p1 ??= polyline[_i-1] ;
				_p2 = polyline[_i];
				_p3 = polyline[(_i+1)%l];
				_p4 ??= polyline[(_i+2)%l];
		
				var _tangents= __bezier_tangents(_p1,_p2,_p3,_p4)
				_p2.h1 = _tangents[0]
				_p2.cached = false
			}
			
			
		}
		static	__bezier_tangents = function(p0,p1,p2,p3)
		{
			var
			 t01 = point_distance(p0.x,p0.y, p1.x,p1.y),
			 t12 = point_distance(p1.x,p1.y, p2.x,p2.y),
			 t23 = point_distance(p2.x,p2.y, p3.x,p3.y),
			h1={},h2={}

			h1.x = p1.x+(p2.x - p1.x + t12 * ((p1.x - p0.x) / t01 - (p2.x - p0.x) / (t01 + t12)))*.33;
			h2.x = p2.x-(p2.x - p1.x + t12 * ((p3.x - p2.x) / t23 - (p3.x - p1.x) / (t12 + t23)))*.33;
	
			h1.y =  p1.y+(p2.y - p1.y + t12 * ((p1.y - p0.y) / t01 - (p2.y - p0.y) / (t01 + t12)))*.33;
			h2.y =  p2.y-(p2.y - p1.y + t12 * ((p3.y - p2.y) / t23 - (p3.y - p1.y) / (t12 + t23)))*.33;


			return [h1,h2]
		}
		static  __bezier_point = function(p1,p2,t)
		{
			if p1[$ "h1"] == undefined
			{
				return p1
			}
			var point = {},
			_2t = t*t,
			_3t= t*_2t
	
			var mt = 1 - t;
			var mt2 = mt * mt;
			var mt3 = mt2 * mt;

			point.x = p1.x * mt3 + 3 * p1.h1.x * mt2 * t + 3 * p2.h2.x * mt * _2t + p2.x * _3t;
			point.y = p1.y * mt3 + 3 * p1.h1.y * mt2 * t + 3 * p2.h2.y * mt * _2t + p2.y * _3t;
			  
			return point
		}	
	#endregion
	
	static SetBSpline = function()
		{}

}
