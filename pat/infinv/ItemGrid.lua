ItemGrid = {}
local fmt = string.format

function ItemGrid:init(name, slotCount)
  self.widgetName = name
  self.slots = {}
  self.slotCount = slotCount
  self.defaultMaxStack = root.assetJson("/items/defaultParameters.config:defaultMaxStack")

  widget.clearListItems(self.widgetName)

  self:registerSlotCallback("slot", self.leftClick)
  self:registerSlotCallback("slot.right", self.rightClick)
  
  for i = 1, self.slotCount or 1 do
    local slot = {}
    slot.index = i
    slot.id = widget.addListItem(self.widgetName)
    slot.parentName = fmt("%s.%s", self.widgetName, slot.id)
    slot.name = fmt("%s.slot", slot.parentName)
    slot.countLabel = fmt("%s.count", slot.parentName)
    self.slots[i] = slot
    widget.setData(slot.name, slot.index)
  end
end

function ItemGrid:hasItems()
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    if self:getSlotItem(slot) then
      return true
    end
  end
  return false
end

function ItemGrid:getItems()
  local items = jarray()
  jresize(items, self.slotCount)
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    items[i] = self:getSlotItem(slot)
  end
  return items
end

function ItemGrid:setItems(items)
  if not items then return self:clearItems() end
  
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    local item = items[i]
    self:setSlotItem(slot, item)
  end
end

function ItemGrid:clearItems()
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    self:setSlotItem(slot, nil)
  end
end

function ItemGrid:registerSlotCallback(callbackName, callback)
  widget.registerMemberCallback(self.widgetName, callbackName, function(_, index)
    if not index or not self.slots[index] then return end
    callback(self, self.slots[index])
  end)
end

function ItemGrid:leftClick(slot)
  local slotItem = self:getSlotItem(slot)
  
  if slotItem and self:shiftHeld() then
    self:setSlotItem(slot, nil)
    player.giveItem(slotItem)
    return
  end
  
  local swapItem = player.swapSlotItem()
  if not swapItem and not slotItem then return end

  if self:stackWith(swapItem, slotItem) then
    if slotItem.count <= 0 then slotItem = nil end
  end
  
  self:setSlotItem(slot, swapItem)
  player.setSwapSlotItem(slotItem)
end

function ItemGrid:rightClick(slot)
  local slotItem = self:getSlotItem(slot)
  if not slotItem then return end
  
  local swapItem = player.swapSlotItem()
  if swapItem and not root.itemDescriptorsMatch(slotItem, swapItem, true) then return end

  local maxStack = self:getMaxStack(slotItem)
  if swapItem and swapItem.count >= maxStack then return end

  local take = 1
  if self:shiftHeld() then
    maxTake = swapItem and math.min(maxStack - swapItem.count, slotItem.count) or maxStack
    take = math.max(1, math.min(maxTake, math.floor(slotItem.count / 2)))
  end

  if swapItem then
    swapItem.count = swapItem.count + take
  else
    swapItem = {name = slotItem.name, parameters = slotItem.parameters, count = take}
  end

  slotItem.count = slotItem.count - take
  if slotItem.count <= 0 then slotItem = nil end
  
  self:setSlotItem(slot, slotItem)
  player.setSwapSlotItem(swapItem)
end

function ItemGrid:shiftHeld()
  if not input then return false end
  return input.key("LShift") or input.key("RShift")
end

function ItemGrid:getSlotItem(slot)
  if not slot then return end
  return widget.itemSlotItem(slot.name)
end

function ItemGrid:setSlotItem(slot, item)
  if item and item.count <= 0 then item = nil end
  widget.setItemSlotItem(slot.name, item)

  if self.onSlotItemChanged then
    self:onSlotItemChanged(slot)
  end

  widget.setVisible(slot.countLabel, item ~= nil)
  if not item then return end

  local count = self:countToString(item.count)
  widget.setText(slot.countLabel, count)
end

function ItemGrid:countToString(num)
  if not num or num == 1 then return "" end

  if num >= 10e6 then
    return fmt("%dm", math.floor(num / 10e5))
  elseif num >= 10e5 then
    return fmt("%.1fm", num / 10e5)
  elseif num >= 10e3 then
    return fmt("%dk", math.floor(num / 10e2))
  elseif num > 10e2 then
    return fmt("%.1fk", num / 10e2)
  end

  return tostring(num)
end

function ItemGrid:getMaxStack(item)
  return item.parameters.maxStack or root.itemConfig(item).config.maxStack or self.defaultMaxStack
end

function ItemGrid:couldStack(item1, item2)
  if item1 and item2 and root.itemDescriptorsMatch(item1, item2, true) then
    local max = self:getMaxStack(item1)
    if item1.count < max then
      return math.min(item2.count, max - item1.count)
    end
  end
  return 0
end

function ItemGrid:stackWith(item1, item2)
  local take = self:couldStack(item1, item2)
  if take > 0 and item2.count >= take then
    item1.count = item1.count + take
    item2.count = item2.count - take
    return true
  end
  return false
end

function ItemGrid:condenseStacks()
  local items = self:getItems()

  for i = self.slotCount, 1, -1 do
    local item = items[i]
    if item then
      for j = 1, i - 1 do
        local stackWithItem = items[j]
        if stackWithItem then
          self:stackWith(item, stackWithItem)
          if stackWithItem.count <= 0 then
            jremove(items, j)
          end
        end
      end
    end
  end

  self:setItems(items)
end

local rarities = {common = 0, uncommon = 1, rare = 2, legendary = 3, essential = 4}
local itemTypes = {
  generic = 0, liquid = 1, material = 2, object = 3, currency = 4, miningtool = 5, flashlight = 6, wiretool = 7, beamminingtool = 8, harvestingtool = 9, tillingtool = 10, paintingbeamtool = 11, headarmor = 12,
  chestarmor = 13, legsarmor = 14, backarmor = 15, consumable = 16, blueprint = 17, codex = 18, inspectiontool = 19, instrument = 20, thrownitem = 22, unlockitem = 23, activeitem = 24, augmentitem = 25
}

function ItemGrid:sort()
  local items = jarray()
  jresize(items, self.slotCount)
  for i = 1, self.slotCount do
    local item = self:getSlotItem(self.slots[i])
    if item then items[#items + 1] = item end
  end

  table.sort(items, function(a, b)
    if a and not b then return true end
    if not a then return false end

    local aType, bType = root.itemType(a.name), root.itemType(b.name)
    if aType ~= bType then return itemTypes[aType] < itemTypes[bType] end

    local aRarity = (a.parameters.rarity or root.itemConfig(a).config.rarity or "common"):lower()
    local bRarity = (b.parameters.rarity or root.itemConfig(b).config.rarity or "common"):lower()
    if aRarity ~= bRarity then
      return rarities[aRarity] > rarities[bRarity]
    end

    if a.name ~= b.name then return a.name < b.name end
    if a.count ~= b.count then return a.count > b.count end

    return false
  end)

  self:setItems(items)
end
