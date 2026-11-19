ImagePickerWidget = {}
local fmt = string.format

function ImagePickerWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  new.callback = callback
  return new
end

function ImagePickerWidget:init()
  self.data = widget.getData(self.widgetName) or {}

  self.template = { type = "layout", layoutType = "basic", scissoring = false, children = self.data.template }

  widget.removeAllChildren(self.widgetName)
  self.itemCount = 0
  self.items = {}
  
  self.imageTags = self.data.tags or {}
  self.iconTags = sb.jsonMerge(self.imageTags, self.data.iconTags)

  self:buildList()

  self._select = function(_, data) self:onSelect(data) end
end

function ImagePickerWidget:buildList()
  local images = root.assetJson(self.data.images)

  self.legacyCount = 0
  for _, group in ipairs(images) do
    self:addGroup(group)
  end

  self.defaultItem = self.items[1] or select(2, next(self.items))

  self:updatePositions()
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
    local key = i
    if name then key = fmt("%s:%s", name, i) end
    self:addItem(key, image)
  end
end

function ImagePickerWidget:addItem(key, image)
  widget.addChild(self.widgetName, self.template, tostring(key))

  local item = {}
  item.key = key
  item.order = self.itemCount
  item.name = fmt("%s.%s", self.widgetName, key)
  item.iconName = fmt("%s.icon", item.name)
  item.selectName = fmt("%s.select", item.name)
  widget.setData(fmt("%s.button", item.name), { parent = self.widgetName, key = key })

  if image then
    item.baseImage = image
    widget.setImage(item.iconName, sb.replaceTags(image, self.iconTags))

    if self.data.specialTag and image:find(fmt("<%s>", self.data.specialTag)) then
      widget.setVisible(fmt("%s.special", item.name), true)
      item.special = true
    end
  end

  self.itemCount = self.itemCount + 1
  self.items[key] = item
  return item
end

function ImagePickerWidget:updatePositions()
  local space = self.data.spacing
  local width = widget.getSize(self.widgetName)[1]
  local columns = width // space[1]
  local rows = math.ceil(self.itemCount / columns)

  widget.setSize(self.widgetName, { width, space[2] * rows })

  for _, item in pairs(self.items) do
    local i = item.order
    local x = space[1] * (i % columns)
    local y = space[2] * (rows - (i // columns) - 1)
    widget.setPosition(item.name, {x, y})
  end
end

function ImagePickerWidget:getSelected()
  if not self.selected then return end
  return self.selected.key, self.selected.special
end

function ImagePickerWidget:setSelected(key)
  local item = self.items[key] or self.defaultItem
  if not item then return end

  if self.selected then widget.setVisible(self.selected.selectName, false) end

  self.selected = item
  widget.setVisible(self.selected.selectName, true)
end

function ImagePickerWidget:onSelect(data)
  if not data then return end
  self:setSelected(data.key)
  self.callback()
end

function ImagePickerWidget:getImage(key)
  local item = self.items[key] or self.defaultItem
  if not item or not item.baseImage then return "" end

  return sb.replaceTags(item.baseImage, self.imageTags)
end

function ImagePickerWidget:setTag(name, value)
  self.imageTags[name] = value
  self.iconTags[name] = value

  for _, item in pairs(self.items) do
    if item.baseImage then
      widget.setImage(item.iconName, sb.replaceTags(item.baseImage, self.iconTags))
    end
  end
end
