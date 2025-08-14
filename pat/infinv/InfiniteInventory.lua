require "/pat/infinv/InvData.lua"
require "/pat/infinv/Searcher.lua"
require "/pat/infinv/WidgetCallbacks.lua"
require "/pat/infinv/widgets/TabList.lua"
require "/pat/infinv/widgets/ItemGrid.lua"
require "/pat/infinv/widgets/ImagePicker.lua"
require "/pat/infinv/widgets/IconPicker.lua"
require "/pat/infinv/widgets/ScrollInput.lua"
require "/pat/infinv/widgets/PageBar.lua"
require "/pat/infinv/widgets/ColorTextbox.lua"

TabList = TabListWidget:new("bagTabs.list", Callbacks.tabSelected)
ItemGrid = ItemGridWidget:new("gridLayout.slots", Callbacks.gridSlotChanged)
IconPicker = IconPickerWidget:new("editorLayout.editorTabs.tabs.icon.scrollArea.list", Callbacks.tabIconSlot)
BorderPicker = ImagePickerWidget:new("editorLayout.editorTabs.tabs.border.scrollArea.list")
BackingPicker = ImagePickerWidget:new("editorLayout.editorTabs.tabs.backing.scrollArea.list")
BorderColorbox = ColorTextboxWidget:new("editorLayout.editorTabs.tabs.border.colorTextbox", Callbacks.tabBorderColor)
BackingColorbox = ColorTextboxWidget:new("editorLayout.editorTabs.tabs.backing.colorTextbox", Callbacks.tabBackingColor)
PageScroller = ScrollInputWidget:new("gridLayout.pageScroller", Callbacks.pageScrolling)
PageBar = PageBarWidget:new("gridLayout.pageBar")

local fmt = string.format

function init()
  PaneId = config.getParameter("_paneId")
  restorePosition()

  TabList:init()
  ItemGrid:init()
  IconPicker:init()
  BorderPicker:init()
  BackingPicker:init()
  BorderColorbox:init()
  BackingColorbox:init()
  PageScroller:init()
  PageBar:init()

  Strings = config.getParameter("strings", {})
  Strings.tooltips = Strings.tooltips or {}

  local bags = InvData:load()
  local selectedTab
  for _, tabData in ipairs(bags) do
    local tab = createTab(tabData)

    if tabData.selected then selectedTab = tab end
  end

  if not selectedTab then
    selectedTab = TabList.tabs[1] or createTab()
  end
  selectedTab:select()

  updateWidgets()
end

function update(dt)
  local playerId = player.id()
  if playerId ~= 0 then
    local shouldClose = world.sendEntityMessage(playerId, "pat_infinv_shouldClose", PaneId):result()
    if shouldClose then
      return pane.dismiss()
    end
  end

  Searcher:update(dt)
  ItemGrid:update(dt)
  PageBar:update()

  if not BlockQuickMoveIn and widget.getChecked("gridLayout.quickMoveCheckbox") and TabList:getSelected() then
    local item = player.swapSlotItem()
    if item then
      local remainder = ItemGrid:addItem(item)
      player.setSwapSlotItem(remainder)
    end
  end

  BlockQuickMoveIn = false
end

function createTooltip(pos)
  local child = widget.getChildAt(pos)
  if not child then return end
  if child:sub(1, 1) == "." then child = child:sub(2) end

  if Strings.tooltips[child] then
    return Strings.tooltips[child]
  end

  local data = widget.getData(child)
  if type(data) ~= "table" then return end

  if data.tooltipKey then
    return Strings.tooltips[data.tooltipKey]
  end

  if data.parent == TabList.widgetName then
    local tab = TabList.tabs[data.index]
    return tab and tab.data.label
  end
end

function cursorOverride(pos)
  BlockQuickMoveIn = true
  PageScroller:update(pos)
end

function shiftItemFromInventory(item) -- osb
  local tab = TabList:getSelected()
  if not tab then return end
  
  local remainder = ItemGrid:addItem(item)
  return remainder or true
end

function uninit()
  save()
  storePosition()
end

function save()
  local bags = jarray()
  for i, tab in ipairs(TabList.tabs) do
    tab.data.selected = tab:isSelected() or nil
    bags[i] = tab.data
  end

  InvData:save(bags)
end

function updateWidgets()
  local tab = TabList:getSelected()

  local enabled = tab ~= nil
  widget.setVisible("gridLayout", enabled)
  widget.setVisible("editorLayout", enabled and widget.getChecked("tabConfigCheckbox"))

  if not tab then return end
  local pages = tab.data.pages or {}
  local pageIndex = tab.data.pageIndex or 0
  local pageCount = getMaxPages()

  local tabHasItems = ItemGrid:hasItems()
  if not tabHasItems then
    for _, id in pairs(pages) do
      local items = InvData:getPageItems(id)
      if next(items) then tabHasItems = true break end
    end
  end

  PageBar:set(pageIndex, pageCount)
  widget.setText("gridLayout.pageLabel", fmt(Strings.pageText, pageIndex, pageCount))
  
  widget.setButtonEnabled("gridLayout.prevPageButton", pageIndex > 1)
  widget.setButtonEnabled("gridLayout.nextPageButton", pageIndex < pageCount)
  widget.setButtonEnabled("editorLayout.moveTabUpButton", tab.index ~= 1)
  widget.setButtonEnabled("editorLayout.moveTabDownButton", tab.index ~= #TabList.tabs)
  widget.setButtonEnabled("editorLayout.deleteTabButton", not tabHasItems)
end

function updateSubtitle()
  local tab = TabList:getSelected()
  local subtitle = ""
  if tab then
    subtitle = tab.data.label or fmt(Strings.defaultTabSubtitle, tab.index)
  end
  widget.setText("subtitleText", fmt("^shadow;%s", subtitle))
end

function updateTabIcon(tab)
  if not tab then return end

  local image = IconPicker:getImage(tab.data.iconIndex, tab.data.iconItem)
  local rot = tab.data.iconRotation
  if rot then rot = rot * (math.pi / 180) end

  tab:setIcon(image, rot)
end

function updateBorder()
  local tab = TabList:getSelected()
  if not tab then return end
  
  local data = tab.data
  BorderPicker:setSelected(data.borderIndex)
  BorderPicker:setTag("custom", data.borderColor or "FFF")
  BorderColorbox:setText(data.borderColor)

  local image = BorderPicker:getImage(data.borderIndex)
  widget.setImage("border", image)
end

function updateBacking()
  local tab = TabList:getSelected()
  if not tab then return end

  local data = tab.data
  BackingPicker:setSelected(data.backingIndex)
  BackingPicker:setTag("custom", data.backingColor or "FFF")
  BackingColorbox:setText(data.backingColor)

  local image = BackingPicker:getImage(data.backingIndex)
  ItemGrid:setBackingImage(image)

  widget.setChecked("editorLayout.editorTabs.tabs.backing.fullCheckbox", data.backingWhenFull or false)
  ItemGrid:setBackingAffinity(data.backingWhenFull)
end

function updateTabDefaultButtons()
  local tab = TabList:getSelected()
  if not tab then return end

  local data = tab.data
  local defaults = InvData.data.bagDefaults

  local enabled = defaults.borderIndex ~= data.borderIndex
    or defaults.borderColor ~= data.borderColor
    or defaults.backingIndex ~= data.backingIndex
    or defaults.backingColor ~= data.backingColor
    or defaults.backingWhenFull ~= data.backingWhenFull

  widget.setButtonEnabled("editorLayout.editorTabs.tabs.border.setDefault", enabled)
  widget.setButtonEnabled("editorLayout.editorTabs.tabs.backing.setDefault", enabled)
  widget.setButtonEnabled("editorLayout.editorTabs.tabs.border.reset", enabled)
  widget.setButtonEnabled("editorLayout.editorTabs.tabs.backing.reset", enabled)
end

function createTab(data)
  local tab = TabList:newTab(data)
  data = tab.data

  if not data.pages then data.pages = jarray() end
  if not data.pages[1] then data.pages[1] = InvData:newPageId() end
  if not data.pageIndex then data.pageIndex = 1 end
  if not data.iconIndex then
    data.iconIndex = ((tab.index - 1) % TabList.data.defaultIconMaxIndex) + 1
  end

  updateTabIcon(tab)
  return tab
end

function setPageBoxEnabled(enabled)
  widget.setVisible("gridLayout.pageTextbox", enabled)
  widget.setVisible("gridLayout.pageTextboxBg", enabled)
  widget.setVisible("gridLayout.pageLabel", not enabled)
end

function changePage(newIndex)
  local tab = TabList:getSelected()
  if not tab then return end

  local pages, currentIndex = tab.data.pages, tab.data.pageIndex
  local maxPages = getMaxPages()
  
  newIndex = math.max(1, math.min(newIndex, maxPages))
  if newIndex == currentIndex then return end

  while currentIndex == maxPages and currentIndex > newIndex do
    local page = pages[currentIndex]
    local items = InvData:getPageItems(page)
    if next(items) then break end

    InvData:removePage(page)
    table.remove(pages)
    currentIndex, maxPages = currentIndex - 1, maxPages - 1
  end

  newIndex = math.min(newIndex, maxPages)
  tab.data.pageIndex = newIndex

  if not pages[newIndex] then
    pages[newIndex] = InvData:newPageId()
    save()
  end
  local items = InvData:getPageItems(pages[newIndex])
  ItemGrid:setItems(items)
  Searcher:pageChanged()
  updateWidgets()
end

function getMaxPages()
  local tab = TabList:getSelected()
  if not tab then return end

  local maxPages = #tab.data.pages

  local lastPageItems = InvData:getPageItems(tab.data.pages[maxPages])
  if next(lastPageItems) then maxPages = maxPages + 1 end

  return maxPages
end

function storePosition()
  if not pane.getPosition or not root.setConfiguration then return end
  root.setConfiguration("pat_infinv_position", pane.getPosition())
end

function restorePosition()
  if not pane.setPosition or not root.getConfiguration or not pane.getSize or not interface.bindCanvas then return end

  local pos = root.getConfiguration("pat_infinv_position")
  if not pos then return end

  local size = pane.getSize()
  local bounds = interface.bindCanvas("voice"):size()
  pos[1] = math.max(0, math.min(pos[1], bounds[1] - size[1]))
  pos[2] = math.max(0, math.min(pos[2], bounds[2] - size[2]))
  
  pane.setPosition(pos)
end
