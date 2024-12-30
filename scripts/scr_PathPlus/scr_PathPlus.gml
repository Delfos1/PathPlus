enum PATHPLUS {LINEAR, BEZIER,CATMULL_ROM,GM_SMOOTH }

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
		_cache_gen  =	false
		_regen()
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
		
		_cache_gen  =	false
		
		_regen()
		return self
	}
	/// Removes the point on the polyline at the n position
	static RemovePoint	= function(n,_amount = 1) 
	{
		n = clamp(n,0,l-1)

		_cache_gen  =	false
			
		l-=_amount
		array_delete(polyline,n,_amount)
		
		_regen()

		return self
	}
	/// Changes the point on the polyline at the n position
	static ChangePoint	= function(n,_x,_y) 
	{
		n = clamp(n,0,l-1)
		var	_prevx = polyline[n].x		,
			_prevy = polyline[n].y		
		polyline[n].x		= _x
		polyline[n].y		= _y

		_cache_gen  =	false
		
		switch(type){
			
			case PATHPLUS.CATMULL_ROM:
				__catmull_rom_set()
			break
			case PATHPLUS.BEZIER:
			
					var _first_handle = polyline[n][$"h1"] ?? polyline[n][$"h2"]
					var _other_handle = _first_handle == polyline[n][$"h1"]  ? polyline[n][$"h2"] : undefined
					if _first_handle == undefined break;
		
		
					_first_handle.x += (_x-_prevx)
					_first_handle.y += (_y-_prevy)
		

					if _other_handle != undefined 
					{
						_other_handle.x += (_x-_prevx)
						_other_handle.y += (_y-_prevy)
					}
			__bezier_set()
			break
		}

		return self
	}
	/// Translates the n point on the polyline relative to its current position
	static TranslatePoint	= function(n,_x,_y) 
	{
		n = clamp(n,0,l-1)
		_x += polyline[n].x				
		_y += polyline[n].y		
	
		ChangePoint(n,_x,_y)

		return self
	}
	/// Changes a single variable within a point. To be used with user amde variables. For PathPlus variables use the proper getters
	static ChangePointVariable	= function(n,_var_as_string,_new_value) 
	{
		if _var_as_string == "x" || _var_as_string == "y" || _var_as_string == "h1" || _var_as_string == "h2" || _var_as_string == "weight" return self
		n = clamp(n,0,l-1)
		if !struct_exists(polyline[n],_var_as_string) return self
		

		polyline[n][$ _var_as_string] = _new_value
		polyline[n].cached	= false
		_cache_gen  =	false
		
		return self
	}
	//noise
	//simplify
	//closest point on path
	#endregion
	#region Path Wrappers
	
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
		
		var _first_handle = _handle == true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		var _other_handle = _handle == true ? polyline[_n][$"h2"] : polyline[_n][$"h1"]
		if _first_handle == undefined return;
		
		
		_first_handle.x = x
		_first_handle.y = y
		

		if _other_handle != undefined  && !_break
		{
			var _angle = point_direction(polyline[_n].x, polyline[_n].y, _first_handle.x,_first_handle.y)+180
			var _length = _symmetric ? 
							point_distance(polyline[_n].x, polyline[_n].y, _first_handle.x,_first_handle.y) : 
							point_distance(polyline[_n].x, polyline[_n].y, _other_handle.x,_other_handle.y) ;
			_other_handle.x =  polyline[_n].x+lengthdir_x(_length,_angle)
			_other_handle.y =  polyline[_n].y+lengthdir_y(_length,_angle)
		}
		_cache_gen  =	false
		 polyline[max(0,(_n-1))].cached = false
		 polyline[_n].cached = false
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

		var _first_handle = _handle == true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
		if _first_handle == undefined return self;
		
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
		
		var _first_handle = _handle == true ? polyline[_n][$"h1"] : polyline[_n][$"h2"]
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

	//static ChangeSpeedFalloff = function(n,_speed,_falloff = 0.2){}

	/// Export a .yy file with the contents of the cache polyline. You need to overwrite an existing path in your GameMaker project for it to work.
	/// Recommended that you simplify the result before exporting to avoid redundant information
	static Export = function(){

	show_message("Warning : You must replace an already existing path in your Game Maker project")

	var file;
	file = get_save_filename("*.yy", "path");
	if (file != "")
	{
		var _path = path ,
		 _closed = path_get_closed(_path)? "\"closed\":true," :"\"closed\":false,",
		 _kind = "\"kind\":" + string(path_get_kind(_path)) + ",",
		 _precision = "\"precision\":" + string(path_get_precision(_path)) + ",",
		 _stringy = json_stringify(cache),
		_name = filename_name(file) 
		_name = string_delete(_name , string_length(_name)-2,3) 
		var _pre = "{ \"$GMPath\":\"\",  \"%Name\":\"" +_name + "\"," +_closed + _kind + _precision + "  \"name\":\"" +_name + "\"," +  "\"parent\":{    \"name\":\"Paths\",    \"path\":\"folders/Paths.yy\",  },\"points\":"
		var _post = ", \"resourceType\":\"GMPath\",  \"resourceVersion\":\"2.0\",}"
		_stringy = string_concat(_pre,_stringy,_post)
		var _buff = buffer_create(string_byte_length(_stringy), buffer_fixed, 1);
	
		buffer_write(_buff, buffer_text, _stringy);
		buffer_save(_buff, file);
		buffer_delete(_buff);
	}
}
	
	static _regen =  function()
	{
	 switch(type){
			
			case PATHPLUS.CATMULL_ROM:
					__catmull_rom_set()
			break
			case PATHPLUS.BEZIER:
					__bezier_set()
			break
		}	
	}
	
	static Reset	= function()
	{
		polyline = [];
		_cache_gen  =	false
	}
	/// Draws either a path, a polyline or its cached version.
	/// @param {Real}   _x		Drawing offset
	/// @param {Real}   _y		Drawing offset
	/// @param {Bool}   _points Whether to draw control points or not
	/// @param {Bool}  _path	Whether to draw the path element or the polyline/cache element
	/// @param {Bool}  _force_poly	Whether to display the interpolated line(false) or base polyline (true)
	static DebugDraw		= function(_x=0,_y=0,_points=false,_path=false,_force_poly=false)
	{
		if _path
		{
			draw_path(path,x,y,true)
			return
		}
		// If type is linear or we are forcing polyline, assign the polyline array, otherwise draw from cache
		var _lines = type == PATHPLUS.LINEAR || _force_poly ? polyline : cache
		
		var _c1 = draw_get_color()
		var _len = array_length(_lines)
		
		for(var _i=0; _i<_len;_i++)
		{
			draw_set_color(COLOR_LINE)
			if closed && _i + 1 == _len
			{
				draw_line(_x+_lines[_i].x,_y+_lines[_i].y,_x+_lines[0].x,_y+_lines[0].y)
			}
			else if _i + 1 < _len
			{
				draw_line(_x+_lines[_i].x,_y+_lines[_i].y,_x+_lines[_i+1].x,_y+_lines[_i+1].y)
			}
			if _points
			{
				draw_set_color(COLOR_INTR)
				draw_circle(_x+_lines[_i].x,_y+_lines[_i].y,2,false)
				draw_set_color(c_gray)
				if type == PATHPLUS.CATMULL_ROM
				{
					var x1 = _x+_lines[_i].x+lengthdir_x(10,_lines[_i].normal)
					var y1 =_y+_lines[_i].y+lengthdir_y(10,_lines[_i].normal)
					var x2 = _x+_lines[_i].x
					var y2 =_y+_lines[_i].y
					draw_line(x1,y1,x2,y2)
					// get normal and extend from x, and draw it
					//draw_line
				}

			}
		}
		if _points
		{
			var _lines = polyline
			draw_set_color(COLOR_PT)
			for(var _i=0; _i<array_length(_lines);_i++)
			{
				draw_circle(_x+_lines[_i].x,_y+_lines[_i].y,3,false)
			}
			if type == PATHPLUS.BEZIER 
			{
				draw_set_color(COLOR_BEZ)
				for(var _i=0; _i<array_length(_lines);_i++)
				{
					if _lines[_i][$"h1"] != undefined
					{
						draw_circle(_x+_lines[_i].h1.x,_y+_lines[_i].h1.y,2,false)
						draw_line(_x+_lines[_i].h1.x,_y+_lines[_i].h1.y,_x+_lines[_i].x,_y+_lines[_i].y)
					}
					if _lines[_i][$"h2"] != undefined
					{
						draw_circle(_x+_lines[_i].h2.x,_y+_lines[_i].h2.y,2,false)
						draw_line(_x+_lines[_i].h2.x,_y+_lines[_i].h2.y,_x+_lines[_i].x,_y+_lines[_i].y)
					}
				}	
			}

		}
		draw_set_color(_c1)
	}
	
	static GenerateCache	= function()
	{
		if type == PATHPLUS.LINEAR || _cache_gen return
		
		var _t = 1/precision 
		cache = []
		
		for (var _i= 0, _n = 0 ; _i < l; _i+=_t )
		{ 
			switch(type)
			{
				case PATHPLUS.BEZIER:
						var _point =	__bezier_point(polyline[floor(_i)],polyline[floor(_i+1)%l],frac(_i))
				break;
				case PATHPLUS.CATMULL_ROM:
						if polyline[floor(_i)][$"segment"] == undefined || ( !closed && _i >= l-1 )
						{
							var _point = 	polyline[floor(_i)] 
						}
						else
						{
							var _point =	__catmull_rom_point(polyline[floor(_i)].segment,frac(_i))
						}
				break;
			}
			
			if polyline[floor(_i)][$ "speed"] != undefined && polyline[floor(_i+1)%l][$ "speed"] != undefined 
			{
				_point.speed = lerp(polyline[floor(_i)].speed,polyline[floor(_i+1)%l].speed,frac(_i))
			}
			else
			{
				_point.speed = 100
			}
					
			cache[_n]= _point
			
			 if ( !closed && _i >= l-1 ) break
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
			_point = { x : lerp(polyline[floor(_t)].x,polyline[ceil(_t)].x,frac(_t)), y : lerp(polyline[floor(_t)].y,polyline[ceil(_t)].y,frac(_t))}
			break;
			case PATHPLUS.BEZIER:
			{
				_point = __bezier_point(polyline[floor(_t)],polyline[floor(_t+1)%l],frac(_t))
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
		static SetCatmullRom = function(_alpha=.5,_tension=.5)
		{
			_alpha		= clamp(_alpha,0,1)
			_tension	= clamp(_tension,0,1)
			_properties = {alpha : _alpha , tension : _tension}
			type		= PATHPLUS.CATMULL_ROM
			cache= []
			
			__catmull_rom_set()
			GenerateCache()
		}
		static  __catmull_rom_set = function(_start = 0 , _end = l)
		{
			var _alpha		= _properties.alpha,
				_tension	= _properties.tension
				
			if _start < 0
			{
				 _start = closed ? l-_start : 0
			}
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
		var _x = 3 * segment.a.x * _2t + 2 * segment.b.x * t + segment.c.x;
		var _y = 3 * segment.a.y * _2t  + 2 * segment.b.y * t + segment.c.y;
	
		point.tangent = point_direction(0,0,_x,_y)
		point.normal =   point.tangent +90
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
			GenerateCache()
			
			return self
		}
		static  __bezier_set	  = function(_start = 0 ,  _end = l)
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
				_p2[$ "h1"] ??= _tangents[0]
				_p3[$ "h2"] ??= _tangents[1]
				

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
			if p1[$ "h1"]  == undefined || p2[$ "h2"] == undefined
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
	

}
