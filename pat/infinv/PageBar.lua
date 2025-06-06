PageBarWidget = {}
local fmt = string.format

function PageBarWidget:new(name)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  return new
end

function PageBarWidget:init()
  self.size = widget.getSize(self.widgetName)
  self.data = widget.getData(self.widgetName)

  local img = "/assetmissing.png?crop=0;0;1;1?multiply=0000?replace;0000=%s?scalenearest=%s;%s"

  widget.addChild(self.widgetName, {
    type = "image",
    file = fmt(img, self.data.backColor, self.size[1], self.size[2])
  }, "bg")

  widget.addChild(self.widgetName, {
    type = "imageStretch",
    size = {0, 0},
    stretchSet = {
      type = "stretch",
      inner = fmt(img, self.data.color, 1, self.size[2])
    }
  }, "bar")

  self.barName = fmt("%s.bar", self.widgetName)
end

function PageBarWidget:set(value, max)
  local width = math.ceil(self.size[1] / max)
  widget.setSize(self.barName, {width, self.size[2]})

  local pos = self.size[1] * ((value - 1) / max)
  widget.setPosition(self.barName, {pos, 0})
end
