ItemGridWidget = {}
local fmt = string.format

function ItemGridWidget:new(name, callback)
  local new = {}
  setmetatable(new, {__index = self})
  new.widgetName = name
  new.callback = callback
  return new
end

function ItemGridWidget:init()
  self.defaultMaxStack = root.assetJson("/items/defaultParameters.config:defaultMaxStack")
  self.data = widget.getData(self.widgetName) or {}
  self.slotCount = self.data.slotCount or 1
  self.slots = {}

  widget.clearListItems(self.widgetName)

  self:registerSlotCallback("slot", self.leftClick)
  self:registerSlotCallback("slot.right", self.rightClick)
  
  for i = self.slotCount, 1, -1 do
    local slot = {}
    slot.index = i
    slot.id = widget.addListItem(self.widgetName)
    slot.name = fmt("%s.%s", self.widgetName, slot.id)
    slot.itemSlot = fmt("%s.slot", slot.name)
    slot.countLabel = fmt("%s.count", slot.name)
    slot.backingImage = fmt("%s.backing", slot.name)
    slot.highlightImage = fmt("%s.highlight", slot.name)
    self.slots[i] = slot
    widget.setData(slot.itemSlot, slot.index)
  end

  for i = 1, math.floor(self.slotCount / 2) do
    local slot1 = self.slots[i]
    local slot2 = self.slots[self.slotCount - i + 1]
    local pos1 = widget.getPosition(slot1.name)
    local pos2 = widget.getPosition(slot2.name)
    widget.setPosition(slot1.name, pos2)
    widget.setPosition(slot2.name, pos1)
  end

  self:setBackingImage(self.data.backingImage)
  self.highlightTimer = 0
end

function ItemGridWidget:update(dt)
  local hl = self.data.highlight

  self.highlightTimer = (self.highlightTimer + dt) % hl.cycle
  local frame = math.floor((self.highlightTimer / hl.cycle) * hl.frames)
  
  if frame ~= self.highlightFrame then
    self.highlightFrame = frame
    local image = self.highlightFrames[frame]
    for i = 1, self.slotCount do
      widget.setImage(self.slots[i].highlightImage, image)
    end
  end
end

function ItemGridWidget:getSlotItem(slot)
  if not slot then return end
  return slot.item
end

function ItemGridWidget:setSlotItem(slot, item, skipCallback)
  if self:isItemEmpty(item) then item = nil end
  widget.setItemSlotItem(slot.itemSlot, item)
  slot.item = item

  if self.callback and not skipCallback then self.callback(slot) end

  widget.setVisible(slot.countLabel, item ~= nil)
  if item then
    widget.setVisible(slot.backingImage, self.data.showBackingImageWhenFull or false)
  else
    widget.setVisible(slot.backingImage, self.data.showBackingImageWhenEmpty or true)
    return
  end

  local count = self:countToString(item.count)
  widget.setText(slot.countLabel, count)
end

function ItemGridWidget:addItem(inputItem)
  local firstEmptySlot

  for i = 1, self.slotCount do
    local slot = self.slots[i]

    local slotItem = self:getSlotItem(slot)
    if slotItem then
      if self:stackWith(slotItem, inputItem) then
        self:setSlotItem(slot, slotItem)
        if self:isItemEmpty(inputItem) then return end
      end
    elseif not firstEmptySlot then
      firstEmptySlot = slot
    end
  end

  if firstEmptySlot then
    self:setSlotItem(firstEmptySlot, inputItem)
    return
  end

  return inputItem
end

function ItemGridWidget:hasItems()
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    if self:getSlotItem(slot) then
      return true
    end
  end
  return false
end

function ItemGridWidget:getItems()
  local items = jarray()
  jresize(items, self.slotCount)
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    items[i] = self:getSlotItem(slot)
  end
  return items
end

function ItemGridWidget:setItems(items, doCallback)
  if not items then return self:clearItems() end

  for i = 1, self.slotCount do
    local slot = self.slots[i]
    local item = items[i]
    self:setSlotItem(slot, item, true)
  end

  if self.callback and doCallback then self.callback() end
end

function ItemGridWidget:clearItems()
  for i = 1, self.slotCount do
    local slot = self.slots[i]
    self:setSlotItem(slot, nil, true)
  end
end

function ItemGridWidget:registerSlotCallback(callbackName, callback)
  widget.registerMemberCallback(self.widgetName, callbackName, function(_, index)
    if not index or not self.slots[index] then return end
    callback(self, self.slots[index])
  end)
end

function ItemGridWidget:leftClick(slot)
  local slotItem = self:getSlotItem(slot)
  
  if slotItem and (self.quickMove or self:shiftHeld()) then
    self:setSlotItem(slot, nil)
    player.giveItem(slotItem)
    return
  end
  
  local swapItem = player.swapSlotItem()
  if not swapItem and not slotItem then return end

  if self:stackWith(swapItem, slotItem) then
    if self:isItemEmpty(slotItem) then slotItem = nil end
  end
  
  self:setSlotItem(slot, swapItem)
  player.setSwapSlotItem(slotItem)
end

function ItemGridWidget:rightClick(slot)
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
  if self:isItemEmpty(slotItem) then slotItem = nil end
  
  self:setSlotItem(slot, slotItem)

  if self.quickMove then
    player.giveItem(swapItem)
  else
    player.setSwapSlotItem(swapItem)
  end
end

function ItemGridWidget:shiftHeld()
  if not input then return false end
  return input.key("LShift") or input.key("RShift")
end

function ItemGridWidget:setQuickMove(v)
  self.quickMove = v
end

local suffixes = {
  {"Q", 1e18},
  {"q", 1e15},
  {"t", 1e12},
  {"b", 1e9},
  {"m", 1e6},
  {"k", 1000, 2000}
}

function ItemGridWidget:countToString(num)
  if not num or num == 1 then return "" end

  for _, v in ipairs(suffixes) do
    local suffix, divisor = v[1], v[2]
    local min = v[3] or divisor
    if num >= min then
      if num >= divisor * 10 then
        return fmt("%d%s", math.floor(num / divisor), suffix)
      end
      return fmt("%.1f%s", num / divisor, suffix)
    end
  end

  return tostring(num)
end

function ItemGridWidget:isItemEmpty(item)
  return not (item and item.count > 0)
end

function ItemGridWidget:getMaxStack(item)
  return item.parameters.maxStack or root.itemConfig(item).config.maxStack or self.defaultMaxStack
end

function ItemGridWidget:couldStack(item1, item2)
  if item1 and item2 and item1.name == item2.name and root.itemDescriptorsMatch(item1, item2, true) then
    local max = self:getMaxStack(item1)
    if item1.count < max then
      return math.min(item2.count, max - item1.count)
    end
  end
  return 0
end

function ItemGridWidget:stackWith(item1, item2)
  local take = self:couldStack(item1, item2)
  if take > 0 and item2.count >= take then
    item1.count = item1.count + take
    item2.count = item2.count - take
    return true
  end
  return false
end

function ItemGridWidget:condenseAndSortStacks()
  local items = self:getItems()
  self:condenseStacks(items)
  items = self:sortStacks(items)
  self:setItems(items, true)
end

function ItemGridWidget:condenseStacks(items)
  for i = self.slotCount, 1, -1 do
    local item = items[i]
    if not item then goto continue end

    for j = 1, i - 1 do
      local stackWithItem = items[j]
      if stackWithItem and self:stackWith(item, stackWithItem) and self:isItemEmpty(stackWithItem) then
        jremove(items, j)
      end
    end
    ::continue::
  end
end

local rarities = {common = 0, uncommon = 1, rare = 2, legendary = 3, essential = 4}
local itemTypes = {
  generic = 0, liquid = 1, material = 2, object = 3, currency = 4, miningtool = 5, flashlight = 6, wiretool = 7, beamminingtool = 8, harvestingtool = 9, tillingtool = 10, paintingbeamtool = 11, headarmor = 12,
  chestarmor = 13, legsarmor = 14, backarmor = 15, consumable = 16, blueprint = 17, codex = 18, inspectiontool = 19, instrument = 20, thrownitem = 22, unlockitem = 23, activeitem = 24, augmentitem = 25
}

function ItemGridWidget:sortStacks(unsorted)
  local items = jarray()
  jresize(items, self.slotCount)

  local itemData = {}
  for _, item in next, unsorted do
    items[#items + 1] = item
    local rarity = (item.parameters.rarity or root.itemConfig(item).config.rarity or "common"):lower()
    local itemType = root.itemType(item.name)
    itemData[item] = { rarity = rarities[rarity], type = itemTypes[itemType] }
  end

  table.sort(items, function(a, b)
    if a and not b then return true end
    if not a then return false end

    local aData, bData = itemData[a], itemData[b]
    if aData.type ~= bData.type then return aData.type < bData.type end
    if aData.rarity ~= bData.rarity then return aData.rarity > bData.rarity end

    if a.name ~= b.name then return a.name < b.name end
    if a.count ~= b.count then return a.count > b.count end

    return false
  end)

  return items
end

function ItemGridWidget:quickStack()
  local items = self:getItems()
  local hasStacked = false

  local extraItems = {}
  local emptySlots = {}

  for i = 1, self.slotCount do
    local item = items[i]
    if not item then
      table.insert(emptySlots, i)
      goto continue
    end

    local hasCount = player.hasCountOfItem(item, true)
    if hasCount == 0 then goto continue end
    hasStacked = true

    local max = self:getMaxStack(item)
    local take = math.min(hasCount, max - item.count)
    local consumed = player.consumeItem({item.name, take, item.parameters}, true, true)
    item.count = item.count + consumed.count

    if hasCount > consumed.count then
      table.insert(extraItems, item)
    end

    ::continue::
  end

  for _, item in ipairs(extraItems) do
    local hasCount = player.hasCountOfItem(item, true)
    if hasCount == 0 then goto continue end

    while hasCount > 0 do
      if #emptySlots == 0 then break end
      
      local slot = emptySlots[1]
      table.remove(emptySlots, 1)

      local take = math.min(hasCount, self:getMaxStack(item))
      local consumed = player.consumeItem({item.name, take, item.parameters}, true, true)
      items[slot] = consumed
      hasCount = hasCount - consumed.count
    end

    ::continue::
  end

  if hasStacked then self:setItems(items, true) end
end

function ItemGridWidget:setBackingImage(image)
  for i = 1, self.slotCount do
    widget.setImage(self.slots[i].backingImage, image)
  end

  self.highlightFrames = {}
  local hl = self.data.highlight
  for i = 0, self.data.highlight.frames - 1 do
    local frame = sb.replaceTags(hl.image, {frame = tostring(i), backing = image})
    self.highlightFrames[i] = frame
  end
end

function ItemGridWidget:resetHighlighted()
  for i = 1, self.slotCount do
    widget.setVisible(self.slots[i].highlightImage, false)
  end
end

function ItemGridWidget:setSlotHighlighted(slot, enabled)
  if type(slot) == "number" then slot = self.slots[slot] end
  if not slot then return end

  widget.setVisible(slot.highlightImage, enabled)
end
