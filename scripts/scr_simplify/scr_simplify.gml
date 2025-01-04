
//feather ignore all
/**
 * Simplifies a line or shape based on an epsilon value from 0 to 1. 0 = no simplification 1 = Complete simplification.
 *  Returns a new array of points.
 * @param {Array} _points An array with points defined as a struct {x,y}
 * @param {Real} _epsilon  0 = no simplification 1 = Complete simplification. When epsilon is left empty, it will use an estimate which is fairly strong, based on an average of the points.
 * @return {Array}
 */
function curve_simplify(_points,_epsilon=undefined){

	var _start = 0
	var _end = array_length(_points)-1
	var simple_point_list = array_create(array_length(_points))

	simple_point_list[_start]	=_points[_start]
	simple_point_list[_end]		=_points[_end]

	
	// Go through all points to find the points that are furthest and closest from the line between A and B
	var _maxDist = -1,
		_maxIndex = -1,
		_avgDist = 0,
		_medVal = [],
		_distToAvg =0
			
	for(var _i = _start ; _i< _end ;_i++)
	{
		var _d = pointToLineDistance(	_points[_i].x		,_points[_i].y,
										_points[_start].x	,_points[_start].y,
										_points[_end].x	,_points[_end].y)
		_avgDist += _d
		//_medVal[_i] = _d
			
		if _d > _maxDist
		{
				_maxDist	=	_d
				_maxIndex	=	_i
		}
	}
	_avgDist =(_avgDist/_end)
	_avgDist *=.1
	_epsilon= _epsilon == undefined ? _avgDist : lerp(0,_maxDist,_epsilon)

	simple_point_list = _array_merge(simple_point_list,__simplify_step(_points,_epsilon,_start,_end))

	return _array_clean(simple_point_list)
}

