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
  
  self.imageTags = self.data.tags or {}
  self.iconTags = sb.jsonMerge(self.imageTags, self.data.iconTags)

  self:buildList()
end

function ImagePickerWidget:buildList()
  for i, image in ipairs(self.images) do
    self:addItem(i, image)
  end
end

function ImagePickerWidget:addItem(index, image)
  local item = {}
  item.id = widget.addListItem(self.widgetName)
  item.index = index
  item.name = fmt("%s.%s", self.widgetName, item.id)
  item.iconName = fmt("%s.icon", item.name)
  widget.setData(fmt("%s.button", item.name), { parent = self.widgetName, index = index })

  if image then
    item.baseImage = image
    widget.setImage(item.iconName, sb.replaceTags(image, self.iconTags))

    if self.data.specialTag and image:find(fmt("<%s>", self.data.specialTag)) then
      widget.setVisible(fmt("%s.special", item.name), true)
      item.special = true
    end
  end

  self.items[index] = item
  self.itemIds[item.id] = item
  return item
end

function ImagePickerWidget:getSelected()
  local id = widget.getListSelected(self.widgetName)
  local item = self.itemIds[id]
  return item.index, item.special
end

function ImagePickerWidget:setSelected(index)
  local item = self.items[index or 1] or self.items[1]
  widget.setListSelected(self.widgetName, item.id)
end

function ImagePickerWidget:getImage(index)
  local image = self.images[index or 1] or self.images[1]
  return image and sb.replaceTags(image, self.imageTags) or ""
end

function ImagePickerWidget:setTag(name, value, icon)
  self.imageTags[name] = value
  self.iconTags[name] = value

  for _, item in pairs(self.items) do
    if item.baseImage then
      widget.setImage(item.iconName, sb.replaceTags(item.baseImage, self.iconTags))
    end
  end
end
