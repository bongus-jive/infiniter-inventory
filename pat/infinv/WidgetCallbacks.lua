Callbacks = {}

function Callbacks.newTabButton()
  TabList:newTab():select()
end

function Callbacks.moveTabButton(_, offset)
  local tab = TabList:getSelected()
  if not tab then return end
  tab:move(tab.index + offset)
end

function Callbacks.deleteTabButton()
  local tab = TabList:getSelected()
  if not tab then return end

  local index = tab.index
  tab:remove()

  local new = TabList.tabs[index] or TabList.tabs[index - 1]
  if new then new:select() end
end

function Callbacks.tabConfigCheckbox()
  updateWidgets()
end

function Callbacks.tabIconSelect()
  local tab = TabList:getSelected()
  if not tab then return end
  
  local icon = IconPicker:getSelected()
  tab.data.iconIndex = icon.index
  setTabIcon(tab.children.icon, icon.image)
end

function Callbacks.tabLabelTextbox()
  local text = widget.getText("tabConfig.labelTextbox")
  if text and text:len() == 0 then text = nil end
  
  local tab = TabList:getSelected()
  if not tab then return end
  tab.data.label = text

  updateTitle()
end

function Callbacks.tabConfigTextboxBlur(name)
  widget.blur("tabConfig." .. name)
end
