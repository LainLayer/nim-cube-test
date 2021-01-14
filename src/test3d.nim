
import terminal, os, math

let
  height = terminalHeight()
  width  = terminalWidth()

const LINEACC = 6

var COUNT = 0

#  _   _      _                     
# | | | | ___| |_ __   ___ _ __ ___ 
# | |_| |/ _ \ | '_ \ / _ \ '__/ __|
# |  _  |  __/ | |_) |  __/ |  \__ \
# |_| |_|\___|_| .__/ \___|_|  |___/
#              |_|                  


proc `*`(c: char, n: int): string =
  for i in 0..(n-1):
    result &= c

proc join(s: seq[string]): string =
  for i in 0..(s.len-2):
    result &= (s[i] & "\n")
  return result & s[s.len-1]


#   ____                           _              
#  / ___| ___  ___  _ __ ___   ___| |_ _ __ _   _ 
# | |  _ / _ \/ _ \| '_ ` _ \ / _ \ __| '__| | | |
# | |_| |  __/ (_) | | | | | |  __/ |_| |  | |_| |
#  \____|\___|\___/|_| |_| |_|\___|\__|_|   \__, |
#                                           |___/ 


type Point = object
  x,y,z: int

proc samePlace(a,b: Point): bool =
  a.x == b.x and a.y == b.y


proc newPoint(x,y,z: int): Point = Point(x: x, y: y, z: z)

type Triangle = object
  verts: array[3, Point]

proc newTriangle(a,b,c: Point): Triangle = Triangle(verts: [a,b,c])

type Cube = object
  triangles: array[12, Triangle]

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

# B C 6 5 4



# Cube(triangles: [
#     newTriangle(p[0], p[1], p[2]),#1
#     newTriangle(p[2], p[1], p[3]),#2
#     newTriangle(p[1], p[5], p[3]),#3
#     newTriangle(p[5], p[6], p[3]),#4
#     newTriangle(p[0], p[5], p[1]),#5
#     newTriangle(p[0], p[4], p[5]),#6
#     newTriangle(p[0], p[7], p[4]),#7
#     newTriangle(p[0], p[2], p[7]),#8
#     newTriangle(p[3], p[7], p[2]),#9
#     newTriangle(p[3], p[6], p[7]),#10
#     newTriangle(p[6], p[4], p[7]),#11
#     newTriangle(p[6], p[5], p[4]) #12
#   ])

    # newTriangle(p[0], p[1], p[2]),#1
    # newTriangle(p[2], p[1], p[3]),#2
    # newTriangle(p[6], p[3], p[1]),#3
    # newTriangle(p[6], p[1], p[5]),#4
    # newTriangle(p[4], p[5], p[1]),#5
    # newTriangle(p[1], p[0], p[4]),#6
    # newTriangle(p[0], p[7], p[4]),#7
    # newTriangle(p[0], p[2], p[7]),#8
    # newTriangle(p[3], p[7], p[2]),#9
    # newTriangle(p[3], p[6], p[7]),#10
    # newTriangle(p[6], p[4], p[7]),#11
    # newTriangle(p[6], p[5], p[4]) #12


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
    newPoint(p.x+size, p.y+size, p.z+size),
    newPoint(p.x     , p.y+size, p.z+size)
  ])

type Vector = object
  p0,p1: Point

proc newVector(p0,p1: Point): Vector = Vector(p0: p0, p1: p1)

proc `+`(v0,v1: Vector): Vector =
  newVector(
    newPoint(v1.p0.x+v0.p0.x, v1.p0.y+v0.p0.y, v1.p0.z+v0.p0.z),
    newPoint(v1.p1.x+v0.p1.x, v1.p1.y+v0.p1.y, v1.p1.z+v0.p1.z)
  )


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

proc compareZ(a: Pixel, b: Pixel): char =
  if a.loc.z > b.loc.z:
    return a.value
  return b.value

type Screen = ref object
  pixels: seq[Pixel]

proc newScreen(): Screen = Screen(pixels: @[])

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

proc `$`(s: Screen): string =
  # Turn my weird screen data structure into a string
  var ret = newSeq[string]()
  let usedRows = s.occupiedRows()

  for i in 0..(height-1):
    var row = ' ' * width
    if i in usedRows:
      #set pixels on row
      for p in s.pixelsOnRow(i):
        if p.loc.x < width: row[p.loc.x] = p.value
    ret.add(row)

  return ret.join()

proc drawPixel(s: Screen, x,y,z: int, c: char) =
  # sets a point on the screen
  if x >= 0 and x < width and y >= 0 and y < height:
    # let
    #   por = s.pixelsOnRow(y)
    #   cpoint = newPoint(x,y,z)
    
    # for p in por:
    #   if p.loc.samePlace(cpoint):
    #     p.value = newPixel(cpoint.x, cpoint.y, cpoint.z, c).compareZ(p)
    #     return
    let
      zz = ((z-1)/3).ceil.toInt
      yy = (y/2).round.toInt
    var cc = c
    if z < COUNT:
      cc = '.'
    elif z < COUNT:
      cc = '+'
    elif z < COUNT:
      cc = '*'
    else:
      cc = '#'

    s.pixels.add(newPixel(x+zz,yy+zz,z,cc))

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
  discard execShellCmd("clear")
  s.pixels = newSeq[Pixel]()

proc display(s: Screen) =
  # Shows the screen on the terminal
  echo s

proc drawTriangle(s: Screen, t: Triangle, c: char) =
  s.drawLine(t.verts[0], t.verts[1], c)
  s.drawLine(t.verts[1], t.verts[2], c)
  s.drawLine(t.verts[2], t.verts[0], c)

  # for p in t.verts:
  #   s.drawPixel(p.x, p.y, p.z, c)

proc drawCube(s: Screen, c: Cube, v: char) =
  # var ass = @['C', 'B', 'A', '9', '8', '7', '6', '5', '4', '3', '2', '1']
  for t in c.triangles:
    s.drawTriangle(t, v)


#  __  __       _       
# |  \/  | __ _(_)_ __  
# | |\/| |/ _` | | '_ \ 
# | |  | | (_| | | | | |
# |_|  |_|\__,_|_|_| |_|
                      


let s = newScreen()

var x = 0


# let
#   cube1 = newCube(newPoint(1,1,1), 18)
#   cube2 = newCube(newPoint(18,1,1), 18)
#   cube3 = newCube(newPoint(36,1,1), 18)



while true:
  s.clear()
  s.drawCube(
    newCube( newPoint(1, 1, 0),  height-2), '.'
  )
  s.display()
  if COUNT < 80: 
    COUNT += 3
  else:
    COUNT = 0
  # discard stdin.readLine()
  sleep(100)




# s.drawCube(cube3, '.')
# s.drawCube(cube2, '.')
# s.drawCube(cube1, '.')


