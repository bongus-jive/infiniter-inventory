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
BorderColorbox = ColorTextboxWidget:new("editorLayout.editorTabs.tabs.border.scrollArea.colorTextbox", Callbacks.tabBorderColor)
BackingColorbox = ColorTextboxWidget:new("editorLayout.editorTabs.tabs.backing.scrollArea.colorTextbox", Callbacks.tabBackingColor)
PageScroller = ScrollInputWidget:new("gridLayout.pageScroller", Callbacks.pageScrolling)
PageBar = PageBarWidget:new("gridLayout.pageBar")

local fmt = string.format
local shared = getmetatable''

function init()
  shared.pat_infinv_dismiss = pane.dismiss

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
    jremove(tabData, "selected")
  end

  if not selectedTab then
    selectedTab = TabList.tabs[1] or createTab()
  end
  selectedTab:select()

  updateWidgets()
end

function update(dt)
  Searcher:update(dt)
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
  if child:sub(1, 1) == "." then child = child:sub(2, -1) end

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
  
  if data.parent == IconPicker.widgetName and data.index == -1 then
    return Strings.tooltips.tabIconSlot
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
  shared.pat_infinv_dismiss = nil
  save()
end

function save()
  local bags = jarray()
  for i, tab in ipairs(TabList.tabs) do
    jremove(tab.data, "selected")
    if tab:isSelected() then tab.data.selected = true end
    
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
  
  BorderPicker:setTag("custom", tab.data.borderColor or "FFF")
  local index = tab.data.borderIndex or 1
  local image = BorderPicker:getImage(index)
  widget.setImage("border", image)
end

function updateBacking()
  local tab = TabList:getSelected()
  if not tab then return end

  BackingPicker:setTag("custom", tab.data.backingColor or "FFF")
  local index = tab.data.backingIndex or 1
  local image = BackingPicker:getImage(index)
  ItemGrid:setBackingImage(image)
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
