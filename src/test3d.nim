
import terminal, os, math, options, strutils
import illwill

let
  height = terminalHeight()
  width  = terminalWidth()

const LINEACC = 7



#  _   _      _                     
# | | | | ___| |_ __   ___ _ __ ___ 
# | |_| |/ _ \ | '_ \ / _ \ '__/ __|
# |  _  |  __/ | |_) |  __/ |  \__ \
# |_| |_|\___|_| .__/ \___|_|  |___/
#              |_|                  


proc `*`(c: char, n: int): string =
  for i in 0..(n-1):
    result &= c


#   ____                           _              
#  / ___| ___  ___  _ __ ___   ___| |_ _ __ _   _ 
# | |  _ / _ \/ _ \| '_ ` _ \ / _ \ __| '__| | | |
# | |_| |  __/ (_) | | | | | |  __/ |_| |  | |_| |
#  \____|\___|\___/|_| |_| |_|\___|\__|_|   \__, |
#                                           |___/ 


type Point = ref object
  x,y,z: int
  shifted: bool


proc newPoint(x,y,z: int): Point = Point(x: x, y: y, z: z, shifted: false)

type Triangle = object
  verts: array[3, Point]

proc newTriangle(a,b,c: Point): Triangle = Triangle(verts: [a,b,c])

type Cube = object
  triangles: array[12, Triangle]

type Model = object
  triangles: seq[Triangle]

proc loadModel(data: string, xs,ys,zs: int): Model =
  var
    points = newSeq[Point]()
    tris   = newSeq[Triangle]()
  for line in data.strip.splitLines():
    case line[0]:
      of 'v':
        let
          vertexes = line.split(" ")
          x = (vertexes[1].parseFloat() * 25).round.toInt + xs
          y = (vertexes[2].parseFloat() * 25).round.toInt + ys
          z = (vertexes[3].parseFloat() * 25).round.toInt + zs

        points.add( newPoint(x,y,z) )
      of 'f':
        let
          pts = line.split(" ")
          p1 = pts[1].parseInt() - 1
          p2 = pts[2].parseInt() - 1
          p3 = pts[3].parseInt() - 1

        tris.add( newTriangle( points[p1], points[p2], points[p3]) )
      else:
        discard
  return Model(triangles: tris)

proc translateModel(m: Model, x,y,z: int) =
  for t in m.triangles:
    for v in t.verts:
      if not v.shifted:
        v.x += x
        v.y += y
        v.z += z
        v.shifted = true
  for t in m.triangles:
    for v in t.verts:
      v.shifted = false

proc newCuboid(p: array[8, Point]): Cube =
  Cube(triangles: [
    newTriangle(p[0], p[1], p[2]),#1
    newTriangle(p[1], p[3], p[2]),#2
    newTriangle(p[1], p[5], p[3]),#3
    newTriangle(p[5], p[6], p[3]),#4 - 
    newTriangle(p[0], p[5], p[1]),#5 - 
    newTriangle(p[0], p[4], p[5]),#6 -
    newTriangle(p[0], p[7], p[4]),#7
    newTriangle(p[0], p[2], p[7]),#8
    newTriangle(p[3], p[7], p[2]),#9
    newTriangle(p[3], p[6], p[7]),#10
    newTriangle(p[4], p[7], p[6]),#11 -
    newTriangle(p[4], p[6], p[5]) #12 -
  ])


proc newCube(p: Point, size: int): Cube =
  newCuboid([
    #top
    newPoint(p.x     , p.y, p.z), # 1
    newPoint(p.x+size, p.y, p.z), # 2
    newPoint(p.x     , p.y, p.z+size), # 3
    newPoint(p.x+size, p.y, p.z+size),

    #bottom
    newPoint(p.x     , p.y+size, p.z),
    newPoint(p.x+size, p.y+size, p.z),
    newPoint(p.x+size, p.y+size, p.z+size), #7
    newPoint(p.x     , p.y+size, p.z+size)
  ])

proc translateCube(c: Cube, x,y,z: int) =
  for t in c.triangles:
    for v in t.verts:
      if not v.shifted:
        v.x += x
        v.y += y
        v.z += z
        v.shifted = true
  for t in c.triangles:
    for v in t.verts:
      v.shifted = false

proc rotateCube(c: Cube, theta: float) =
  var
    point1 = c.triangles[0].verts[0]
    point7 = c.triangles[3].verts[1]
    center1 = newPoint(
      ((point1.x + point7.x)/2).toInt,
      ((point1.y + point7.y)/2).toInt,
      ((point1.z + point7.z)/2).toInt)
  for t in c.triangles:
    for v in t.verts:
      if not v.shifted:
        let
          xrot = ( v.x.float * cos(theta) ) - ( v.z.float * sin(theta) )
          zrot = ( v.x.float * sin(theta) ) + ( v.z.float * cos(theta) )
        v.x = xrot.toInt
        v.z = zrot.toInt
        v.shifted = true
  
  point1 = c.triangles[0].verts[0]
  point7 = c.triangles[3].verts[1]

  let center2 = newPoint(
    ((point1.x + point7.x)/2).toInt,
    ((point1.y + point7.y)/2).toInt,
    ((point1.z + point7.z)/2).toInt)

  # reset points
  for t in c.triangles:
    for v in t.verts:
      v.shifted = false
  
  c.translateCube(center1.x-center2.x, center1.y-center2.y, center1.z-center2.z)


#   ____                 _     _          
#  / ___|_ __ __ _ _ __ | |__ (_) ___ ___ 
# | |  _| '__/ _` | '_ \| '_ \| |/ __/ __|
# | |_| | | | (_| | |_) | | | | | (__\__ \
#  \____|_|  \__,_| .__/|_| |_|_|\___|___/
#                 |_|                     

type Pixel = ref object
  loc: Point
  value: char

proc newPixel(x,y,z: int, v: char): Pixel = Pixel(loc: newPoint(x,y,z), value: v)

type Screen = ref object
  pixels: seq[Pixel]
  tBuff: TerminalBuffer

proc newScreen(): Screen =
  Screen(pixels: @[], tBuff: newTerminalBuffer(width, height))

proc occupiedRows(s: Screen): seq[int] =
  # Returns which rows have pixels on them
  for p in s.pixels:
    result.add(p.loc.y)

proc pixelsOnRow(s: Screen, n: int): seq[Pixel] =
  # returns the existing pixels on a row
  for p in s.pixels:
    if p.loc.y == n: result.add(p)

# proc `[]=`(s: Screen, w,h,z: int, c: char) =
#   s.pixels.add(newPixel(w+z,h+z, z, c))

proc toStringSeq(s: Screen): seq[string] =
  # Turn my weird screen data structure into a string
  var ret = newSeq[string]()
  let usedRows = s.occupiedRows()

  for i in 0..(height-1):
    var row = ' ' * width
    if i in usedRows:
      for p in s.pixelsOnRow(i):
        if p.loc.x < width and p.loc.x >= 0: row[p.loc.x] = p.value
    ret.add(row)

  return ret

proc `[]`(s: Screen, x,y,z: int): Option[int] =
  for i in 0..(s.pixels.len-1):
    if s.pixels[i].loc.x == x and s.pixels[i].loc.y == y and s.pixels[i].loc.z <= z:
      return some(i)

# proc drawPixel(s: Screen, x,y,z: int, c: char) =
#   # sets a point on the screen
#   let
#     az = ((z-1)/3).ceil.toInt
#     px = x + az
#     py = (y/2).round.toInt + az
#     pAlreadyThere = s[px,py,z]
#   if pAlreadyThere.isSome:
#       s.pixels[pAlreadyThere.get()] = newPixel(px,py,z,c)
#   else:
#     s.pixels.add(newPixel(px,py,z,c))

proc drawPixel(s: Screen, x,y,z: int, c: char) =
  let
    aspectRatio = width/height
    fieldOfView = 1.0 / tan(degToRad(90.0) * 0.5)*100
    zfar = -1000.0
    znear = 1000.0
    q = zfar / (zfar - znear)
    tx = (aspectRatio.float*fieldOfView*x.float)/(z.float*2)
    ty = (fieldOfView*y.float)/z.float 
    tz = (z.float*q - znear*q).float/z.float

  s.pixels.add( newPixel(tx.toInt,ty.toInt,tz.toInt, c) )


proc drawLine(s: Screen, p0,p1: Point, c: char, n: int) =
  if n == 0:
    return

  if n == LINEACC:
    s.drawPixel(p0.x, p0.y, p0.z, c)
    s.drawPixel(p1.x, p1.y, p1.z, c)

  let
    avgx = ((p0.x+p1.x)/2).round.toInt
    avgy = ((p0.y+p1.y)/2).round.toInt
    avgz = ((p0.z+p1.z)/2).round.toInt

  s.drawPixel(avgx, avgy, avgz, c)

  s.drawLine(p0, newPoint(avgx, avgy, avgz), c, n-1)
  s.drawLine(newPoint(avgx, avgy, avgz), p1, c, n-1)
                      
proc drawLine(s: Screen, p0,p1: Point, c: char) = s.drawLine(p0,p1,c,LINEACC)


proc clear(s: Screen) =
  # sets the screen to empty space
  s.pixels = newSeq[Pixel]()
  for i in 0..(height-1):
    s.tBuff.write(0, i, ' ' * width)

proc display(s: Screen) =
  # Shows the screen on the terminal
  # for p in s.pixels:
  #   s.tBuff.write(p.loc.x, p.loc.y, fmt"{p.value}")
  var h = 0
  for line in s.toStringSeq():
    s.tBuff.write(0,h, line)
    h+=1
  s.tBuff.display()

proc drawTriangle(s: Screen, t: Triangle, c: char) =
  s.drawLine(t.verts[0], t.verts[1], c)
  s.drawLine(t.verts[1], t.verts[2], c)
  s.drawLine(t.verts[2], t.verts[0], c)

  # for p in t.verts:
  #   s.drawPixel(p.x, p.y, p.z, c)

proc drawCube(s: Screen, c: Cube, v: char) =
  for t in c.triangles:
    s.drawTriangle(t, v)


proc drawModel(s: Screen, m: Model, v: char) =
  for t in m.triangles:
    s.drawTriangle(t, v)

#  __  __       _       
# |  \/  | __ _(_)_ __  
# | |\/| |/ _` | | '_ \ 
# | |  | | (_| | | | | |
# |_|  |_|\__,_|_|_| |_|
                      


let s = newScreen()

# s.tBuff.setBackgroundColor(bgBlack)
s.tBuff.setForegroundColor(illwill.ForegroundColor.fgWhite)
s.tBuff.setBackgroundColor(illwill.BackgroundColor.bgBlack)


var
  x = 0
  y = 0
  z = 0

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)



illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()

# var m = loadModel(readFile("VideoShip.obj"), 120, 80, 180)

var myCube = newCube( newPoint(60+x, 10+y, z+120),  height-2)


while true:
  s.clear()
  
  s.drawCube(myCube, '.')
  myCube.rotateCube(degToRad(5.0))
  # s.drawModel(m, '.')

  s.display()

  case getKey():
    of Key.Q:
      exitProc()
    of Key.Right:
      # m.translateModel(10,0,0)
      x+=5
    of Key.Left:
      # m.translateModel(-10,0,0)
      x-=5
    of Key.Up:
      # m.translateModel(0,-10,0)
      y-=5
    of Key.Down:
      # m.translateModel(0,10,0)
      y+=5
    of Key.A:
      # m.translateModel(0,0,-10)
      z-=5
    of Key.B:
      # m.translateModel(0,0,10)
      z+=5
    else:
      discard

  sleep(20)
