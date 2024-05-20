          
/// Calculates the angle of a chord in an ellipse given one endpoint and the chord length

/// @param {Real} x1 x-coordinate of the known endpoint
/// @param {Real} y1 y-coordinate of the known endpoint
/// @param {Real} chordLength length of the chord
/// @param {Real} ellipseCenterX x-coordinate of the center of the ellipse
/// @param {Real} ellipseCenterY y-coordinate of the center of the ellipse
/// @param {Real} ellipseSemiMajorAxis length of the semi-major axis of the ellipse
/// @param {Real} ellipseSemiMinorAxis length of the semi-minor axis of the ellipse      
/// @return {Real} 
function calculateChordAngle(x1,y1,chordLength,ellipseCenterX,ellipseCenterY,ellipseSemiMajorAxis,ellipseSemiMinorAxis){


// Step 1: Find the Equation of the Chord
var m = 0; // slope of the chord
if (ellipseSemiMajorAxis != 0) {
    m = -ellipseSemiMinorAxis / ellipseSemiMajorAxis; // slope of the major axis
}

// Step 2: Determine the Second Endpoint

var dx = chordLength / (2*sqrt(1 + m*m));
var dy = m * dx;
/*
var dx = chordLength / (2 * ellipseSemiMajorAxis);
var dy = sqrt(chordLength*chordLength - dx*dx); // Pythagorean theorem*/
// Two possible endpoints
var x2_1 = x1 + dx;
var y2_1 = y1 + dy;
var x2_2 = x1 - dx;
var y2_2 = y1 - dy;

// Step 3: Intersect the Line with the Ellipse
// For simplicity, let's consider only one possible endpoint
var a = ellipseSemiMajorAxis;
var b = ellipseSemiMinorAxis;
var x0 = x2_1;
var y0 = y2_1;

var ellipseEquation = sqr((x0 - ellipseCenterX) / a) + sqr((y0 - ellipseCenterY) / b);
if (ellipseEquation <= 1) {
    // The point (x2_1, y2_1) is on the ellipse
    var x2 = x2_1;
    var y2 = y2_1;
} else {
    // The point (x2_2, y2_2) is on the ellipse
    var x2 = x2_2;
    var y2 = y2_2;
}

// Step 4: Calculate the Slope of the Chord
var m_chord = (y2 - y1) / (x2 - x1);

// Step 5: Find the Angle of the Chord with the X-Axis
var theta = darctan(m_chord);

// Step 6: Adjust the Angle for the Ellipse's Orientation (if needed)

return theta;

}