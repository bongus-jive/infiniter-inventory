SpinnerWidget = {}
local fmt = string.format

function SpinnerWidget:new(name)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  return new
end

function SpinnerWidget:init()
  self._spin = function(_, d) self:spin(d) end

  self.downButton = fmt("%s.down", self.widgetName)
  self.upButton = fmt("%s.up", self.widgetName)
  self.label = fmt("%s.label", self.widgetName)

  local data = widget.getData(self.widgetName)
  self.min = data.min
  self.max = data.max
  self:setValue(data.default or self.min)
end

function SpinnerWidget:spin(v)
  if not self.value then return end
  self:setValue(self.value + v)
end

function SpinnerWidget:setValue(value)
  self.value = math.max(math.min(value, self.max), self.min)
  widget.setText(self.label, tostring(self.value))
  widget.setButtonEnabled(self.downButton, self.value > self.min)
  widget.setButtonEnabled(self.upButton, self.value < self.max)
end
