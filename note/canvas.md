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

# Canvas fill rules
"nonzero": The non-zero winding rule, which is the default rule.
"evenodd": The even-odd winding rule.

# Drawing text
fillText(text, x, y [, maxWidth])
    Fills a given text at the given (x,y) position. Optionally with a maximum width to draw.
strokeText(text, x, y [, maxWidth])
    Strokes a given text at the given (x,y) position. Optionally with a maximum width to draw.

# Styling text
font = value
    The current text style being used when drawing text. This string uses the same syntax as the CSS font property. The default font is 10px sans-serif.
textAlign = value
    Text alignment setting. Possible values: start, end, left, right or center. The default value is start.
textBaseline = value
    Baseline alignment setting. Possible values: top, hanging, middle, alphabetic, ideographic, bottom. The default value is alphabetic.
direction = value
    Directionality. Possible values: ltr, rtl, inherit. The default value is inherit.

# drawing image
[](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Using_images#Getting_images_to_draw)
drawImage(image, x, y)
    Draws the CanvasImageSource specified by the image parameter at the coordinates (x, y).
## Scaling
drawImage(image, x, y, width, height)
## Slicing
drawImage(image, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)

# Saving and restoring state
save the drawing state and transform
save()
    Saves the entire state of the canvas.
restore()
    Restores the most recently saved canvas state.

# transform
translate(x, y)
    Moves the canvas and its origin on the grid. x indicates the horizontal distance to move, and y indicates how far to move the grid vertically.
rotate(angle)
    Rotates the canvas clockwise around the current origin by the angle number of radians.
scale(x, y)
    Scales the canvas units by x horizontally and by y vertically. Both parameters are real numbers. Values that are smaller than 1.0 reduce the unit size and values above 1.0 increase the unit size. Values of 1.0 leave the units the same size.
transform(a, b, c, d, e, f)
    Multiplies the current transformation matrix with the matrix described by its arguments.
    [a c e]
    [b d f]
    [0 0 1]
setTransform(a, b, c, d, e, f)
    Resets the current transform to the identity matrix, and then invokes the transform() method with the same arguments. This basically undoes the current transformation, then sets the specified transform, all in one step.
resetTransform()
    Resets the current transform to the identity matrix. This is the same as calling: ctx.setTransform(1, 0, 0, 1, 0, 0);
# Compositing and clipping

# Pixel manipulation with canvas
## The ImageData object
width
    The width of the image in pixels.
height
    The height of the image in pixels.
data
    A Uint8ClampedArray representing a one-dimensional array containing the data in the RGBA order, with integer values between 0 and 255 (included).
Creating an ImageData object
    var myImageData = ctx.createImageData(width, height);
Getting the pixel data for a context
    var myImageData = ctx.getImageData(left, top, width, height);
Painting pixel data into a context
    ctx.putImageData(myImageData, dx, dy);

# Saving images
canvas.toDataURL('image/png')
    Default setting. Creates a PNG image.
canvas.toDataURL('image/jpeg', quality)
    Creates a JPG image. Optionally, you can provide a quality in the range from 0 to 1, with one being the best quality and with 0 almost not recognizable but small in file size.

# Optimizing canvas
[](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Optimizing_canvas)
*   Pre-render similar primitives or repeating objects on an off-screen canvas
*   Avoid floating-point coordinates and use integers instead
*   Don’t scale images in drawImage
*   Use multiple layered canvases for complex scenes.
*   CSS for large background images
*   Scaling canvas using CSS transforms
*   Test performance with [JSPerf].
