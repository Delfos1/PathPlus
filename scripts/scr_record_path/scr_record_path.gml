/// Start recording a path. This will save a polyline with timecode and pixel information.
/// Necessary to use every step
function PathRecord(x,y){

	static rec = new PathPlus() 
	static l = -1
	static sensitivity = 5
	static start_time = undefined

	
	start_time ??= current_time
	
	
	var _time = (current_time-start_time) 

		_pixels_per_frame = 1
	if l != -1 
	{
		var _distance = point_distance(x,y,rec.polyline[l].x,rec.polyline[l].y) //compare current position to previous 
		if  _distance < sensitivity		return
		show_debug_message($"distance = {_distance}, {l}")
		var _t = _time - rec.polyline[l].time
		_pixels_per_frame = _distance / (_t/(game_get_speed(gamespeed_microseconds)*0.001))
	}
	
	l++
	rec.AddPoint(x,y,,{time : _time, ppf: _pixels_per_frame})

	return 
}

/// Stops the path recording and resets 
function PathRecordStop(_record_speed = true,smooth= false,prec= 8,_closed=false){
	
	var _l = PathRecord.l	
	if _l == -1 return
		
	var _pathPlus =  new PathPlus(PathRecord.rec.polyline)
	var _p = _pathPlus.polyline ,
		_spdmax= -infinity
	

	if _record_speed
	{
		for(var _j = 0 ; _j<_l;_j++)
		{
			var _speed = _p[_j].ppf

			_spdmax= _speed > _spdmax ? _speed : _spdmax
		}
		_pathPlus.path_speed = _spdmax // speed in pixels for the object to follow. This is the max speed it can get to
	}
	//simplify path
	_pathPlus.Simplify(.02)
	_pathPlus.SetCatmullRom(1,0.2)
	//_pathPlus.GetLength()
	
	//generate path resource
	for(var _i = 0 ; _i<_l;_i++)
	{
		var _speed = 100
		if _record_speed && _i<_l //calculate speed based on percentage
		{
			var _speed =  (_p[_i].ppf/_spdmax)*100
		}
		_p[_i].speed = _speed
	}
		_pathPlus.SetClosed(_closed).SetPrecision(2).BakeToPath()
		

	//restart statics	
	PathRecord.rec.Reset()
	PathRecord.l				= -1
	PathRecord.start_time		= undefined

return _pathPlus
	
}
	
function PathRecordDraw(){	
	if PathRecord.l	== -1 return false

	
	PathRecord.rec.DebugDraw()
	
	return true
}  



