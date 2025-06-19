ImagePickerWidget = {}
local fmt = string.format

function ImagePickerWidget:new(name)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  return new
end

function ImagePickerWidget:init()
  self.data = widget.getData(self.widgetName) or {}

  self.images = self.data.images or {}
  if type(self.images) == "string" then
    self.images = root.assetJson(self.images)
  end

  widget.clearListItems(self.widgetName)
  self.items = {}
  self.itemIds = {}

  self:buildList()
end

function ImagePickerWidget:buildList()
  for i, image in ipairs(self.images) do
    self:addItem(i, image)
    self.images[i] = image:gsub("<frame>", "base")
  end
end

function ImagePickerWidget:addItem(index, image)
  local item = {}
  item.id = widget.addListItem(self.widgetName)
  item.index = index
  item.name = fmt("%s.%s", self.widgetName, item.id)
  widget.setData(fmt("%s.button", item.name), { parent = self.widgetName, index = index })

  if image then
    local icon = fmt("%s.icon", item.name)
    widget.setImage(icon, image:gsub("<frame>", "icon"))
  end

  self.items[index] = item
  self.itemIds[item.id] = item
  return item
end

function ImagePickerWidget:getSelected()
  local id = widget.getListSelected(self.widgetName)
  return self.itemIds[id].index
end

function ImagePickerWidget:setSelected(index)
  local item = self.items[index or 1] or self.items[1]
  widget.setListSelected(self.widgetName, item.id)
end

function ImagePickerWidget:getImage(index, item)
  return self.images[index] or ""
end
