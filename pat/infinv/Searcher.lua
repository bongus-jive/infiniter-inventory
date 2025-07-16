Searcher = {}

function Searcher:update()
  if self.searchThread then
    if coroutine.status(self.searchThread) == "dead" then
      self.searchThread = nil
    else
      local success, result = coroutine.resume(self.searchThread)
      if not success then error(result) end
    end
  end
end

function Searcher:start(name)
  if not name or name:len() == 0 then return self:reset() end

  self.currentSearch = name:lower()
  self.searchedPages = {}

  self.searchThread = coroutine.create(self.searchAllPages)
  local success, result = coroutine.resume(self.searchThread, self)
  if not success then error(result) end
end

function Searcher:reset()
  self.currentSearch = nil
  self.searchThread = nil
  self.searchedPages = {}
  self:clearHighlights()
end

function Searcher:clearHighlights()
  ItemGrid:resetHighlighted()
  for _, tab in pairs(TabList.tabs) do
    tab:setHighlighted(false)
  end
  widget.setChecked("gridLayout.prevPageButton", false)
  widget.setChecked("gridLayout.nextPageButton", false)
end

function Searcher:highlightResults()
  self:clearHighlights()

  local currentTab = TabList:getSelected()
  local currentIndex, currentId
  if currentTab then
    currentIndex = currentTab.data.pageIndex
    currentId = currentTab.data.pages[currentIndex]
  end

  for pageId, v in pairs(self.searchedPages) do
    for _, matches in pairs(v.slots) do
      if matches then goto hasItem end
    end
    goto continue
    ::hasItem::

    v.parentTab:setHighlighted(true)

    if pageId == currentId then
      for index, matches in pairs(v.slots) do
        ItemGrid:setSlotHighlighted(index, matches)
      end
      goto continue
    end
    
    if v.parentTab == currentTab then
      if v.pageIndex < currentIndex then
        widget.setChecked("gridLayout.prevPageButton", true)
      elseif v.pageIndex > currentIndex then
        widget.setChecked("gridLayout.nextPageButton", true)
      end
    end

    ::continue::
  end
end

function Searcher:pageChanged()
  if not self.currentSearch then return end
  self:highlightResults()
end

function Searcher:slotUpdated(slot)
  if not self.currentSearch then return end

  local tab = TabList:getSelected()
  if not tab then return end

  local pageIndex = tab.data.pageIndex
  local pageId = tab.data.pages[pageIndex]

  if slot and self.searchedPages[pageId] then
    local item = ItemGrid:getSlotItem(slot)
    local matches = self:searchItem(item)
    self.searchedPages[pageId].slots[slot.index] = matches
  else
    local slots = self:searchPage(pageId)
    self.searchedPages[pageId] = { parentTab = tab, pageIndex = pageIndex, slots = slots }
  end

  self:highlightResults()
end

function Searcher:searchPage(id)
  local items = InvData:getPageItems(id)
  local count = 0
  local matchingSlots = {}
  for i, item in pairs(items) do
    if self:searchItem(item) then
      matchingSlots[i] = true
      count = count + 1
    end
  end
  return matchingSlots, count
end

function Searcher:searchItem(item)
  if not item then return false end

  local text = self.currentSearch

  if item.name:lower():find(text, nil, true) then
    return true
  end

  local cfg = root.itemConfig(item).config
  local params = item.parameters

  local shortdesc = params.shortdescription or cfg.shortdescription or ""
  shortdesc = shortdesc:gsub("(%b^;)", ""):lower()
  if shortdesc:find(text, nil, true) then
    return true
  end

  local desc = params.description or cfg.description or ""
  desc = desc:gsub("(%b^;)", ""):lower()
  if desc:find(text, nil, true) then
    return true
  end

  return false
end

function Searcher:searchAllPages()
  local pageList = {}
  local pageKeys = {}

  local function addPage(parent, index, id)
    if pageKeys[id] then return end
    pageKeys[id] = true
    table.insert(pageList, { parent = parent, index = index, id = id })
  end

  local selectedTab = TabList:getSelected()
  local currentPage
  if selectedTab then
    --add current page first
    local pageIndex, pages = selectedTab.data.pageIndex, selectedTab.data.pages
    currentPage = pages[pageIndex]
    addPage(selectedTab, pageIndex, currentPage)

    --then add the rest of the current tab's pages
    for index, id in ipairs(pages) do
      addPage(selectedTab, index, id)
    end
  end

  local tabs = TabList.tabs
  for _, tab in ipairs(tabs) do
    for index, id in ipairs(tab.data.pages) do
      addPage(tab, index, id)
    end
  end

  coroutine.yield()

  local maxTime = script.updateDt() * 0.8
  local start = os.clock()
  local foundPage = false

  for _, page in ipairs(pageList) do
    local slots, count = self:searchPage(page.id)
    self.searchedPages[page.id] = { parentTab = page.parent, pageIndex = page.index, slots = slots }

    if count > 0 and not foundPage then
      foundPage = true
      if page.id ~= currentPage then
        page.parent:select()
        changePage(page.index)
      end
    end

    local now = os.clock()
    if now - start > maxTime then
      start = now
      coroutine.yield()
    end
  end

  self:highlightResults()
end
