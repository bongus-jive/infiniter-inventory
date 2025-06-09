require "/pat/infinv/WidgetCallbacks.lua"
require "/pat/infinv/InvData.lua"

require "/pat/infinv/TabList.lua"
require "/pat/infinv/ItemGrid.lua"
require "/pat/infinv/IconPicker.lua"
require "/pat/infinv/ScrollInput.lua"
require "/pat/infinv/PageBar.lua"

local fmt = string.format

TabList = TabListWidget:new("tabs.list", Callbacks.tabSelected)
ItemGrid = ItemGridWidget:new("gridLayout.slots", Callbacks.gridSlotChanged)
IconPicker = IconPickerWidget:new("editorLayout.settings.iconList")
PageScroller = ScrollInputWidget:new("gridLayout.pageScroller", Callbacks.pageScrolling)
PageBar = PageBarWidget:new("gridLayout.pageBar")

function init()
  TabList:init()
  ItemGrid:init()
  IconPicker:init()
  PageScroller:init()
  PageBar:init()

  local cfg = config.getParameter
  Strings = cfg("strings", {})
  Strings.tooltips = Strings.tooltips or {}
  
  local data = InvData.load()
  for _, tabData in ipairs(data) do
    local tab = TabList:newTab(tabData)
    if tabData.selected then tab:select() end
    jremove(tabData, "selected")
  end

  if #TabList.tabs == 0 then TabList:newTab() end
  if not TabList:getSelected() then TabList.tabs[1]:select() end

  updateWidgets()
end

function cursorOverride(pos)
  PageScroller:update(pos)
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

  if data.parentTabId then
    local tab = TabList.tabs[data.parentTabId]
    return tab and tab.data.label
  end
end

function shiftItemFromInventory(item) -- osb
  local remainder = ItemGrid:addItem(item)
  return remainder or true
end

function uninit()
  save()
end

function save()
  local tab = TabList:getSelected()
  if tab then
    saveCurrentPage(tab)
    tab.data.selected = true
  end

  local tabs = jarray()
  for i, tab in ipairs(TabList.tabs) do
    tabs[i] = tab.data
  end

  InvData.save(tabs)
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

  if not hasTab then widget.setChecked("tabConfigCheckbox", false) end

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
  widget.setButtonEnabled("editorLayout.settings.deleteTabButton", hasTab and not tabHasItems)

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

function updateTitle()
  local tab = TabList:getSelected()
  local subtitle = ""
  if tab then
    subtitle = tab.data.label or string.format(Strings.defaultTabSubtitle, tab.index)
  end
  pane.setTitle(Strings.title, subtitle)
end

function updateTabIcon(tab)
  if not tab then return end

  local image
  if tab.data.iconIndex == -1 then
    image = getItemIcon(tab.data.iconItem)
  else
    image = IconPicker:getImage(tab.data.iconIndex)
  end

  local rot = tab.data.iconRotation
  if rot then rot = rot * (math.pi / 180) end

  tab:setIcon(image, rot)
end

function getItemIcon(item)
  if not item then return end
  
  item = root.itemConfig(item)
  local icon = item.parameters.inventoryIcon or item.config.inventoryIcon
  if not icon then return end

  local function absolutePath(path)
    if path and path:sub(1, 1) ~= "/" then return item.directory .. path end
    return path
  end

  if type(icon) == "string" then
    return absolutePath(icon)
  end

  for _, drawable in pairs(icon) do
    drawable.image = absolutePath(drawable.image)
  end
  return icon
end

function TabList:buildTab(tab)
  local data = tab.data

  if not data.pages then data.pages = jarray() end
  if not data.pages[1] then data.pages[1] = jarray() end
  if not data.pageIndex then data.pageIndex = 1 end

  if not data.iconIndex then
    data.iconIndex = ((tab.index - 1) % self.data.defaultIconMaxIndex) + 1
  end

  updateTabIcon(tab)
end
