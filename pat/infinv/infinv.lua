require "/pat/infinv/InvData.lua"
require "/pat/infinv/TabList.lua"
require "/pat/infinv/ItemGrid.lua"
require "/pat/infinv/IconPicker.lua"

require "/pat/infinv/WidgetCallbacks.lua"

function init()
  local cfg = config.getParameter

  Strings = cfg("strings", {})
  Strings.tooltips = Strings.tooltips or {}

  TabList:init("tabs.list")
  ItemGrid:init("slots", cfg("slotCount"))
  IconPicker:init("tabConfig.iconList", root.assetJson("/pat/infinv/tabicons/tabicons.json"))
  
  local data = InvData.load()
  for _, tabData in ipairs(data) do
    local tab = TabList:newTab(tabData)
    if tabData.selected then
      tab:select()
    end
    jremove(tabData, "selected")
  end

  if #TabList.tabs == 0 then
    TabList:newTab()
  end

  if not TabList:getSelected() then
    TabList.tabs[1]:select()
  end

  updateWidgets()
end

function uninit()
  local tab = TabList:getSelected()
  if tab then
    tab.data.items = ItemGrid:getItems()
    tab.data.selected = true
  end

  local data = jarray()
  for i, tab in ipairs(TabList.tabs) do
    data[i] = tab.data
  end

  InvData.save(data)
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

function updateWidgets()
  local tabCount = #TabList.tabs
  local tab = TabList:getSelected()
  local tabSelected = tab ~= nil
  local gridHasitems = ItemGrid:hasItems()
  local editingTab = widget.getChecked("tabConfigCheckbox")

  widget.setVisible("slots", tabSelected and not editingTab)
  widget.setVisible("tabConfig", tabSelected and editingTab)
  widget.setVisible("tabConfigBg", tabSelected and editingTab)
  widget.setButtonEnabled("tabConfigCheckbox", tabSelected)
  widget.setButtonEnabled("tabConfig.moveTabUpButton", tabSelected and tab.index ~= 1)
  widget.setButtonEnabled("tabConfig.moveTabDownButton", tabSelected and tab.index ~= tabCount)
  widget.setButtonEnabled("tabConfig.deleteTabButton", tabSelected and tabCount > 1 and not gridHasitems)
end

function updateTitle()
  local tab = TabList:getSelected()
  local subtitle = ""
  if tab then
    subtitle = tab.data.label or string.format(Strings.defaultTabSubtitle, tab.index)
  end
  pane.setTitle(Strings.title, subtitle)
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

function updateTabIcon(tab)
  if not tab then return end

  local image
  if tab.data.iconIndex == -1 then
    image = getItemIcon(tab.data.iconItem)
  else
    image = IconPicker:getImage(tab.data.iconIndex)
  end

  tab:setIcon(image)
end

-- widget wrapper sludge --
function TabList:buildTab(tab)
  local data = tab.data
  if not data.iconIndex then
    data.iconIndex = ((tab.index - 1) % self.data.defaultIconIndexMax) + 1
  end

  updateTabIcon(tab)
end

function TabList:onSelect(tab, oldTab)
  if oldTab then
    oldTab.data.items = ItemGrid:getItems()
  end

  updateWidgets()

  local label = tab and tab.data.label or ""
  widget.setText("tabConfig.labelTextbox", label)
  updateTitle()

  if not tab then
    return ItemGrid:clearItems()
  end

  IconPicker:setSelected(tab.data.iconIndex or 1)
  IconPicker:setIconSlotItem(tab.data.iconItem)
  ItemGrid:setItems(tab.data.items)
end

function ItemGrid:onSlotItemChanged(slot)
  updateWidgets()
end
