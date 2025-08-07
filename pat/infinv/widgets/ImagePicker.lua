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

  local legacyCount = 0
  for _, group in ipairs(images) do
    if type(group) == "string" then
      legacyCount = legacyCount + 1
      self:addItem(legacyCount, "__legacy", group)
    else
      for i, image in ipairs(group.images) do
        self:addItem(i, group.group, image)
      end
    end
  end
end

function ImagePickerWidget:addItem(index, group, image)
  if group and group:len() > 0 then index = fmt("%s:%s", group, index) end

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
  local item = self.items[index] or self.items[1]
  widget.setListSelected(self.widgetName, item.id)
end

function ImagePickerWidget:getImage(index)
  local item = self.items[index] or self.items[1]
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
