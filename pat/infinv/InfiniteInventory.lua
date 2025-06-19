require "/pat/infinv/WidgetCallbacks.lua"
require "/pat/infinv/VJsonTuah.lua"
require "/pat/infinv/widgets/TabList.lua"
require "/pat/infinv/widgets/ItemGrid.lua"
require "/pat/infinv/widgets/ImagePicker.lua"
require "/pat/infinv/widgets/IconPicker.lua"
require "/pat/infinv/widgets/ScrollInput.lua"
require "/pat/infinv/widgets/PageBar.lua"

InvData = VJsonTuah:new("pat-infiniteinventory")
TabList = TabListWidget:new("tabs.list", Callbacks.tabSelected)
ItemGrid = ItemGridWidget:new("gridLayout.slots", Callbacks.gridSlotChanged)
IconPicker = IconPickerWidget:new("editorLayout.editorTabs.tabs.icon.scrollArea.list", Callbacks.tabIconSlot)
BorderPicker = ImagePickerWidget:new("editorLayout.editorTabs.tabs.border.scrollArea.list")
BackingPicker = ImagePickerWidget:new("editorLayout.editorTabs.tabs.backing.scrollArea.list")
PageScroller = ScrollInputWidget:new("gridLayout.pageScroller", Callbacks.pageScrolling)
PageBar = PageBarWidget:new("gridLayout.pageBar")

local fmt = string.format

function init()
  TabList:init()
  ItemGrid:init()
  IconPicker:init()
  BorderPicker:init()
  BackingPicker:init()
  PageScroller:init()
  PageBar:init()

  local cfg = config.getParameter
  Strings = cfg("strings", {})
  Strings.tooltips = Strings.tooltips or {}
  
  local data = InvData:load()
  for _, tabData in ipairs(data) do
    createNewTab(tabData)
  end

  if #TabList.tabs == 0 then createNewTab():select() end
  if not TabList:getSelected() then TabList.tabs[1]:select() end

  updateWidgets()
end

function update()
  PageBar:update()

  local item = player.swapSlotItem()

  if item and not HadSwapItem and not BlockQuickMoveIn and widget.getChecked("quickMoveCheckbox") and TabList:getSelected() then
    local remainder = ItemGrid:addItem(item)
    player.setSwapSlotItem(remainder)
  end

  HadSwapItem = item ~= nil
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
  save()
end

function save()
  local tabs = jarray()
  for i, tab in ipairs(TabList.tabs) do
    jremove(tab.data, "selected")
    if tab:isSelected() then
      tab.data.selected = true
      saveCurrentPage(tab)
    end
    
    tabs[i] = tab.data
  end

  InvData:save(tabs)
end

function saveCurrentPage(tab)
  tab = tab or TabList:getSelected()
  if not tab then return end

  local index = tab.data.pageIndex
  tab.data.pages[index] = ItemGrid:getItems()
end

function updateWidgets()
  local tab = TabList:getSelected()
  local hasTab = tab ~= nil
  local tabCount = #TabList.tabs
  local pageIndex = tab and tab.data.pageIndex or 0
  local pageCount = tab and #tab.data.pages or 0

  local gridHasItems = ItemGrid:hasItems()
  local tabHasItems = gridHasItems
  if not tabHasItems and pageCount > 1 then
    for _, page in pairs(tab.data.pages) do
      if next(page) then tabHasItems = true break end
    end
  end

  local editMode = hasTab and widget.getChecked("tabConfigCheckbox")
  widget.setVisible("gridLayout", hasTab and not editMode)
  widget.setVisible("editorLayout", editMode)

  widget.setButtonEnabled("tabConfigCheckbox", hasTab)
  widget.setButtonEnabled("sortButton", hasTab and not editMode)
  widget.setButtonEnabled("quickStackButton", hasTab and not editMode)
  widget.setButtonEnabled("gridLayout.prevPageButton", hasTab and pageIndex > 1)
  widget.setButtonEnabled("gridLayout.nextPageButton", hasTab and (pageIndex < pageCount or gridHasItems))

  widget.setButtonEnabled("editorLayout.settings.moveTabUpButton", hasTab and tab.index ~= 1)
  widget.setButtonEnabled("editorLayout.settings.moveTabDownButton", hasTab and tab.index ~= tabCount)
  widget.setButtonEnabled("editorLayout.settings.deleteTabButton", hasTab and tabCount > 1 and not tabHasItems)

  local maxPages = pageCount
  if tab then
    if pageIndex == pageCount then
      if gridHasItems then maxPages = maxPages + 1 end
    elseif next(tab.data.pages) then
      maxPages = maxPages + 1
    end
  end
  widget.setText("gridLayout.pageLabel", tab and fmt(Strings.pageText, pageIndex, maxPages) or "")
  PageBar:set(pageIndex, maxPages)
end

function updateSubtitle()
  local tab = TabList:getSelected()
  local subtitle = ""
  if tab then
    subtitle = tab.data.label or string.format(Strings.defaultTabSubtitle, tab.index)
  end
  widget.setText("subtitleText", subtitle)
end

function updateTabIcon(tab)
  if not tab then return end

  local image = IconPicker:getImage(tab.data.iconIndex, tab.data.iconItem)
  local rot = tab.data.iconRotation
  if rot then rot = rot * (math.pi / 180) end

  tab:setIcon(image, rot)
end

function createNewTab(data)
  local tab = TabList:newTab(data)
  data = tab.data

  if data.selected then tab:select() end
  jremove(data, "selected")

  if not data.pages then data.pages = jarray() end
  if not data.pages[1] then data.pages[1] = jarray() end
  if not data.pageIndex then data.pageIndex = 1 end
  if not data.iconIndex then
    data.iconIndex = ((tab.index - 1) % TabList.data.defaultIconMaxIndex) + 1
  end

  updateTabIcon(tab)
  return tab
end
