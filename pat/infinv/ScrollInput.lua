ScrollInput = {}
local fmt = string.format

function ScrollInput:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})

  new.name = name
  new.size = widget.getSize(name)
  new.callback = callback

  new.position = {0, 0}
  new.origin = fmt("%s.origin", name)
  new.wheelTarget = fmt("%s.wheel.target", name)
  new.wheelUp = fmt("%s.wheel.up", name)

  widget.addChild(name, {type = "widget", size = {new.size[1], 1}}, "origin")
  new:createWheel()

  return new
end

function ScrollInput:createWheel()
  widget.removeChild(self.name, "wheel")
  local cfg = {
    type = "scrollArea",
    size = self.size,
    verticalScroll = false,
    children = {
      target = { type = "widget", size = {self.size[1], 1}},
      up = { type = "widget", size = {self.size[1], 1000}}
    }
  }
  widget.addChild(self.name, cfg, "wheel")
end

function ScrollInput:update(mousePos)
  if not widget.inMember(self.name, mousePos) then return end

  if not widget.inMember(self.origin, self.position) then
    self.position = self:findOrigin(mousePos)
  end

  if not widget.inMember(self.wheelTarget, self.position) then
    local up = widget.inMember(self.wheelUp, self.position)
    self.callback(up)
    self:createWheel()
  end
end

function ScrollInput:findOrigin(mousePos)
  local x, y = mousePos[1], mousePos[2]

  local find = 32
  while find > 1 do
    while widget.inMember(self.name, {x, y - find}) do
      y = y - find
    end
    find = find / 2
  end

  return {x, y}
end
