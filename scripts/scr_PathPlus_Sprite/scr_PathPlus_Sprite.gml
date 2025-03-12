function PathPlusSprite (_pathplus,_sprite, _thickness = undefined) constructor
{
	sprite		= _sprite
	pathplus	= _pathplus
	base_width	= _thickness == undefined ? sprite_get_height(sprite) : _thickness
	spw			= pathplus.pixel_length / sprite_get_width(sprite);
	cache		= []
	nodes		= animcurve_really_create({
		curve_name : "PathPlusSpriteAC" ,
		channels : [{name:"w_n" , type : animcurvetype_catmullrom , iterations : 8},
					{name:"w_s" , type : animcurvetype_catmullrom , iterations : 8},
					{name:"r" , type : animcurvetype_catmullrom , iterations : 8},
					{name:"g" , type : animcurvetype_catmullrom , iterations : 8},
					{name:"b" , type : animcurvetype_catmullrom , iterations : 8},
					{name:"a" , type : animcurvetype_catmullrom , iterations : 8}
					]
	})
	
	AddColor(0,c_white)
	AddColor(1,c_white)
	
	animated			= false
	animation_offset	= 0
	frame				= 0
	mask_start			= 0
	mask_end			= 1
	tiled				= true
	
	//Tapers
	taper_start			= 0
	start_length		= 0
	taper_end			= 0
	end_length			= 0
	
	// Add 
	
	static AddColor = function(_n,_color,_alpha=1)
	{
		_n		= clamp(_n,0,1)
		
		var
		//_r2 = color_get_red(_color),
		//_g2 = color_get_green(_color),
		//_b2 = color_get_blue(_color),
		_r2 = color_get_hue(_color),
		_g2 = color_get_saturation(_color),
		_b2 = color_get_value(_color),
		_a2 = clamp(_alpha,0,1),
		_r	= animcurve_get_channel(nodes,"r").points,
		_g	= animcurve_get_channel(nodes,"g").points,
		_b	= animcurve_get_channel(nodes,"b").points,
		_a	= animcurve_get_channel(nodes,"a").points

		animcurve_point_add(_r,_n,_r2)
		animcurve_point_add(_g,_n,_g2)
		animcurve_point_add(_b,_n,_b2)
		animcurve_point_add(_a,_n,_a2)
		
		animcurve_points_set(nodes,"r",_r)
		animcurve_points_set(nodes,"g",_g)
		animcurve_points_set(nodes,"b",_b)
		animcurve_points_set(nodes,"a",_a)
		
		return self
	}
	
	static AddThickness = function(_n,_north,_south=_north) 
	{
		_n		= clamp(_n,0,1)
		_north	= clamp(_north,0,1)
		_south	= clamp(_south,0,1)
		
		var
		_w_n	= animcurve_get_channel(nodes,"w_n").points,
		_w_s	= animcurve_get_channel(nodes,"w_s").points
		
		animcurve_point_add(_w_n,_n,_north,true)
		animcurve_point_add(_w_s,_n,_south,true)
		
		animcurve_points_set(nodes,"w_n",_w_n)
		animcurve_points_set(nodes,"w_s",_w_s)
		
		return self
	}

	static SetMask = function(_start,_end) 
	{
		mask_start			= clamp(_start,0,1)
		mask_end			= clamp(_end,0,1)
		
		return self
	}
	
	static SetTaper = function(_taper_start, _start_length, _taper_end , _end_length) 
	{
		taper_start			=  clamp(_taper_start,0,1)
		start_length		=  clamp(_start_length,0,1)
		taper_end			=  clamp(_taper_end,0,1)
		end_length			=  clamp(_end_length,0,1)
		
		return self
	}

	static SetSprite =  function(_sprite)
	{
		sprite		= _sprite
		spw			= pathplus.pixel_length / sprite_get_width(sprite);
		
		return self
	}
	
	static Draw = function(_subimg=0)
	{
		var 
		sprite_pt= sprite_get_texture(sprite, _subimg) ,
		repeatX = 1, repeatY = 1 ,
		_l = array_length(cache)		

		draw_primitive_begin_texture(pr_trianglestrip, sprite_pt);

		for (var i = 0; i < _l; i++)
		{
			var 
			curr = cache[i] ,
			uv = curr.l / pathplus.pixel_length 
		
		    if tiled {uv *= spw}
		    uv *= repeatX;

		   draw_vertex_texture_colour(curr.x1, curr.y1, uv, repeatY, curr.color, curr.alpha);
		   draw_vertex_texture_colour(curr.x2, curr.y2, uv, 0, curr.color, curr.alpha);
		}
		
		gpu_set_texrepeat(true);
		draw_primitive_end();
		gpu_set_texrepeat(false);
	}
	
	static DebugDraw = function()
	{
		var _l = array_length(cache)	
		
		for (var i = 0; i < _l-1; i++)
		{
			var 
			curr = cache[i],
			next = cache[i+1]
			
			draw_line(curr.x1, curr.y1, curr.x2, curr.y2)
			draw_line(curr.x2, curr.y2, next.x1, next.y1)
			draw_line(next.x1, next.y1,curr.x1, curr.y1)
		}
	}
	
	static RegenCache = function(color=true, pos=true)
	{
		var _cache = pathplus.cache ,
			_l = array_length(_cache)
			
		if 	array_length(cache)!= _l 
		{
			cache = _cache
		}
		
		var
		_r		= animcurve_get_channel(nodes,"r"),
		_g		= animcurve_get_channel(nodes,"g"),
		_b		= animcurve_get_channel(nodes,"b"),
		_a		= animcurve_get_channel(nodes,"a"),
		_w_n	= animcurve_get_channel(nodes,"w_n"),
		_w_s	= animcurve_get_channel(nodes,"w_s")
		
		
		for (var i = 0; i < _l; i++)
		{		
			var _n = _cache[i].l/pathplus.pixel_length ,
			point = cache[i],
			_ws,_wn ,
			_color,_alpha
			
			if pos
			{
				_wn = animcurve_channel_evaluate(_w_n,_n)*(base_width*.5)
				_ws = animcurve_channel_evaluate(_w_s,_n)*(base_width*.5)
				
				point.x2= lengthdir_x(_ws,_cache[i].normal)		+ _cache[i].x 
				point.y2= lengthdir_y(_ws,_cache[i].normal)		+ _cache[i].y 
				point.x1= lengthdir_x(_wn,_cache[i].normal-180)	+ _cache[i].x 
				point.y1= lengthdir_y(_wn,_cache[i].normal-180)	+ _cache[i].y 
			}
			
			if color
			{
				var __r = animcurve_channel_evaluate(_r,_n) ,
					__g = animcurve_channel_evaluate(_g,_n) ,
					__b = animcurve_channel_evaluate(_b,_n)
				//_color = make_color_rgb(__r,__g	,__b)
				_color = make_color_hsv(__r,__g	,__b)
				_alpha = animcurve_channel_evaluate(_a,_n)
				
				point.alpha = _alpha
				point.color = _color
			}

			point.l = _cache[i].l

			cache[i] = point
		}
	}
	
}


/// @description             
/// @param {Id.Instance}     
/// @param {Asset.GMObject}  
/// @return 
function PathPlus_DrawSprite(pathplus,sprite,width)
{

}