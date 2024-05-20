         
/// Records a polygon to be usde as a lasso selection  
/// @param {Array}     _selection Array to record the polygon to
/// @param {Real}		x x coordinate of the new position
/// @param {Real}		y y coordinate of the new position
/// @param {Real}		_dis minimum distance required to record a new vertex

function LassoSelection(_selection,x,y,_dis = 10){
	
	var _l = array_length(_selection)
	
	if _l == 0
	{
		array_push(_selection,[x,y])
		exit
	}
	
	var _d = point_distance(_selection[_l-1][0],_selection[_l-1][1],x,y)
	
	if _d >_dis
	{
		array_push(_selection,[x,y])
		exit
	}

}
function LassoDraw(_selection){

	var _l = array_length(_selection)
	
	if _l == 0
	{ exit }
	
	for(var _i=0; _i<_l-1;_i++)
	{
		draw_line(_selection[_i][0],_selection[_i][1],_selection[_i+1][0],_selection[_i+1][1])
	}
}
function LassoEnd(_selection,_collide){

	//Close shape
	array_push(_selection,_selection[0])

	var _coord =[]

	#region Prepare collision points for checks
	if is_array(_collide)
	{
		for(var _j=0; _j<array_length(_collide);_j++)
		{
			if is_handle(_collide[_j])
			{
				with(_collide[_j])
				{
					array_push(_coord,[id,[bbox_left,bbox_top],[bbox_left,bbox_bottom],[bbox_right,bbox_top],[bbox_right,bbox_bottom]])
				}
			}else{array_push(_coord,_collide[_j])}
		}
	}
	else if is_handle(_collide)
	{
		with(_collide)
		{
			array_push(_coord,[id,[bbox_left,bbox_top],[bbox_left,bbox_bottom],[bbox_right,bbox_top],[bbox_right,bbox_bottom]])
		}
	}
	else
	{
		show_debug_message("Lasso Error: Collide data procided doesnt conform to an array or an object")	
	}
	#endregion
	
	var _results =[]
	var _l = array_length(_coord)
	for(var _i=0; _i<_l;_i++)
	{
		// Starts at 1 because 0 is reserved for an id
		var _found_points = 0
		for (var _in = 1 ;_in <  array_length(_coord[_i]) ;_in++ )
		{
			_found_points = point_in_polygon(_coord[_i][_in][0],_coord[_i][_in][1],_selection) ? _found_points+1 : _found_points
		}
	
		if (_found_points >= (array_length(_coord[_i])-1)/2)
		{
			array_push(_results,_coord[_i][0])
		}
		
	}
		array_resize(_selection,0)
		return _results
}

///  Returns true if the given test point is inside 
///  the given 2D polygon, false otherwise.
///
///   @param {real} x coordinates of the test point
///	  @param {real} y coordinates of the test point
///   @param {array} polygon     array of series of array coordinate pairs defining the shape of a polygon like so: [[x,y],[x,y],...]
///
///
// By XOT, modified by Delfos
function point_in_polygon(x0,y0,polygon)
{
    var inside;
    var n, i, x1, y1, x2, y2;
    inside = false;
	
    n = array_length(polygon) 

    for (i=0; i<n-1; i+=1)
    {
        x1 = polygon[i][0];
        y1 = polygon[i][1];
        x2 = polygon[i+1][0];
        y2 = polygon[i+1][1];
 
        if ((y2 > y0) != (y1 > y0)) 
        {
            inside ^= (x0 < (x1-x2) * (y0-y2) / (y1-y2) + x2);
        }       
    }
    return inside;
}