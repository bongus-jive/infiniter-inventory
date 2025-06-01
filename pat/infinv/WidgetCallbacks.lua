Callbacks = {}

function Callbacks.newTabButton()
  TabList:newTab():select()
end

function Callbacks.moveTabButton(_, offset)
  local tab = TabList:getSelected()
  if not tab then return end
  tab:move(tab.index + offset)
end

function Callbacks.deleteTabButton()
  if ItemGrid:hasItems() then return end

  local tab = TabList:getSelected()
  if not tab then return end

  local index = tab.index
  tab:remove()

  local new = TabList.tabs[index] or TabList.tabs[index - 1]
  if new then new:select() end
end

function Callbacks.sortButton()
  ItemGrid:condenseStacks()
  ItemGrid:sort()
end

function Callbacks.quickStackbutton()
  ItemGrid:quickStack()
end

function Callbacks.tabConfigCheckbox()
  updateWidgets()
end

function Callbacks.tabIconSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  local icon = IconPicker:getSelected()
  tab.data.iconIndex = icon.index
  updateTabIcon(tab)
end

function Callbacks.tabIconSlot()
  local item = player.swapSlotItem()
  if not item then return end

  local tab = TabList:getSelected()
  if not tab then return end

  local current = IconPicker:getIconSlotItem()
  if item and current and root.itemDescriptorsMatch(item, current, true) then
    item = nil
  end

  jremove(tab.data, "iconItem")
  if item then
    tab.data.iconItem = item
  end

  IconPicker:setIconSlotItem(item)
  updateTabIcon(tab)
end

function Callbacks.tabIconSlotRight()
  IconPicker:setIconSlotItem(nil)

  local tab = TabList:getSelected()
  if not tab then return end
  jremove(tab.data, "iconItem")
  updateTabIcon(tab)
end

function Callbacks.tabLabelTextbox()
  local text = widget.getText("tabConfig.labelTextbox")
  
  local tab = TabList:getSelected()
  if not tab then return end
  
  if text and text:len() > 0 then
    tab.data.label = text
  else
    jremove(tab.data, "label")
  end

  updateTitle()
end

function Callbacks.tabConfigTextboxBlur(name)
  widget.blur("tabConfig." .. name)
end

function Callbacks.rotateIconButton()
  local tab = TabList:getSelected()
  if not tab then return end

  local rot = tab.data.iconRotation or 360
  rot = rot - 90
  if rot <= 0 then
    jremove(tab.data, "iconRotation")
  else
    tab.data.iconRotation = rot
  end

  updateTabIcon(tab)
end
