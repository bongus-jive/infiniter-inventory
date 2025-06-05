ScrollInputWidget = {}
local fmt = string.format

function ScrollInputWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  new.callback = callback
  return new
end

function ScrollInputWidget:init(name, callback)
  self.position = {0, 0}
  self.size = widget.getSize(self.widgetName)
  
  self.origin = fmt("%s.origin", self.widgetName)
  self.wheelUp = fmt("%s.wheel.up", self.widgetName)
  self.wheelTarget = fmt("%s.wheel.target", self.widgetName)

  widget.addChild(self.widgetName, {type = "widget", size = {self.size[1], 1}}, "origin")
  self:createWheel()
end

function ScrollInputWidget:createWheel()
  widget.removeChild(self.widgetName, "wheel")
  local cfg = {
    type = "scrollArea",
    size = self.size,
    verticalScroll = false,
    children = {
      target = { type = "widget", size = {self.size[1], 1}},
      up = { type = "widget", size = {self.size[1], 1000}}
    }
  }
  widget.addChild(self.widgetName, cfg, "wheel")
end

function ScrollInputWidget:update(mousePos)
  if not widget.inMember(self.widgetName, mousePos) then return end

  if not widget.inMember(self.origin, self.position) then
    self.position = self:findOrigin(mousePos)
  end

  if not widget.inMember(self.wheelTarget, self.position) then
    local up = widget.inMember(self.wheelUp, self.position)
    self.callback(up)
    self:createWheel()
  end
end

function ScrollInputWidget:findOrigin(mousePos)
  local x, y = mousePos[1], mousePos[2]

  local find = 32
  while find > 1 do
    while widget.inMember(self.widgetName, {x, y - find}) do
      y = y - find
    end
    find = find / 2
  end

  return {x, y}
end
