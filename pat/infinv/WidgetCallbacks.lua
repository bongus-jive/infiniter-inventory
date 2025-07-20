Callbacks = {}

-- footer buttons
function Callbacks.newTabButton()
  createTab():select()
  save()
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

  local pages = tab.data.pages
  for _, id in pairs(pages) do
    local items = InvData:getPageItems(id)
    if next(items) then return end
  end

  for _, id in pairs(pages) do
    InvData:removePage(id)
  end

  local index = tab.index
  tab:remove()

  local new = TabList.tabs[index] or TabList.tabs[index - 1]
  if new then new:select() end

  save()
  updateWidgets()
  Searcher:restart()
end

function Callbacks.sortButton()
  ItemGrid:condenseAndSortStacks()
end

function Callbacks.quickStackButton()
  ItemGrid:quickStack()
end

function Callbacks.quickMoveCheckbox()
  ItemGrid:setQuickMove(widget.getChecked("gridLayout.quickMoveCheckbox"))
end

function Callbacks.tabConfigCheckbox()
  updateWidgets()
end

-- pages
function Callbacks.changePage(_, offset)
  local tab = TabList:getSelected()
  if not tab then return end

  changePage(tab.data.pageIndex + offset)
end

function Callbacks.pageScrolling(up)
  local tab = TabList:getSelected()
  if not tab then return end

  setPageBoxEnabled(false)
  changePage(tab.data.pageIndex + (up and -1 or 1))
end

local pageBox = "gridLayout.pageTextbox"
function Callbacks.pageBox()
  if not widget.hasFocus(pageBox) then return end

  local text = widget.getText(pageBox)
  if not text or text:len() == 0 then return end

  local newPage = tonumber(text)
  changePage(newPage)
  
  local tab = TabList:getSelected()
  if tab and tab.data.pageIndex ~= newPage then
    widget.setText(pageBox, tostring(tab.data.pageIndex))
  end
end

function Callbacks.focusPageBox()
  setPageBoxEnabled(true)
  widget.setText(pageBox, "")
  widget.focus(pageBox)
end

function Callbacks.blurPageBox()
  setPageBoxEnabled(false)
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
  if item then tab.data.iconItem = {name = item.name, parameters = item.parameters} end
  updateTabIcon(tab)
end

function Callbacks.tabIconRotateButton()
  local tab = TabList:getSelected()
  if not tab then return end

  local rot = tab.data.iconRotation or 360
  rot = rot - 90
  jremove(tab.data, "iconRotation")
  if rot > 0 then
    tab.data.iconRotation = rot
  end

  updateTabIcon(tab)
end

-- tab label
function Callbacks.tabLabelTextbox()
  local tab = TabList:getSelected()
  if not tab then return end

  local text = widget.getText("editorLayout.labelTextbox")
  
  jremove(tab.data, "label")
  if text and text:len() > 0 then
    tab.data.label = text
  end

  updateSubtitle()
end

-- tab customization
function Callbacks.tabBorderSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  jremove(tab.data, "borderIndex")
  local index = BorderPicker:getSelected()
  if index ~= 1 then tab.data.borderIndex = index end
  updateBorder()
end

function Callbacks.tabBackingSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  jremove(tab.data, "backingIndex")
  local index = BackingPicker:getSelected()
  if index ~= 1 then tab.data.backingIndex = index end
  updateBacking()
end

function Callbacks.tabBorderColor(color)
  local tab = TabList:getSelected()
  if not tab then return end

  jremove(tab.data, "borderColor")
  if color then tab.data.borderColor = color end
  updateBorder()
end

function Callbacks.tabBackingColor(color)
  local tab = TabList:getSelected()
  if not tab then return end

  jremove(tab.data, "backingColor")
  if color then tab.data.backingColor = color end
  updateBacking()
end

-- the rest
function Callbacks.gridSlotChanged(slot)
  local tab = TabList:getSelected()
  if not tab then return end
  
  local page = tab.data.pages[tab.data.pageIndex]
  InvData:setPageItems(page, ItemGrid:getItems())
  save()

  updateWidgets()

  Searcher:slotUpdated(slot)
end

function Callbacks.tabSelected(tab, oldTab)
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
  BorderColorbox:setText(tab.data.borderColor)
  updateBorder()
  
  BackingPicker:setSelected(tab.data.backingIndex)
  BackingColorbox:setText(tab.data.backingColor)
  updateBacking()

  local pageIndex = math.max(1, math.min(tab.data.pageIndex, #tab.data.pages))
  local items = InvData:getPageItems(tab.data.pages[pageIndex])
  ItemGrid:setItems(items)
  Searcher:pageChanged()
  updateWidgets()
end

function Callbacks.searchButton()
  if not widget.active("search") then
    widget.setVisible("search", true)
    widget.setText("search.textbox", "")
    widget.focus("search.textbox")
    return
  end

  local text = widget.getText("search.textbox") or ""
  if text:len() > 0 then
    Searcher:start(text, true)
    return
  end

  widget.setVisible("search", false)
  Searcher:reset()
end

function Callbacks.search()
  if not widget.hasFocus("search.textbox") then return end
  local text = widget.getText("search.textbox")
  Searcher:typing(text)
end

function Callbacks.searchEnter()
  local text = widget.getText("search.textbox")
  Searcher:start(text, true)
end

function Callbacks.searchTabbed(_, prev)
  Searcher:nextResult(prev)
  widget.focus("search.textbox")
end

function Callbacks.blur()
  widget.focus("_blur")
  widget.blur("_blur")
end
