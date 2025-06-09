IconPickerWidget = {}
local fmt = string.format

function IconPickerWidget:new(name)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  return new
end

function IconPickerWidget:init()
  self.data = widget.getData(self.widgetName) or {}

  self.images = self.data.images or {}
  if type(self.images) == "string" then
    self.images = root.assetJson(self.images)
  end

  widget.clearListItems(self.widgetName)
  self.items = {}
  self.itemIds = {}

  local item = self:addItem(-1)
  widget.addChild(item.name, self.data.iconSlotTemplate, "slot")
  self.iconSlot = fmt("%s.slot", item.name)

  local btn = fmt("%s.button", item.name)
  local data = widget.getData(btn) or {}
  data.tooltipKey = "tabIconSlot"
  widget.setData(btn, data)

  for i, image in ipairs(self.images) do
    self:addItem(i, image)
  end
end

function IconPickerWidget:addItem(index, image)
  local item = {}
  item.id = widget.addListItem(self.widgetName)
  item.index = index
  item.name = fmt("%s.%s", self.widgetName, item.id)

  if image then
    local icon = fmt("%s.icon", item.name)
    widget.setImage(icon, image)
  end

  self.items[index] = item
  self.itemIds[item.id] = item
  return item
end

function IconPickerWidget:getSelected()
  local id = widget.getListSelected(self.widgetName)
  return self.itemIds[id]
end

function IconPickerWidget:setSelected(index)
  if not index then return end
  local item = self.items[index] or self.items[1]
  widget.setListSelected(self.widgetName, item.id)
end

function IconPickerWidget:getImage(index)
  return self.images[index] or ""
end

function IconPickerWidget:getIconSlotItem()
  return widget.itemSlotItem(self.iconSlot)
end

function IconPickerWidget:setIconSlotItem(item)
  widget.setItemSlotItem(self.iconSlot, item)
end
