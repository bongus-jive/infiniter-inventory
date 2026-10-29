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

  widget.clearListItems(self.widgetName)
  self.items = {}
  self.itemIds = {}
  
  self.imageTags = self.data.tags or {}
  self.iconTags = sb.jsonMerge(self.imageTags, self.data.iconTags)

  self:buildList()
end

function ImagePickerWidget:buildList()
  local images = root.assetJson(self.data.images)

  self.legacyCount = 0
  for _, group in ipairs(images) do
    self:addGroup(group)
  end

  self.defaultItem = self.items[1] or select(2, next(self.items))
end

function ImagePickerWidget:addGroup(group)
  if type(group) == "string" then
    self.legacyCount = (self.legacyCount or 0) + 1
    self:addItem("__legacy:"..legacyCount, group)
    return
  end

  local name = group.group
  if name == "" then name = nil end

  for i, image in ipairs(group.images) do
    local index = i
    if name then index = fmt("%s:%s", name, i) end
    self:addItem(index, image)
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
  local item = self.items[index] or self.defaultItem
  if not item then return end

  widget.setListSelected(self.widgetName, item.id)
end

function ImagePickerWidget:getImage(index)
  local item = self.items[index] or self.defaultItem
  if not item then return "" end

  return item.baseImage and sb.replaceTags(item.baseImage, self.imageTags) or ""
end

function ImagePickerWidget:setTag(name, value)
  self.imageTags[name] = value
  self.iconTags[name] = value

  for _, item in pairs(self.itemIds) do
    if item.baseImage then
      widget.setImage(item.iconName, sb.replaceTags(item.baseImage, self.iconTags))
    end
  end
end
