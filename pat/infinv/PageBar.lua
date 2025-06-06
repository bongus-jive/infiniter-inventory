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
  self.data = widget.getData(self.widgetName)
end

function PageBarWidget:set(value, max)
  local pos = self.size[1] * (value - 1) / max
  local width = math.ceil(self.size[1] / max)

  self.canvas:clear()
  self.canvas:drawRect({0, 0, self.size[1], self.size[2]}, self.data.backColor)
  self.canvas:drawRect({pos, 0, pos + width, self.size[2]}, self.data.color)
end
