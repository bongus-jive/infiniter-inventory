Callbacks = {}

-- footer buttons
function Callbacks.newTabButton()
  createNewTab():select()
end

function Callbacks.moveTabButton(_, offset)
  local tab = TabList:getSelected()
  if not tab then return end
  tab:move(tab.index + offset)

  updateWidgets()
end

function Callbacks.deleteTabButton()
  local tab = TabList:getSelected()
  if not tab then return end

  if ItemGrid:hasItems() then return end

  local index = tab.index
  tab:remove()

  local new = TabList.tabs[index] or TabList.tabs[index - 1]
  if new then new:select() end

  updateWidgets()
end

function Callbacks.sortButton()
  ItemGrid:condenseStacks()
  ItemGrid:sort()
end

function Callbacks.quickStackbutton()
  ItemGrid:quickStack()
end

function Callbacks.quickMoveCheckbox()
  ItemGrid:setQuickMove(widget.getChecked("quickMoveCheckbox"))
end

function Callbacks.tabConfigCheckbox()
  updateWidgets()
end

-- pages
function Callbacks.changePage(_, offset)
  local tab = TabList:getSelected()
  if not tab then return end

  local currentIndex = tab.data.pageIndex
  local pages = tab.data.pages
  
  local newIndex = math.max(1, math.min(currentIndex + offset, #pages + 1))
  if newIndex == currentIndex then return end

  if currentIndex == #pages and not ItemGrid:hasItems() then
    if currentIndex == 1 or offset > 0 then return end
    table.remove(pages)
  else
    saveCurrentPage(tab)
  end

  tab.data.pageIndex = newIndex

  if not pages[newIndex] then pages[newIndex] = jarray() end
  ItemGrid:setItems(pages[newIndex])
  updateWidgets()
end

function Callbacks.pageScrolling(up)
  Callbacks.changePage(nil, up and -1 or 1)
end

-- tab icons
function Callbacks.tabIconSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  tab.data.iconIndex = IconPicker:getSelected()
  updateTabIcon(tab)
end

function Callbacks.tabIconSlot(item)
  local tab = TabList:getSelected()
  if not tab then return end

  jremove(tab.data, "iconItem")
  if item then tab.data.iconItem = item end
  updateTabIcon(tab)
end

function Callbacks.tabIconRotateButton()
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

--tab label
function Callbacks.tabLabelTextbox()
  local text = widget.getText("editorLayout.labelTextbox")
  
  local tab = TabList:getSelected()
  if not tab then return end
  
  if text and text:len() > 0 then
    tab.data.label = text
  else
    jremove(tab.data, "label")
  end

  updateSubtitle()
end

function Callbacks.tabLabelBlur(name)
  widget.blur("editorLayout." .. name)
end

-- the rest
function Callbacks.gridSlotChanged(slot)
  updateWidgets()
  save()
end

function Callbacks.tabSelected(tab, oldTab)
  if oldTab then
    saveCurrentPage(oldTab)
  end
  
  local label = tab and tab.data.label or ""
  widget.setText("editorLayout.labelTextbox", label)
  updateSubtitle()

  if not tab then
    ItemGrid:clearItems()
    updateWidgets()
    return
  end

  IconPicker:setSelected(tab.data.iconIndex)
  IconPicker:setIconSlotItem(tab.data.iconItem)

  BorderPicker:setSelected(tab.data.borderIndex)
  BackingPicker:setSelected(tab.data.backingIndex)

  local pageIndex = math.max(1, math.min(tab.data.pageIndex, #tab.data.pages))
  ItemGrid:setItems(tab.data.pages[pageIndex])
  updateWidgets()
end

function Callbacks.tabBorderSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  tab.data.borderIndex = BorderPicker:getSelected()
  local image = BorderPicker:getImage(tab.data.borderIndex)
  widget.setImage("border", image)
end

function Callbacks.tabBackingSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  tab.data.backingIndex = BackingPicker:getSelected()
  local image = BackingPicker:getImage(tab.data.backingIndex)
  ItemGrid:setBackingImage(image)
end
