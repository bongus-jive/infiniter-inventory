IconPicker = {}
local fmt = string.format

function IconPicker:init(name, images)
  self.listName = name
  self.images = images
  self.data = widget.getData(self.listName)

  self.items = {}
  self.itemIds = {}

  widget.clearListItems(self.listName)

  local item = self:addItem(-1)
  widget.addChild(item.widgetName, self.data.iconSlotTemplate, "slot")
  self.iconSlot = fmt("%s.slot", item.widgetName)

  local btn = fmt("%s.button", item.widgetName)
  local data = widget.getData(btn) or {}
  data.tooltipKey = "tabIconSlot"
  widget.setData(btn, data)

  for i, image in ipairs(self.images) do
    self:addItem(i, image)
  end
end

function IconPicker:addItem(index, image)
  local item = {}
  item.id = widget.addListItem(self.listName)
  item.index = index
  item.widgetName = fmt("%s.%s", self.listName, item.id)

  if image then
    local icon = fmt("%s.icon", item.widgetName)
    widget.setImage(icon, image)
  end

  self.items[index] = item
  self.itemIds[item.id] = item
  return item
end

function IconPicker:getSelected()
  local id = widget.getListSelected(self.listName)
  return self.itemIds[id]
end

function IconPicker:setSelected(index)
  if not index then return end
  local item = self.items[index] or self.items[1]
  widget.setListSelected(self.listName, item.id)
end

function IconPicker:getImage(index)
  return self.images[index] or ""
end

function IconPicker:getIconSlotItem()
  return widget.itemSlotItem(self.iconSlot)
end

function IconPicker:setIconSlotItem(item)
  widget.setItemSlotItem(self.iconSlot, item)
end
