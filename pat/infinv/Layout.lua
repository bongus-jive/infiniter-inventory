AutoLayout = {}

local fmt = string.format
local TEST_WIDGET = "_AutoLayout"

function AutoLayout:setSize(width, height)
  local cfg = config.getParameter("autoLayout")

  local current = widget.getData(TEST_WIDGET) or cfg.defaultSize
  if width == current[1] and height == current[2] then return end

  local img = cfg.resizeImage .. "?scalenearest=%s;%s"
  
  local layout = { type = "layout", layoutType = "basic", data = { width, height }, children = { } }
  layout.children.bg = {
    type = "background",
    fileHeader = fmt(img, width, cfg.headerHeight),
    fileFooter = fmt(img, width, cfg.footerHeight),
    fileBody = fmt(img, width, height - cfg.headerHeight - cfg.footerHeight)
  }

  pane.removeWidget(TEST_WIDGET)
  pane.addWidget(layout, TEST_WIDGET)

  self.xOffset = width - current[1]
  self.yOffset = height - current[2]
  for widgetName, modes in pairs(cfg.widgets) do
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
