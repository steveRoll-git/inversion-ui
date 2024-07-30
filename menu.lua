local love = love
local lg = love.graphics

local pushScissor = require "lib.scissorStack".pushScissor
local popScissor = require "lib.scissorStack".popScissor

local quad = lg.newQuad(0, 0, 0, 0, 0, 0)

---@param x number
---@param y number
---@param w number
---@param h number
---@param sw number
---@param sh number
---@return love.Quad
local function newQuad(x, y, w, h, sw, sh)
  quad:setViewport(x, y, w, h, sw, sh)
  return quad
end

---@param a number
---@param b number
---@param t number
---@return number
local function lerp(a, b, t)
  return a + (b - a) * t
end

local flux = require "lib.flux"

local invertShader = lg.newShader [[
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
  vec4 p = Texel(texture, tc);
  return vec4(1 - p.r, 1 - p.g, 1 - p.b, p.a) * color;
}
]]

---@class MenuData
---@field title string
---@field items? MenuData[]

---@class Menu
---@field data MenuData
---@field selection number

local font = lg.newFont("Inter-Regular.ttf", 18)

local itemsCanvas = lg.newCanvas()

local menuTransitionDuration = 0.3

---@class MenuState
local MenuState = {}

---@param previous any
---@param menuData MenuData
function MenuState:enter(previous, menuData)
  self.tweens = flux.group()

  ---@type Menu[]
  self.stack = {
    {
      data = menuData,
      selection = 1
    }
  }

  self.selectionOffset = 0

  self.sliceCanvas = lg.newCanvas()
end

function MenuState:topMenu()
  return self.stack[#self.stack]
end

---@param menu Menu
---@param alpha number
function MenuState:drawMenuItems(menu, alpha)
  local isPreLast = menu == self.stack[#self.stack - 1]

  lg.push()
  lg.origin()
  local prev = lg.getCanvas()
  local px, py, pw, ph = lg.getScissor()
  lg.setScissor()
  lg.setCanvas(itemsCanvas)
  lg.clear(0, 0, 0, 1)

  for i, option in ipairs(menu.data.items) do
    lg.setColor(1, 1, 1, alpha)
    if self.expandAnim and isPreLast and i == menu.selection then
      lg.print(
        option.title,
        lerp(0, lg.getWidth() / 2 - font:getWidth(option.title) / 2, self.expandAnim),
        (i - 1) * font:getHeight())
    else
      lg.print(option.title, 0, (i - 1) * font:getHeight())
    end
  end

  lg.setCanvas(prev)
  lg.setScissor(px, py, pw, ph)
  lg.pop()

  lg.draw(itemsCanvas)

  local sx, sy = lg.transformPoint(0, (menu.selection - 1) * font:getHeight() + (self.selectionOffset or 0))
  pushScissor(sx, sy, lg.getWidth(), font:getHeight())
  lg.setShader(invertShader)
  lg.setColor(1, 1, 1, (isPreLast and (1 - self.expandAnim) ^ 4 or 1) * alpha)
  lg.draw(itemsCanvas)
  lg.setShader()
  popScissor()
end

---@param menu Menu
function MenuState:drawMenu(menu)
  lg.setFont(font)
  lg.setColor(1, 1, 1)
  lg.printf(menu.data.title, 0, 0, lg.getWidth(), "center")

  lg.push()
  lg.translate(0, font:getHeight())
  self:drawMenuItems(menu, 1)
  lg.pop()

  lg.setLineStyle("smooth")
  lg.setLineWidth(0.5)
  lg.setColor(1, 1, 1)
  local y = font:getHeight() - 0.5
  lg.line(0, y, lg.getWidth(), y)
end

function MenuState:enterMenu()
  self.selectionOffset = 0

  local menu = self:topMenu()

  self.expandAnim = 0
  self.tweens:to(self, menuTransitionDuration, { expandAnim = 1 })
      :ease("quadinout")
      :oncomplete(function()
        self.expandAnim = nil
      end)
  table.insert(self.stack, {
    data = menu.data.items[menu.selection],
    selection = 1,
  })
end

function MenuState:update(dt)
  self.tweens:update(dt)
end

function MenuState:keypressed(_, sc)
  local menu = self:topMenu()
  local prevIndex = menu.selection
  if sc == "up" then
    menu.selection = menu.selection - 1
    if menu.selection < 1 then
      menu.selection = #menu.data.items
    end
    self.selectionOffset = (prevIndex - menu.selection) * font:getHeight()
    self.tweens:to(self, 0.1, { selectionOffset = 0 })
  elseif sc == "down" then
    menu.selection = menu.selection + 1
    if menu.selection > #menu.data.items then
      menu.selection = 1
    end
    self.selectionOffset = (prevIndex - menu.selection) * font:getHeight()
    self.tweens:to(self, 0.1, { selectionOffset = 0 })
  elseif sc == "z" and menu.data.items[menu.selection].items then
    self:enterMenu()
  elseif sc == "escape" and #self.stack > 1 then
    self.expandAnim = 1
    self.tweens:to(self, menuTransitionDuration, { expandAnim = 0 })
        :ease("quadinout")
        :oncomplete(function()
          self.expandAnim = nil
          table.remove(self.stack)
        end)
  end
end

function MenuState:draw()
  if self.expandAnim then
    local nextMenu = self:topMenu()
    local prevMenu = self.stack[#self.stack - 1]

    lg.setCanvas(self.sliceCanvas)
    lg.clear()
    self:drawMenu(prevMenu)
    lg.setCanvas()

    local splitY = (prevMenu.selection + 1) * font:getHeight()

    lg.setBlendMode("alpha", "premultiplied")
    lg.draw(
      self.sliceCanvas,
      newQuad(
        0, 0,
        lg.getWidth(), splitY,
        lg.getDimensions()),
      0,
      lerp(0, -splitY + font:getHeight(), self.expandAnim))
    local c = 1 - self.expandAnim ^ 4
    lg.setColor(c, c, c)
    lg.draw(
      self.sliceCanvas,
      newQuad(
        0, splitY,
        lg.getWidth(), lg.getHeight() - splitY,
        lg.getDimensions()),
      0,
      lerp(splitY, (#nextMenu.data.items + 1) * font:getHeight(), self.expandAnim))
    lg.setBlendMode("alpha")

    lg.push()
    local newY = lerp(splitY, font:getHeight(), self.expandAnim)
    lg.translate(0, newY)
    pushScissor(0, newY, lg.getWidth(), lerp(0, #nextMenu.data.items * font:getHeight(), self.expandAnim))
    lg.setColor(1, 1, 1)
    self:drawMenuItems(nextMenu, 1)
    popScissor()
    lg.pop()

    lg.setLineStyle("smooth")
    lg.setLineWidth(0.5)
    lg.setColor(1, 1, 1, self.expandAnim)
    lg.line(0, newY, lg.getWidth(), newY)
  else
    self:drawMenu(self:topMenu())
  end
end

return MenuState
