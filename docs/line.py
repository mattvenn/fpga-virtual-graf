#http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Python
def get_line_1(start, end):
    """Bresenham's Line Algorithm
    Produces a list of tuples from start and end
 
    """
    # Setup initial conditions
    x1, y1 = start
    x2, y2 = end
    dx = x2 - x1
    dy = y2 - y1
 
    # Determine how steep the line is
    is_steep = abs(dy) > abs(dx)
 
    # Rotate line
    if is_steep:
        x1, y1 = y1, x1
        x2, y2 = y2, x2
 
    # Swap start and end points if necessary and store swap state
    swapped = False
    if x1 > x2:
        x1, x2 = x2, x1
        y1, y2 = y2, y1
        swapped = True
 
    # Recalculate differentials
    dx = x2 - x1
    dy = y2 - y1
 
    # Calculate error
    error = int(dx / 2.0)
    ystep = 1 if y1 < y2 else -1
 
    # Iterate over bounding box generating points between start and end
    y = y1
    points = []
    for x in range(x1, x2 + 1):
        coord = (y, x) if is_steep else (x, y)
        points.append(coord)
        error -= abs(dy)
        if error < 0:
            y += ystep
            error += dx
 
    # Reverse the list if the coordinates were swapped
    if swapped:
        points.reverse()
    return points

## integer version
def get_line(start, end):
    points = []

    # dx calc
    dx = abs(start[0] - end[0])
    dy = abs(start[1] - end[1])

    # slope calc
    if start[0] < end[0]:
        sx = 1
    else:
        sx = -1
    if start[1] < end[1]:
        sy = 1
    else:
        sy = -1

    err = dx - dy

    x = start[0]
    y = start[1]

    while True:
        points.append((x,y))
        if x == end[0] and y == end[1]:
            break

        err2 = err << 2 # left shift faster than multiply by 2

        if err2 > -dy:
            err -= dy
            x += sx

        if err2 < dx:
            err += dx
            y += sy
        
    return points



from PIL import Image, ImageDraw

w= 500
h= 500

#create an image
im = Image.new("RGB", (w,h), "white")

num = 8

y = 0
for x in range(0, w-1, w/num):
    for point in get_line((w/2,h/2), (x, y)):
        im.putpixel(point, 255)

y = h-1
for x in range(0, w-1, w/num):
    for point in get_line((w/2,h/2), (x, y)):
        im.putpixel(point, 255)

x = 0
for y in range(0, h-1, h/num):
    for point in get_line((w/2,h/2), (x, y)):
        im.putpixel(point, 255)

x = w -1 
for y in range(0, h-1, h/num):
    for point in get_line((w/2,h/2), (x, y)):
        im.putpixel(point, 255)

#save the image
im.save("lines.png", "PNG")

