local love = love
local lg = love.graphics

---Returns the rectangle that is the intersection of two rectangles
---@param x1 number
---@param y1 number
---@param w1 number
---@param h1 number
---@param x2 number
---@param y2 number
---@param w2 number
---@param h2 number
---@return number, number, number, number
local function rectangleIntersection(x1, y1, w1, h1, x2, y2, w2, h2)
  local x = math.max(x1, x2)
  local y = math.max(y1, y2)
  local x6 = math.min(x1 + w1, x2 + w2)
  local y6 = math.min(y1 + h1, y2 + h2)
  return x, y, x6 - x, y6 - y
end

---Sets the scissor with `w` and `h` clamped in case they're less than 0.
---@param x number
---@param y number
---@param w number
---@param h number
local function setScissorClamped(x, y, w, h)
  lg.setScissor(x, y, math.max(w, 0), math.max(h, 0))
end

---@type number[]
local scissorStack = {}

---Pushes this scissor to the stack, and sets the actual scissor to the intersection with the last pushed scissor.
---@param x number
---@param y number
---@param w number
---@param h number
local function pushScissor(x, y, w, h)
  local lastX = scissorStack[#scissorStack - 3]
  local lastY = scissorStack[#scissorStack - 2]
  local lastW = scissorStack[#scissorStack - 1]
  local lastH = scissorStack[#scissorStack]
  if lastX then
    x, y, w, h = rectangleIntersection(lastX, lastY, lastW, lastH, x, y, w, h)
  end
  table.insert(scissorStack, x)
  table.insert(scissorStack, y)
  table.insert(scissorStack, w)
  table.insert(scissorStack, h)
  setScissorClamped(x, y, w, h)
end

local function popScissor()
  assert(#scissorStack > 0, "attempt to pop a scissor when none were pushed")
  for _ = 1, 4 do
    table.remove(scissorStack)
  end

  local lastX = scissorStack[#scissorStack - 3]
  local lastY = scissorStack[#scissorStack - 2]
  local lastW = scissorStack[#scissorStack - 1]
  local lastH = scissorStack[#scissorStack]

  if lastX then
    setScissorClamped(lastX, lastY, lastW, lastH)
  else
    lg.setScissor()
  end
end

return {
  pushScissor = pushScissor,
  popScissor = popScissor
}
