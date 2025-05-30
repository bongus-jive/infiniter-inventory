IconPicker = {}
local fmt = string.format

function IconPicker:init(name, images)
  self.listName = name
  self.images = images
  
  self.items = {}
  local itemIds = {}
  setmetatable(self.items, {__index = itemIds})

  widget.clearListItems(self.listName)

  for i, image in ipairs(self.images) do
    local item = {}
    item.id = widget.addListItem(self.listName)
    item.index = i
    item.image = image

    local icon = fmt("%s.%s.icon", self.listName, item.id)
    widget.setImage(icon, image)

    self.items[i] = item
    itemIds[item.id] = item
  end
end

function IconPicker:getSelected()
  local id = widget.getListSelected(self.listName)
  return self.items[id]
end

function IconPicker:setSelected(index)
  if not index then return end
  local item = self.items[index] or self.items[1]
  widget.setListSelected(self.listName, item.id)
end

function IconPicker:getImage(index)
  return self.images[index] or ""
end
