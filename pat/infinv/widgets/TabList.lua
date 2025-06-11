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

  self._selectCallback = function()
    if self._skipSelectCallback then return end

    local oldTab = self.selectedTab
    local newTab = self:getSelected()
    if self.callback then
      self.callback(newTab, oldTab)
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
  widget.clearListItems(self.widgetName)
  for _, tab in ipairs(self.tabs) do
    self.tabIds[tab.id] = nil
    tab:init()
  end
end

function TabListWidget:reindex(start)
  for i = (start or 1), #self.tabs do
    self.tabs[i].index = i
  end
end

function TabListWidget:getSelected()
  local id = widget.getListSelected(self.widgetName)
  self.selectedTab = self.tabs[id]
  return self.selectedTab
end

function TabListWidget:deselect()
  if not widget.getListSelected(self.widgetName) then return end

  self._skipSelectCallback = true
  local new = widget.addListItem(self.widgetName)
  widget.setListSelected(self.widgetName, new)
  widget.removeListItem(self.widgetName, #self.tabs)
  self._skipSelectCallback = false
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

  self.children = {}
  if self.parent.data.initChildren then
    for _, name in ipairs(self.parent.data.initChildren) do
      self:initChild(name)
    end
  end
end

function TabItem:initChild(name)
  local child = fmt("%s.%s", self.widgetName, name)
  local data = widget.getData(child) or {}
  data.parentTabId = self.id
  widget.setData(child, data)
  self.children[name] = child
end

function TabItem:remove()
  self:deselect()
  widget.removeListItem(self.parent.widgetName, self.index - 1)
  self.parent.tabIds[self.id] = nil
  table.remove(self.parent.tabs, self.index)
  self.parent:reindex(self.index)
end

function TabItem:move(newIndex)
  newIndex = math.max(1, math.min(#self.parent.tabs, newIndex))
  if self.index == newIndex then return end

  local selected = self:isSelected()

  table.remove(self.parent.tabs, self.index)
  table.insert(self.parent.tabs, newIndex, self)

  self.parent:reindex()
  self.parent:rebuild()

  if selected then self:select() end
end

function TabItem:isSelected()
  return self == self.parent.selectedTab
end

function TabItem:select()
  widget.setListSelected(self.parent.widgetName, self.id)
  self.parent.selectedTab = self
end

function TabItem:deselect()
  if self:isSelected() then self.parent:deselect() end
end

function TabItem:setIcon(image, rotation)
  widget.removeChild(self.widgetName, "icon")
  self.children.icon = nil

  if not image then return end

  local iconConfig = {
    rotation = rotation,
    [type(image) == "string" and "file" or "drawables"] = image
  }
  iconConfig = sb.jsonMerge(self.parent.data.iconTemplate, iconConfig)
  
  widget.addChild(self.widgetName, iconConfig, "icon")
  self:initChild("icon")
end
