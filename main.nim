import sdl2, random, sequtils, os

let breite: int = 500
let hoehe: int = 500

type
  SDLException = object of Exception

  Input {.pure.} = enum space, quit,r, none

  State = ref object
    inputs: array[Input, bool]
    renderer: RendererPtr

template sdlFailIf(cond: typed, reason: string) = 
  if cond: raise SDLException.newException(reason & ", SDL error: " & $getError())

proc toInput(key: Scancode): Input =
  case key
  of SDL_SCANCODE_Q: Input.quit
  of SDL_SCANCODE_SPACE: Input.space
  of SDL_SCANCODE_R: Input.r
  else: Input.none
proc newState(renderer: RendererPtr): State = 
  new result
  result.renderer = renderer
proc handleInput(state: State) = 
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      state.inputs[Input.quit] = true
    of KeyDown:
      state.inputs[event.key.keysym.scancode.toInput] = true
    of KeyUp:
      state.inputs[event.key.keysym.scancode.toInput] = false
    else:
      discard
proc draw(renderer: RendererPtr, x,y,r,g,b: int) =
  var nx, ny: cint
  var nr,ng,nb: uint8
  if x < 0: nx = 0
  elif x > breite-1: nx = breite.cint-1
  else: nx = cint(x)

  if y < 0: ny = 0
  elif y > hoehe-1: ny = hoehe.cint-1
  else: ny = cint(y)

  if r > 255: nr = 255
  else: nr = r.uint8
  if g > 255: ng = 255
  else: ng = ng.uint8
  if b > 255: nb = 255
  else: nb = nb.uint8

  renderer.setDrawColor(r=r.uint8,g=g.uint8,b=b.uint8)
  renderer.drawPoint(nx,ny)
proc clean(renderer: RendererPtr) =
  renderer.setDrawColor(0,0,0)
  renderer.clear()

proc mymod(x,y: int): int =
  result = (x+y) 
  result = result mod y

proc seed(map: var seq[seq[bool]]) =
  var x,y: int
  x = random(breite-1)
  y = random(hoehe-1)
  map[x][y] = true

proc getNeighbors(map: seq[seq[bool]], x:int,y:int):int = 
  result = 0
  for i in x-1..x+1:
    for j in y-1..y+1:
      if map[mymod(i,breite)][mymod(j,hoehe)]:
        result += 1
  if map[mymod(x,breite)][mymod(y,hoehe)]:
    result -= 1
proc toggle(b: var bool) =
  if b:
    b = false
  else:
    b = true
  

randomize()
sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)): "SDL INIT FAILED"
sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY","2")): "Linear texture filter not enabled"
let window = createWindow(title = "Game Of Life", x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED, w = breite.cint, h = hoehe.cint, flags = SDL_WINDOW_SHOWN)
sdlFailIf(window.isNil): "Window not created"
let renderer = window.createRenderer(index = -1, flags = Renderer_Accelerated or Renderer_PresentVsync)
sdlFailIf(renderer.isNil): "Renderer not created"

#Main Variables
var
  state = newState(renderer)
  pause: bool = false
  map = newSeqWith(breite, newSeq[bool](hoehe))
  map2 = map

for i in 1..breite*hoehe:
  map.seed()

while not state.inputs[Input.quit]:
  if state.inputs[Input.space]:
    pause.toggle()
    os.sleep(200)
  if state.inputs[Input.r]:
    map = newSeqWith(breite, newSeq[bool](hoehe))
    for i in 1..breite*hoehe:
      map.seed()
  map2 = map
  if not pause:
    for x in 0..breite-1:
      for y in 0..hoehe-1:
        var n= map.getNeighbors(x,y)
        if n < 2:
          map2[x][y] = false
        elif n > 3:
          map2[x][y] = false
        elif n == 3:
          map2[x][y] = true 
  map = map2


  state.renderer.clean()
  for x in 0..breite-1:
    for y in 0..hoehe-1:
      if map[x][y]:
        renderer.draw(x,y,255,255,255)


  state.handleInput()
  state.renderer.present()
