TabListWidget = {}
local fmt = string.format

function TabListWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.TabItem = {}
  setmetatable(new.TabItem, {__index = self.TabItem})

  new.widgetName = name
  new.callback = callback
  return new
end

function TabListWidget:init()
  self.data = widget.getData(self.widgetName) or {}
  self:clear()

  self._select = function()
    if self._skipSelectCallback then return end
    
    local id = widget.getListSelected(self.widgetName)

    local oldTab = self.selectedTab
    self.selectedTab = self.tabs[id]

    if self.callback then
      self.callback(self.selectedTab, oldTab)
    end
  end
end

function TabListWidget:clear()
  widget.clearListItems(self.widgetName)
  self.tabs = {}
  self.tabIds = {}
  self.selectedTab = nil
  setmetatable(self.tabs, {__index = self.tabIds})
end

function TabListWidget:rebuild()
  self._skipSelectCallback = true
  widget.clearListItems(self.widgetName)
  for _, tab in ipairs(self.tabs) do
    self.tabIds[tab.id] = nil
    tab:init()
  end
  if self.selectedTab then self.selectedTab:select() end
  self._skipSelectCallback = false
end

function TabListWidget:reindex(start)
  for i = (start or 1), #self.tabs do
    local tab = self.tabs[i]
    tab.index = i
    tab:initChildren()
  end
end

function TabListWidget:getSelected()
  return self.selectedTab
end

function TabListWidget:resetHighlighted()
  for _, tab in pairs(self.tabs) do
    tab:setHighlighted(false)
  end
end

function TabListWidget:newTab(data)
  local new = {}
  setmetatable(new, {__index = self.TabItem})

  table.insert(self.tabs, new)
  new.index = #self.tabs
  new.parent = self
  new.data = data or jobject()
  new:init()

  return new
end

-------------------------------------------------

local TabItem = {}
TabListWidget.TabItem = TabItem

function TabItem:init()
  self.id = widget.addListItem(self.parent.widgetName)
  self.widgetName = fmt("%s.%s", self.parent.widgetName, self.id)
  self.parent.tabIds[self.id] = self

  self:initChildren()

  if self.highlighted then
    self:setHighlighted(true)
  end

  if self.icon then
    self:setIcon(self.icon[1], self.icon[2])
  end
end

function TabItem:initChildren()
  self.children = {}
  if not self.parent.data.initChildren then return end
  for _, name in pairs(self.parent.data.initChildren) do
    self:initChild(name)
  end
end

function TabItem:initChild(name)
  local child = fmt("%s.%s", self.widgetName, name)
  local data = widget.getData(child) or {}
  data.parent = self.parent.widgetName
  data.index = self.index
  widget.setData(child, data)
  self.children[name] = child
end

function TabItem:remove()
  widget.removeListItem(self.parent.widgetName, self.index - 1)
  table.remove(self.parent.tabs, self.index)
  self.parent.tabIds[self.id] = nil
  self.parent:reindex(self.index)
end

function TabItem:move(newIndex)
  newIndex = math.max(1, math.min(#self.parent.tabs, newIndex))
  if self.index == newIndex then return end

  table.remove(self.parent.tabs, self.index)
  table.insert(self.parent.tabs, newIndex, self)

  self.parent:reindex()
  self.parent:rebuild()
end

function TabItem:isSelected()
  return self == self.parent.selectedTab
end

function TabItem:select()
  widget.setListSelected(self.parent.widgetName, self.id)
  self.parent.selectedTab = self
end

function TabItem:setIcon(image, rotation)
  widget.removeChild(self.widgetName, "icon")
  self.icon = nil

  if not image then return end
  
  local iconConfig = {
    rotation = rotation,
    [type(image) == "string" and "file" or "drawables"] = image
  }
  iconConfig = sb.jsonMerge(self.parent.data.iconTemplate, iconConfig)
  
  widget.addChild(self.widgetName, iconConfig, "icon")
  self.icon = {image, rotation}
end

function TabItem:setHighlighted(enabled)
  if not self.children.highlight then return end
  widget.setVisible(self.children.highlight, enabled)
  self.highlighted = enabled or nil
end
