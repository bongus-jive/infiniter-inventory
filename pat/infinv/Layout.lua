AutoLayout = {}

local DEFAULT_WIDTH = 250
local DEFAULT_HEIGHT = 166
local TEST_WIDGET = "_AutoLayout"
local BACKGROUNDS = { "gui.pane.fileHeader", "gui.pane.fileBody", "gui.pane.fileFooter" }

function AutoLayout:init()
  if widget.getData(TEST_WIDGET) then return end
  pane.addWidget({ type = "widget", data = true }, TEST_WIDGET)

  local w, h = 0, 0
  for _, part in ipairs(BACKGROUNDS) do
    local img = config.getParameter(part)
    if img and img:len() > 0 then
      local size = root.imageSize(img)
      w = math.max(w, size[1])
      h = h + size[2]
    end
  end

  self.xOffset = w - DEFAULT_WIDTH
  self.yOffset = h - DEFAULT_HEIGHT

  local cfg = config.getParameter("autoLayout", {})
  for widgetName, modes in pairs(cfg) do
    self:apply(widgetName, modes)
  end
end

function AutoLayout:apply(widgetName, modes)
  if #modes == 0 then return end

  local pos = widget.getPosition(widgetName)
  local size = widget.getSize(widgetName)

  if not (pos or size) then
    sb.logWarn("InfiniterInventory Layout: no widget '%s'", widgetName)
    return
  end

  for _, mode in ipairs(modes) do
    if mode == "x" then
      pos[1] = pos[1] + self.xOffset
    elseif mode == "y" then
      pos[2] = pos[2] + self.yOffset
    elseif mode == "h" then
      size[1] = size[1] + self.xOffset
    elseif mode == "v" then
      size[2] = size[2] + self.yOffset
    elseif mode == "x_center" then
      pos[1] = pos[1] + (self.xOffset / 2)
    elseif mode == "y_center" then
      pos[1] = pos[1] + (self.xOffset / 2)
    else
      sb.logWarn("InfiniterInventory Layout: no mode '%s'", mode)
    end
  end

  widget.setPosition(widgetName, pos)
  widget.setSize(widgetName, size)
end
