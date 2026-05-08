ScrollInputWidget = {}
local fmt = string.format

function ScrollInputWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  new.callback = callback
  return new
end

function ScrollInputWidget:init()
  self.position = {0, 0}
  self.size = widget.getSize(self.widgetName)
  
  self.origin = fmt("%s.origin", self.widgetName)
  self.wheelUp = fmt("%s.wheel.up", self.widgetName)
  self.wheelTarget = fmt("%s.wheel.target", self.widgetName)

  self.wheelConfig = {
    type = "scrollArea",
    size = self.size,
    verticalScroll = false,
    children = {
      target = { type = "widget", size = {self.size[1], 1} },
      up = { type = "widget", size = {self.size[1], 1000} }
    }
  }

  widget.removeAllChildren(self.widgetName)
  widget.addChild(self.widgetName, { type = "widget", size = {self.size[1], 1} }, "origin")
  self:createWheel()
end

function ScrollInputWidget:createWheel()
  widget.removeChild(self.widgetName, "wheel")
  widget.addChild(self.widgetName, self.wheelConfig, "wheel")
  self.active = false
end

function ScrollInputWidget:update(mousePos)
  if not widget.inMember(self.widgetName, mousePos) then return end

  if input then -- se/osb
    for _, event in ipairs(input.events()) do
      if event.type == "MouseWheel" then
        self.callback(event.data.mouseWheel > 0)
        break
      end
    end
    return
  end

  if not widget.inMember(self.origin, self.position) then
    self.position = self:findOrigin(mousePos)
  end

  if not widget.inMember(self.wheelTarget, self.position) then
    if self.active then
      local up = widget.inMember(self.wheelUp, self.position)
      self.callback(up)
    end

    self:createWheel()
  elseif not self.active then
    self.active = true
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
