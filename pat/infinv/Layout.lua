AutoLayout = {}

local fmt = string.format
local TEST_WIDGET = "_AutoLayout"

function AutoLayout:init()
  self.config = config.getParameter("autoLayout")
end

function AutoLayout:setGridDimensions(dims)
  local w = self.config.baseSize[1] + (dims[1] * self.config.gridItemSize[1])
  local h = self.config.baseSize[2] + (dims[2] * self.config.gridItemSize[2])
  self:setSize(w, h)
end

function AutoLayout:setSize(width, height)
  local cfg = self.config

  local current = widget.getData(TEST_WIDGET) or cfg.defaultSize
  if width == current[1] and height == current[2] then return end

  width = math.max(width, cfg.defaultSize[1])
  height = math.max(height, cfg.defaultSize[2])

  self.lastSize = current
  self.size = { width, height }
  self.xOffset = width - current[1]
  self.yOffset = height - current[2]

  local img = cfg.resizeImage .. "?scalenearest=%s;%s"
  
  local layout = { type = "layout", layoutType = "basic", data = self.size, children = { } }
  layout.children.bg = {
    type = "background",
    fileHeader = fmt(img, width, cfg.headerHeight),
    fileFooter = fmt(img, width, cfg.footerHeight),
    fileBody = fmt(img, width, height - cfg.headerHeight - cfg.footerHeight)
  }

  pane.removeWidget(TEST_WIDGET)
  pane.addWidget(layout, TEST_WIDGET)
  for widgetName, modes in pairs(cfg.widgets) do
    self:apply(widgetName, modes)
  end

  local pid = player.id()
  if pid ~= 0 then
    local s = self.size
    if width == cfg.defaultSize[1] and height == cfg.defaultSize[2] then s = nil end
    world.sendEntityMessage(pid, "pat_infinv_setSize", s)
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
      local dist = pos[1] - (self.lastSize[1] // 2)
      pos[1] = (self.size[1] // 2) + dist
    elseif mode == "y_center" then
      local dist = pos[2] - (self.lastSize[2] // 2)
      pos[2] = (self.size[2] // 2) + dist
    else
      sb.logWarn("InfiniterInventory Layout: no mode '%s'", mode)
    end
  end

  widget.setPosition(widgetName, pos)
  widget.setSize(widgetName, size)
end
