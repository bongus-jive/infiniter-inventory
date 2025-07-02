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

  local vJson = player.getProperty("pat-infiniteinventory")
  local invData = vJson and root.loadVersionedJson(vJson, "pat-infiniteinventory") or {}

  local selectedTab
  for _, tabData in ipairs(invData) do
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
  shared.pat_infinv_dismiss = nil
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

  local vJson = root.makeCurrentVersionedJson("pat-infiniteinventory", tabs)
  player.setProperty("pat-infiniteinventory", vJson)
end

function saveCurrentPage(tab)
  tab = tab or TabList:getSelected()
  if not tab then return end

  local index = tab.data.pageIndex
  tab.data.pages[index] = ItemGrid:getItems()
end

function updateWidgets()
  local tab = TabList:getSelected()

  local enabled = tab ~= nil
  widget.setVisible("gridLayout", enabled)
  widget.setVisible("editorLayout", enabled and widget.getChecked("tabConfigCheckbox"))
  widget.setButtonEnabled("sortButton", enabled)
  widget.setButtonEnabled("quickStackButton", enabled)
  widget.setButtonEnabled("quickMoveCheckbox", enabled)

  if not tab then return end
  local pages = tab.data.pages or {}
  local pageIndex, pageCount = tab.data.pageIndex or 0, #pages

  if next(pages[#pages]) then pageCount = pageCount + 1 end

  local tabHasItems = false
  for _, items in pairs(pages) do
    if next(items) then tabHasItems = true break end
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
  if not data.pages[1] then data.pages[1] = jarray() end
  if not data.pageIndex then data.pageIndex = 1 end
  if not data.iconIndex then
    data.iconIndex = ((tab.index - 1) % TabList.data.defaultIconMaxIndex) + 1
  end

  updateTabIcon(tab)
  return tab
end
