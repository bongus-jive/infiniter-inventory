OptionSpinnerWidget = {}
local fmt = string.format

function OptionSpinnerWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  new.callback = callback
  return new
end

function OptionSpinnerWidget:init()
  self.data = widget.getData(self.widgetName) or {}

  for name, cfg in pairs(self.data.children or {}) do
    widget.addChild(self.widgetName, cfg, name)
  end

  self.options = self.data.options
  if type(self.options) == "string" then
    self.options = root.assetJson(self.options)
  end
  self.index = 1
  self.maxIndex = #self.options

  self.up = function() self:spin(1) end
  self.down = function() self:spin(-1) end
end

function OptionSpinnerWidget:spin(offset)
  local index = ((self.index + offset - 1) % self.maxIndex) + 1
  self:set(index)
end

function OptionSpinnerWidget:set(index)
  self.index = math.max(1, math.min(index or 1, self.maxIndex))
  self.callback(self.index, self.options[self.index])
end
