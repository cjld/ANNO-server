# Fallback content
Providing fallback content is very straightforward: just insert the alternate content inside the <canvas> element.

# drawing rectangle
fillRect(x, y, width, height)
    Draws a filled rectangle.
strokeRect(x, y, width, height)
    Draws a rectangular outline.
clearRect(x, y, width, height)
    Clears the specified rectangular area, making it fully transparent.

# drawing path
beginPath()
    Creates a new path. Once created, future drawing commands are directed into the path and used to build the path up.
Path methods
    Methods to set different paths for objects.
closePath()
    Closes the path so that future drawing commands are once again directed to the context.
stroke()
    Draws the shape by stroking its outline.
fill()
    Draws a solid shape by filling the path's content area.
moveTo(x, y)
    Moves the pen to the coordinates specified by x and y.
lineTo(x, y)
    Draws a line from the current drawing position to the position specified by x and y.
arc(x, y, radius, startAngle, endAngle, anticlockwise)
    Draws an arc which is centered at (x, y) position with radius r starting at startAngle and ending at endAngle going in the given direction indicated by anticlockwise (defaulting to clockwise).
arcTo(x1, y1, x2, y2, radius)
    Draws an arc with the given control points and radius, connected to the previous point by a straight line.

# Bezier and quadratic curves

# Path2D objects
Path2D.addPath(path [, transform])
    Adds a path to the current path with an optional transformation matrix.

# Colors
fillStyle = color
    Sets the style used when filling shapes.
strokeStyle = color
    Sets the style for shapes' outlines.

# line style
lineWidth = value
    Sets the width of lines drawn in the future.
lineCap = type
    Sets the appearance of the ends of lines.
lineJoin = type
    Sets the appearance of the "corners" where lines meet.
miterLimit = value
    Establishes a limit on the miter when two lines join at a sharp angle, to let you control how thick the junction becomes.
getLineDash()
    Returns the current line dash pattern array containing an even number of non-negative numbers.
setLineDash(segments)
    Sets the current line dash pattern.
lineDashOffset = value
    Specifies where to start a dash array on a line.

# Gradients
createLinearGradient(x1, y1, x2, y2)
    Creates a linear gradient object with a starting point of (x1, y1) and an end point of (x2, y2).
createRadialGradient(x1, y1, r1, x2, y2, r2)
    Creates a radial gradient. The parameters represent two circles, one with its center at (x1, y1) and a radius of r1, and the other with its center at (x2, y2) with a radius of r2.
gradient.addColorStop(position, color)
    Creates a new color stop on the gradient object. The position is a number between 0.0 and 1.0 and defines the relative position of the color in the gradient, and the color argument must be a string representing a CSS <color>, indicating the color the gradient should reach at that offset into the transition.

# pattern
createPattern(image, type)
    Creates and returns a new canvas pattern object. image is a CanvasImageSource (that is, an HTMLImageElement, another canvas, a <video> element, or the like. type is a string indicating how to use the image.
