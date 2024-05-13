enum PATHPLUS {LINEAR, BEZIER,B_SPLINE ,CATMULL_ROM, GM_SMOOTH  }

function PathPlus(_path = []) constructor
{
	if is_handle(_path)
	{
		path		=	path_add()
		path_assign(path,_path)
		PathToPoly(false,true);
		l			=	path_get_number(path);
		precision	=	path_get_precision(path);
		closed		=	path_get_closed(path);
		type		=	path_get_kind(path) == true ? PATHPLUS.GM_SMOOTH : PATHPLUS.LINEAR	;
	}
	else if is_array(_path)
	{
		path		=	path_add()
		polyline	=	_path
		l			=	array_length(polyline)
		precision	=	8;
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
	#region Polyline Basics
	/// Adds point to the Polyline
	static AddPoint = function(_x,_y,_optional_vars = {}) 
	{
		_optional_vars.x		= _x
		_optional_vars.y		= _y
		_optional_vars.cached	= false
		l++
		array_push(polyline,_optional_vars)
		_cache_gen  =	false
		
		return self
	}
	//insert point
	//remove point
	//noise
	//simplify
	//closest point on path
	#endregion
	#region Path basics
	
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
	
	static Reset	= function()
	{
		polyline = [];
		_cache_gen  =	false
	}
	static Draw		= function(x,y,_path=false,_override_type=false)
	{
		if _path
		{
			draw_path(path,x,y,true)
			return
		}
		var _lines = type == PATHPLUS.LINEAR ? polyline : cache
		
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
				if _lines[_i][$"m1"] != undefined
				{
					draw_circle(_lines[_i].m1.x,_lines[_i].m1.y,2,false)
					draw_line(_lines[_i].m1.x,_lines[_i].m1.y,_lines[_i].x,_lines[_i].y)
				}
				if _lines[_i][$"m2"] != undefined
				{
					draw_circle(_lines[_i].m2.x,_lines[_i].m2.y,2,false)
					draw_line(_lines[_i].m2.x,_lines[_i].m2.y,_lines[_i].x,_lines[_i].y)
				}
			}	
		}
		
		draw_set_color(_c1)
	}
	static __GenerateCache =  function()
	{
		switch(type)
		{
			case PATHPLUS.LINEAR:
				return;
			break;
			case PATHPLUS.BEZIER:
			{
				if _cache_gen return
				var _t = 1/precision ,
				_length = closed ? l : l-1
				for (var _i= 0; _i < _length; _i+=_t)
				{ 
					var _point = __bezier_point(polyline[floor(_i)],polyline[floor(_i+1)%l],frac(_i))
					array_push(cache,_point)
			
					if _i > 0 polyline[floor(_i)].cached = true
				}
				
				if !closed array_push(cache,polyline[floor(_i)])
				_cache_gen = true	
			}
			break;
			case PATHPLUS.B_SPLINE:
			break;
			case PATHPLUS.CATMULL_ROM:
			{
				// Generate subpoints based on the precision
				var _t = 1/precision ,
					_length = closed ? l : l-1
				for (var _i= 0; _i < _length; _i+=_t)
				{ 
					var _point = __catmull_rom_point(polyline[floor(_i)].segment,frac(_i))
					array_push(cache,_point)
			
					if _i > 0 polyline[floor(_i)].cached = true
				}
				_cache_gen = true
			break;
			}
		}
		_cache_gen  = true
	}

	/// Generates a polyline out of the path
	static PathToPoly	= function(_bake_smooth = false , _keep_speed =false)
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
	static BakeToPath = function(smooth =false)
	{
		if cache == undefined return
		
		if !_cache_gen __GenerateCache()
		
		path_clear_points(path)
		path_set_closed(path,closed)
		path_set_precision(path,precision)
		path_set_kind(path,smooth)
		
		for (var _i= 0; _i < array_length(cache); _i++)
		{
			var _speed =  cache[_i][$ "speed"] ?? 100
			path_add_point(path,cache[_i].x,cache[_i].y,_speed)
		}
		
		return 
	}
	
	#region Catmull-Rom
		static SetCatmullRom = function(_alpha=.5,_tension=0)
		{
			var _length = closed ? l : l-1
			type = PATHPLUS.CATMULL_ROM
			//Go through points and generate the coefficients for each segment
			for (var _i= 0; _i < _length; _i++)
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
			_p3 = polyline[(_i+1)%_length];
			_p4 ??= polyline[(_i+2)%_length];
		
				polyline[_i].segment = __catmull_rom_coef(_p1,_p2,_p3,_p4,_alpha,_tension)
			}
	
			__GenerateCache()
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
			var _length = closed ? l : l-1
			type = PATHPLUS.BEZIER
			//Go through points and generate the coefficients for each segment
			for (var _i= 0; _i < _length; _i++)
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
				_p2.m1 = _tangents[0]
				_p3.m2 = _tangents[1]
			}
	
			__GenerateCache()
			
			return self
		}
		static	__bezier_tangents = function(p0,p1,p2,p3)
		{
			var
			 t01 = point_distance(p0.x,p0.y, p1.x,p1.y),
			 t12 = point_distance(p1.x,p1.y, p2.x,p2.y),
			 t23 = point_distance(p2.x,p2.y, p3.x,p3.y),
			m1={},m2={}

			m1.x = p1.x+(p2.x - p1.x + t12 * ((p1.x - p0.x) / t01 - (p2.x - p0.x) / (t01 + t12)))*.33;
			m2.x = p2.x-(p2.x - p1.x + t12 * ((p3.x - p2.x) / t23 - (p3.x - p1.x) / (t12 + t23)))*.33;
	
			m1.y =  p1.y+(p2.y - p1.y + t12 * ((p1.y - p0.y) / t01 - (p2.y - p0.y) / (t01 + t12)))*.33;
			m2.y =  p2.y-(p2.y - p1.y + t12 * ((p3.y - p2.y) / t23 - (p3.y - p1.y) / (t12 + t23)))*.33;


			return [m1,m2]
		}
		static  __bezier_point = function(p1,p2,t)
		{
			var point = {},
			_2t = t*t,
			_3t= t*_2t
	
			var mt = 1 - t;
			var mt2 = mt * mt;
			var mt3 = mt2 * mt;

			point.x = p1.x * mt3 + 3 * p1.m1.x * mt2 * t + 3 * p2.m2.x * mt * _2t + p2.x * _3t;
			point.y = p1.y * mt3 + 3 * p1.m1.y * mt2 * t + 3 * p2.m2.y * mt * _2t + p2.y * _3t;
			  
			return point
		}	
	#endregion
	
	static SetBSpline = function()
		{}

}
