PageBarWidget = {}
local fmt = string.format

function PageBarWidget:new(name)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  return new
end

function PageBarWidget:init()
  self.canvas = widget.bindCanvas(self.widgetName)
  self.size = widget.getSize(self.widgetName)
  self.rect = {0, 0, self.size[1], self.size[2]}
  self.data = widget.getData(self.widgetName)
end

function PageBarWidget:update()
  if not self.target then return end

  local tPos, tWidth = self.target[1], self.target[2]
  local dist = math.max(math.abs(tPos - self.pos), math.abs(tWidth - self.width))
  
  if dist <= self.data.speed then
    self.pos, self.width = tPos, tWidth
    self.target = nil
  else
    self.pos = self.pos + self.data.speed * (tPos - self.pos)
    self.width = self.width + self.data.speed * (tWidth - self.width)
  end

  self.canvas:clear()
  self.canvas:drawRect(self.rect, self.data.backColor)
  self.canvas:drawRect({self.pos, 0, self.pos + self.width, self.size[2]}, self.data.color)
end

function PageBarWidget:set(value, max)
  local width = self.size[1] / max
  local pos = width * (value - 1)
  self.target = {pos, width}

  if not self.pos then
    self.pos, self.width = pos, width
  end
end
