require "/pat/infinv/widgets/ImagePicker.lua"

IconPickerWidget = ImagePickerWidget:new()
local fmt = string.format

function IconPickerWidget:new(name, slotCallback)
  local new = ImagePickerWidget.new(self, name)
  new.slotCallback = slotCallback
  return new
end

function IconPickerWidget:init()
  ImagePickerWidget.init(self)

  self._slotLeft = function() self:slotLeft() end
  self._slotRight = function() self:slotRight() end
end

function IconPickerWidget:buildList()
  local item = self:addItem(-1)
  widget.addChild(item.name, self.data.iconSlotTemplate, "slot")
  self.iconSlot = fmt("%s.slot", item.name)

  ImagePickerWidget.buildList(self)
end

function IconPickerWidget:getImage(index, item)
  if index == -1 then
    return self:getItemIcon(item)
  end
  return ImagePickerWidget.getImage(self, index)
end

function IconPickerWidget:getIconSlotItem()
  return widget.itemSlotItem(self.iconSlot)
end

function IconPickerWidget:setIconSlotItem(item)
  widget.setItemSlotItem(self.iconSlot, item)
end

function IconPickerWidget:getItemIcon(itemDesc)
  item = root.itemConfig(itemDesc)
  if not item then return end

  local function instanceValue(key, def)
    return item.parameters[key] or item.config[key] or def
  end

  local itemType = root.itemType(itemDesc.name)
  local icon
  if itemType == "codex" then
    icon = instanceValue("codexIcon")
  else
    icon = instanceValue("inventoryIcon")
  end
  if not icon then return end

  local directives = ""
  if itemType == "headarmor" or itemType == "chestarmor" or itemType == "legsarmor" or itemType == "backarmor" then
    directives = instanceValue("directives")
    if not directives or directives:len() == 0 then
      local options = instanceValue("colorOptions", { "" })
      local index = (instanceValue("colorIndex", 0) % #options) + 1
      local option = options[index]

      if type(option) == "string" then
        directives = "?" .. option
      else
        directives = "?replace"
        for from, to in pairs(option) do directives = fmt("%s;%s=%s", directives, from, to) end
      end
    end
  end

  local function absolutePath(path)
    if path and path:sub(1, 1) ~= "/" then return item.directory .. path end
    return path
  end

  if type(icon) == "string" then
    return absolutePath(icon) .. directives
  end

  for _, drawable in pairs(icon) do
    drawable.image = absolutePath(drawable.image) .. directives
  end
  return icon
end

function IconPickerWidget:slotLeft()
  local item = player.swapSlotItem()
  if not item then return end

  local current = self:getIconSlotItem()
  if item and current and root.itemDescriptorsMatch(item, current, true) then
    item = nil
  end

  self:setIconSlotItem(item)
  if self.slotCallback then self.slotCallback(item) end
end

function IconPickerWidget:slotRight()
  self:setIconSlotItem()
  if self.slotCallback then self.slotCallback() end
end
