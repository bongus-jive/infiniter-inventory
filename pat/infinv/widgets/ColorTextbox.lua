ColorTextboxWidget = {}

function ColorTextboxWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  new.callback = callback
  return new
end

function ColorTextboxWidget:init()
  self.data = widget.getData(self.widgetName)
  self._input = function() self:input() end
end

function ColorTextboxWidget:setText(text)
  widget.setText(self.widgetName, text or "")
end

function ColorTextboxWidget:input()
  if not widget.hasFocus(self.widgetName) then return end

  local text = widget.getText(self.widgetName)
  local len = text:len()

  if len == 0 then
    self.callback(nil)
  elseif len == 3 or len == 4 or len == 6 or len == 8 then
    self.callback(text)
  end
end
