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

    for (i=0; i<n; i+=1)
    {
        x1 = polygon[i].x;
        y1 = polygon[i].y;
        x2 = polygon[(i+1)%n].x;
        y2 = polygon[(i+1)%n].y;
 
        if ((y2 > y0) != (y1 > y0)) 
        {
            inside ^= (x0 < (x1-x2) * (y0-y2) / (y1-y2) + x2);
        }       
    }
    return inside;
}