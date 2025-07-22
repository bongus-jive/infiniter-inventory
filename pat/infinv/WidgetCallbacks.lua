Callbacks = {}

-- footer buttons
function Callbacks.newTabButton()
  local data = sb.jsonMerge(InvData.data.bagDefaults)
  createTab(data):select()
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

  if item then
    jremove(item, "count")
    if jsize(item.parameters) == 0 then jremove(item, "parameters") end
  end
  tab.data.iconItem = item
  updateTabIcon(tab)
end

function Callbacks.tabIconRotateButton()
  local tab = TabList:getSelected()
  if not tab then return end

  local rot = tab.data.iconRotation or 360
  rot = rot - 90
  tab.data.iconRotation = rot > 0 and rot or nil

  updateTabIcon(tab)
end

-- tab label
function Callbacks.tabLabelTextbox()
  local tab = TabList:getSelected()
  if not tab then return end

  local text = widget.getText("editorLayout.labelTextbox")
  
  tab.data.label = nil
  if text and text:len() > 0 then
    tab.data.label = text
  end

  updateSubtitle()
end

-- tab customization
function Callbacks.tabBorderSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  local index = BorderPicker:getSelected()
  tab.data.borderIndex = index ~= 1 and index or nil
  updateBorder()
  updateTabDefaultButtons()
end

function Callbacks.tabBackingSelect()
  local tab = TabList:getSelected()
  if not tab then return end

  local index = BackingPicker:getSelected()
  tab.data.backingIndex = index ~= 1 and index or nil
  updateBacking()
  updateTabDefaultButtons()
end

function Callbacks.tabBorderColor(color)
  local tab = TabList:getSelected()
  if not tab then return end

  tab.data.borderColor = color
  updateBorder()
  updateTabDefaultButtons()
end

function Callbacks.tabBackingColor(color)
  local tab = TabList:getSelected()
  if not tab then return end

  tab.data.backingColor = color
  updateBacking()
  updateTabDefaultButtons()
end

function Callbacks.tabSetDefault()
  local tab = TabList:getSelected()
  if not tab then return end

  local data = tab.data
  local defaults = InvData.data.bagDefaults
  defaults.borderIndex = data.borderIndex
  defaults.borderColor = data.borderColor
  defaults.backingIndex = data.backingIndex
  defaults.backingColor = data.backingColor
  updateTabDefaultButtons()
end

function Callbacks.tabResetToDefault()
  local tab = TabList:getSelected()
  if not tab then return end

  local data = tab.data
  local defaults = InvData.data.bagDefaults
  data.borderIndex = defaults.borderIndex
  data.borderColor = defaults.borderColor
  data.backingIndex = defaults.backingIndex
  data.backingColor = defaults.backingColor
  updateBorder()
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

  updateBorder()
  updateBacking()
  updateTabDefaultButtons()

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
