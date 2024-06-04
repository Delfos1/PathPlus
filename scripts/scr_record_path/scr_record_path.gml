/// Start recording a path. This will save a polyline with timecode and pixel information.
/// Necessary to use every step
function PathRecord(x,y){

	static rec = new PathPlus() 
	static l = -1
	static sensitivity = 5
	static start_time = undefined
	
	start_time ??= current_time
	var _time = (current_time-start_time) ,
	games
		_pixels_per_frame = 1
	if l != -1 
	{
		var _distance = point_distance(x,y,rec.polyline[l].x,rec.polyline[l].y) //compare current position to previous 
		if  _distance < sensitivity		return
		
		var _t = _time - rec.polyline[l].time
		_pixels_per_frame = _distance / (_t/(game_get_speed(gamespeed_microseconds)*0.001))
	}
	
	l++
	rec.AddPoint(x,y,{time : _time, ppf: _pixels_per_frame})

	return 
}

/// Stops the path recording and resets 
function PathRecordStop(_record_speed = true,smooth= true,prec= 8,_closed=true){
		var _l = PathRecord.l	
		if _l == -1 return
	var _pathPlus =  new PathPlus(PathRecord.rec.polyline)
	var _path =_pathPlus.path,
		_p = PathRecord.rec.polyline ,
		_l = PathRecord.l	,
		_spdmax=undefined
	path_set_closed(_path,_closed)
	path_set_precision(_path,prec)
	path_set_kind(_path,smooth)
	
	if _record_speed
	{
		for(var _j = 0 ; _j<_l;_j++)
		{
			var _speed = _p[_j].ppf
				
			_spdmax??= _speed
			_spdmax= _speed > _spdmax ? _speed : _spdmax
		}
		_pathPlus.path_speed = _spdmax
	}
	//simplify path
	
	//generate path resource
	for(var _i = 0 ; _i<_l;_i++)
	{
		var _speed = 100
		if _record_speed && _i<_l //calculate speed based on percentage
		{
			var _speed =  (_p[_i].ppf/_spdmax)*100
		}
		path_add_point(_path,_p[_i].x,_p[_i].y,_speed)
	}
	
	//restart statics	
	PathRecord.rec.Reset()
	PathRecord.l				= -1
	PathRecord.start_time		= undefined

return _pathPlus
	
}
	
function PathRecordDraw(){	
	if PathRecord.l	== -1 return 
	PathRecord.rec.DebugDraw()
	return
}  



