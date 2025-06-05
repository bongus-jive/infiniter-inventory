require "/pat/infinv/WidgetCallbacks.lua"
require "/pat/infinv/InvData.lua"

require "/pat/infinv/TabList.lua"
require "/pat/infinv/ItemGrid.lua"
require "/pat/infinv/IconPicker.lua"
require "/pat/infinv/ScrollInput.lua"

local fmt = string.format

TabList = TabListWidget:new("tabs.list", Callbacks.tabSelected)
ItemGrid = ItemGridWidget:new("slots", Callbacks.gridSlotChanged)
IconPicker = IconPickerWidget:new("tabConfig.iconList")
PageScroller = ScrollInputWidget:new("pageScroller", Callbacks.pageScrolling)

function init()
  TabList:init()
  ItemGrid:init()
  IconPicker:init()
  PageScroller:init()

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

function uninit()
  local tab = TabList:getSelected()
  if tab then
    saveCurrentPage(tab)
    tab.data.selected = true
  end

  local data = jarray()
  for i, tab in ipairs(TabList.tabs) do
    data[i] = tab.data
  end

  InvData.save(data)
end

function saveCurrentPage(tab)
  tab = tab or TabList:getSelected()
  if not tab then return end

  local index = tab.data.pageIndex
  tab.data.pages[index] = ItemGrid:getItems()
end

function updateWidgets()
  local tab = TabList:getSelected()
  local isTabSelected = tab ~= nil
  local gridHasItems = ItemGrid:hasItems()
  local isEditingTab = isTabSelected and widget.getChecked("tabConfigCheckbox")
  local enabled = isTabSelected and not isEditingTab
  
  if isEditingTab then
    local tabCount = #TabList.tabs
    local canDeleteTab = tabCount > 1 and not gridHasItems
    if canDeleteTab then
      for _, page in pairs(tab.data.pages) do
        for _, item in pairs(page) do canDeleteTab = false break end
        if not canDeleteTab then break end
      end
    end
    widget.setButtonEnabled("tabConfig.deleteTabButton", canDeleteTab)
    widget.setButtonEnabled("tabConfig.moveTabUpButton", tab.index ~= 1)
    widget.setButtonEnabled("tabConfig.moveTabDownButton",  tab.index ~= tabCount)
  end

  widget.setVisible("slots", enabled)
  widget.setVisible("pageScroller", enabled)
  widget.setVisible("tabConfig", isEditingTab)
  widget.setVisible("tabConfigBg", isEditingTab)

  widget.setButtonEnabled("sortButton", enabled)
  widget.setButtonEnabled("quickStackButton", enabled)
  widget.setButtonEnabled("prevPageButton", enabled and tab.data.pageIndex > 1)
  widget.setButtonEnabled("nextPageButton", enabled and (tab.data.pageIndex < #tab.data.pages or gridHasItems))
  widget.setButtonEnabled("tabConfigCheckbox", isTabSelected)

  widget.setText("pageLabel", tab and fmt("%s/%s", tab.data.pageIndex, #tab.data.pages) or "")
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
