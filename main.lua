local rects = {}

local width, height = 800, 600
local offsetX, offsetY = 500000, 500000
local scale = 1
local mousePressed = false
local view = {
  x = 0,
  y = 0,
  w = width,
  h = height
}
local fast = false

local function rectOverlap(rect1, rect2)
  if  rect1.x == rect2.x
    or rect1.y == rect2.y
    or rect1.x + rect1.w == rect2.x + rect2.w
    or rect1.y + rect1.h == rect2.y + rect2.h
  then
    return false
  end

  if rect1.x > rect2.x + rect2.w or rect2.x > rect1.x + rect1.w then
    return false
  end

  if rect1.y > rect2.y + rect2.h or rect2.y > rect1.y + rect1.h then
    return false
  end

  return true
end

local function draw_rects(rects, view)
  local rect = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
  }
  local rectCount = 0
  for i=1, #rects do
    rect.x = (rects[i].x - offsetX) * scale + width/2
    rect.y = (rects[i].y - offsetY) * scale + height/2
    rect.w = rects[i].w * scale
    rect.h = rects[i].h * scale
    if (view == nil or rectOverlap(rect, view)) then
      love.graphics.setColor(rects[i].r, rects[i].g, rects[i].b)
      love.graphics.rectangle('fill', rect.x, rect.y, rect.w, rect.h)
      rectCount = rectCount + 1
    end
  end
  return rectCount
end

local function build_acceleration_structure(quad, rects, depth)
  local _rects = {}
  for i=1, #rects do
    if rectOverlap(quad, rects[i]) then
      _rects[#_rects + 1] = rects[i]
    end
  end

  if depth == 0 then
    if #_rects == 0 then
      return nil
    end

    quad.rects = _rects
    return quad
  end

  local childs = {
    build_acceleration_structure({x = quad.x, y = quad.y, w = quad.w/2, h = quad.h/2}, _rects, depth - 1),
    build_acceleration_structure({x = quad.x + quad.w/2, y = quad.y, w = quad.w/2, h = quad.h/2}, _rects, depth - 1),
    build_acceleration_structure({x = quad.x, y = quad.y + quad.h/2, w = quad.w/2, h = quad.h/2}, _rects, depth - 1),
    build_acceleration_structure({x = quad.x + quad.w/2, y = quad.y + quad.h/2, w = quad.w/2, h = quad.h/2}, _rects, depth - 1)
  }

  quad.childs = {}
  for i=1, 4 do
    if childs[i] ~= nil then
      quad.childs[#quad.childs + 1] = childs[i]
    end
  end
  
  if #quad.childs == 0 then
    return nil
  end

  return quad
end

local function draw_acceleration_structure(struct, view)
  local structOffset = {
    x = (struct.x - offsetX) * scale + width/2,
    y = (struct.y - offsetY) * scale + height/2,
    w = struct.w * scale,
    h = struct.h * scale,
  }

  if not rectOverlap(view, structOffset) then
    return 0
  end

  if struct.childs then
    local rectCount = 0
    for i=1, #struct.childs do
      rectCount = rectCount + draw_acceleration_structure(struct.childs[i], view)
    end
    return rectCount
  elseif struct.rects then
    return draw_rects(struct.rects, view)
  end
  return 0
end

local accelerated_struct

function love.load()
  love.window.setMode(width, height)

  for i=1, 10000000 do
    rects[i] = {
      x = math.random(0, 1000000),
      y = math.random(0, 1000000),
      w = math.random(50, 100),
      h = math.random(50, 100),
      r = math.random(0, 255)/255,
      g = math.random(0, 255)/255,
      b = math.random(0, 255)/255
    }
  end

  accelerated_struct = build_acceleration_structure({x = 0, y = 0, w = 1000000, h = 1000000}, rects, 8)
end

function love.draw()

  local start = love.timer.getTime()
  love.graphics.clear()
  local rectCount = 0
  if fast then
    rectCount = draw_acceleration_structure(accelerated_struct, view)
  else
    rectCount = draw_rects(rects, view)
  end
  local stop = love.timer.getTime()
  local fps = love.timer.getFPS()

  love.graphics.setColor(1, 1, 1)
  love.graphics.line(width/2, height/2-20, width/2, height/2+20)
  love.graphics.line(width/2-20, height/2, width/2+20, height/2)

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('fill', 0, 0, 100, 60)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Time: '..tostring(math.floor((stop-start)*10000+0.5)/10000)..'s', 0, 0)
  love.graphics.print('FPS: '..tostring(fps), 0, 20)
  love.graphics.print('Rects: '..tostring(rectCount), 0, 40)
end


function love.mousepressed(x, y, button)
  mousePressed = true
end

function love.mousereleased(x, y, button)
  mousePressed = false
end

function love.mousemoved(x, y, dx, dy)
  if mousePressed then
    offsetX = offsetX - dx/scale 
    offsetY = offsetY - dy/scale
  end
end

local scaleFactor = 1
function love.wheelmoved( dx, dy )
  local dir = dy > 0 and 1 or -1
  local newScale = scale + dir * scaleFactor

  if dy > 0 and newScale >= scaleFactor*10 then
    scaleFactor = 10 ^ (math.log10(scaleFactor) + 1)
  elseif dy < 0 and newScale <= scaleFactor then
    scaleFactor = 10 ^ (math.log10(scaleFactor) - 1)
  end
  
  scale = scale + scaleFactor * dir
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'b' then
    fast = not fast
  end
end