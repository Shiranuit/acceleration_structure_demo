local rects = {}

local totalRectangles = 1000000
local width, height = 800, 600
local offsetX, offsetY = totalRectangles / 20, totalRectangles / 20
local scale = 1
local mousePressed = false
local view = {
  x = 0,
  y = 0,
  w = width,
  h = height
}
local fast = false

-- Returns true if two rectangles intersect
local function rectIntersects(rect1, rect2)
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

-- Sort a list from [start] to [stop] based on the result of the comparison function
local function binarySort(list, start, stop, compare)
  local i = start
  local j = start
  while i <= stop and compare(list[i]) do
    i = i + 1
    j = j + 1
  end
  j = j + 1

  while j <= stop do
    if compare(list[j]) then
      local temp = list[i]
      list[i] = list[j]
      list[j] = temp

      i = i + 1
    end
    j = j + 1
  end

  return i-1 -- Return the index of the last element in the sorted list matching the comparison function
end

-- Draw every rectangle in the list from [start] to [stop] if they are in the view
local function draw_rects(rects, view, start, stop)
  local start = start or 1
  local stop = stop or #rects
  local rect = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
  }
  local rectCount = 0
  for i=start, stop do
    rect.x = (rects[i].x - offsetX) * scale + width/2
    rect.y = (rects[i].y - offsetY) * scale + height/2
    rect.w = rects[i].w * scale
    rect.h = rects[i].h * scale
    if (view == nil or rectIntersects(rect, view)) then
      love.graphics.setColor(rects[i].r, rects[i].g, rects[i].b)
      love.graphics.rectangle('fill', rect.x, rect.y, rect.w, rect.h)
      rectCount = rectCount + 1
    end
  end
  return rectCount
end

local function sort_region(region, rects)
  local overlapp = function(rect)
    return rectIntersects(region, rect)
  end

  return binarySort(rects, region.start, region.stop, overlapp)
end

-- Build a QuadTree for the given rects
local function build_acceleration_structure(region, rects, depth)
  -- Early stopping if we reached the maximum depth or there are to few rectangle to subdivide the region
  if depth == 0 or region.stop - region.start < 500 then
    return region
  end

  -- List of the 4 subregions for the given region
  local regions = {
    {x = region.x, y = region.y, w = region.w/2, h = region.h/2},
    {x = region.x + region.w/2, y = region.y, w = region.w/2, h = region.h/2},
    {x = region.x, y = region.y + region.h/2, w = region.w/2, h = region.h/2},
    {x = region.x + region.w/2, y = region.y + region.h/2, w = region.w/2, h = region.h/2},
  }

  -- Sort the rects in the region for each subregion
  -- This is done by sorting the rects in the region based on the overlap with the subregion
  -- Then since all rects from a region are next to each other
  -- we can define where the subregions start and stop in the list of rectangles
  regions[1].start = region.start
  regions[1].stop = region.stop
  regions[1].stop = sort_region(regions[1], rects)
  region.childs = {}
  -- If the difference between stop and start is less than 0, there are no rects in the region
  if regions[1].stop - regions[1].start >= 0 then
    region.childs[#region.childs + 1] = build_acceleration_structure(regions[1], rects, depth - 1)
  end
  for i=2, #regions do
    regions[i].start = regions[i - 1].stop + 1
    regions[i].stop = region.stop
    regions[i].stop = sort_region(regions[i], rects)
    -- If the difference between stop and start is less than 0, there are no rects in the region
    if regions[i].stop - regions[i].start >= 0 then
      region.childs[#region.childs + 1] = build_acceleration_structure(regions[i], rects, depth - 1)
    end
  end

  if #region.childs == 0 then
    return nil
  end

  return region
end

-- Iterate through all the sub regions of the quad tree and draw the rectangles
-- Returns the number of rectangles drawn
local function draw_acceleration_structure(struct, rects, view)
  -- Compute new struct coordinates in screen space
  local structOffset = {
    x = (struct.x - offsetX) * scale + width/2,
    y = (struct.y - offsetY) * scale + height/2,
    w = struct.w * scale,
    h = struct.h * scale,
  }

  if not rectIntersects(view, structOffset) then
    return 0 -- No need to draw anything, the region is not in the field of view
  end

  -- If the region contains sub regions, draw them
  if struct.childs then
    local rectCount = 0
    for i=1, #struct.childs do
      rectCount = rectCount + draw_acceleration_structure(struct.childs[i], rects, view)
    end
    return rectCount
  else
    -- Draw each rectangle in the region
    return draw_rects(rects, view, struct.start, struct.stop)
  end
  return 0
end

local accelerated_struct

function love.load()
  love.window.setMode(width, height)

  for i=1, totalRectangles do
    rects[i] = {
      x = math.random(0, totalRectangles / 10),
      y = math.random(0, totalRectangles / 10),
      w = math.random(50, 100),
      h = math.random(50, 100),
      r = math.random(0, 255)/255,
      g = math.random(0, 255)/255,
      b = math.random(0, 255)/255
    }
  end

  accelerated_struct = build_acceleration_structure({x = 0, y = 0, w = totalRectangles / 10, h = totalRectangles / 10, start=1, stop=#rects}, rects, 24)
end

-- Draws the boundaries of the accelerated structure recursively
local function draw_boundaries(struct, point, view)
  -- Compute new struct coordinates in screen space
  local structOffset = {
    x = (struct.x - offsetX) * scale + width/2,
    y = (struct.y - offsetY) * scale + height/2,
    w = struct.w * scale,
    h = struct.h * scale,
  }

  -- If the struct and the view are not overlapping, then we don't need to draw anything
  -- since everything inside the struct is not in the view
  if not rectIntersects(structOffset, view) then
    return
  end

  -- Only draw the boundaries if the point is inside the struct
  if (structOffset.x <= point.x and structOffset.y <= point.y and structOffset.x + structOffset.w >= point.x and structOffset.y + structOffset.h >= point.y) then
    if struct.childs then
      for i=1, #struct.childs do
        draw_boundaries(struct.childs[i], point, view)
      end
    end
    love.graphics.rectangle('line', structOffset.x, structOffset.y, structOffset.w, structOffset.h)
  end
end

function love.draw()

  local start = love.timer.getTime()
  love.graphics.clear()
  local rectCount = 0
  if fast then
    rectCount = draw_acceleration_structure(accelerated_struct, rects, view)
  else
    rectCount = draw_rects(rects, view)
  end
  local stop = love.timer.getTime()
  local fps = love.timer.getFPS()

  -- Draw cross at center
  love.graphics.setColor(1, 1, 1)
  love.graphics.line(width/2, height/2-20, width/2, height/2+20)
  love.graphics.line(width/2-20, height/2, width/2+20, height/2)

  -- Draw acceleration_structure boundaries that are visible and where the cursor is located
  -- local x, y = love.mouse.getPosition()
  -- love.graphics.setColor(1, 1, 1)
  -- draw_boundaries(accelerated_struct, {x = x, y = y}, view)

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('fill', 0, 0, 200, 80)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Time per frame: '..tostring(math.floor((stop-start)*10000000+0.5)/10000000)..'s', 0, 0)
  love.graphics.print('FPS: '..tostring(fps), 0, 20)
  love.graphics.print('Rects: '..tostring(rectCount), 0, 40)
  love.graphics.print('Acceleration Struct: '..(fast and 'on' or 'off'), 0, 60)
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
  print(scale, scaleFactor)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'b' then
    fast = not fast
  end
  if key == 'down' then
    love.wheelmoved(0, -1)
  elseif key == 'up' then
    love.wheelmoved(0, 1)
  end
end
