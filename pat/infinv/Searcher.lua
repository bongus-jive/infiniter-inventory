Searcher = {}

function Searcher:update(dt)
  if self.typingTimer then
    self.typingTimer = self.typingTimer - dt
    if self.typingTimer <= 0 then
      self:start(self.typingText, false)
    end
  end
  
  if self.searchThread then
    if coroutine.status(self.searchThread) == "dead" then
      self.searchThread = nil
    else
      local success, result = coroutine.resume(self.searchThread)
      if not success then error(result) end
    end
  end
end

function Searcher:start(text, goToResult)
  self.typingTimer = nil
  if not text or text:len() == 0 then return self:reset() end
  text = text:lower()

  self.goToResult = goToResult
  if self.currentSearch == text then
    if goToResult then self:nextResult() end
    return
  end

  self.currentSearch = text
  self.searchedPages = {}

  self.searchThread = coroutine.create(self.searchAllPages)
  local success, result = coroutine.resume(self.searchThread, self)
  if not success then error(result) end
end

function Searcher:typing(text)
  if not text or text:len() == 0 then return self:reset() end
  self.typingTimer = 0.2
  self.typingText = text
end

function Searcher:reset()
  self.currentSearch = nil
  self.searchThread = nil
  self.typingText = nil
  self.searchedPages = {}
  self:clearHighlights()
end

function Searcher:restart()
  local text = self.currentSearch
  if not text then return end
  self:reset()
  self:start(text, self.goToResult)
end

function Searcher:clearHighlights()
  ItemGrid:resetHighlighted()
  TabList:resetHighlighted()
  widget.setChecked("gridLayout.prevPageButton", false)
  widget.setChecked("gridLayout.nextPageButton", false)
  widget.setText("search.results", "")
end

function Searcher:highlightResults()
  self:clearHighlights()

  local currentTab = TabList:getSelected()
  local currentIndex, currentId
  if currentTab then
    currentIndex = currentTab.data.pageIndex
    currentId = currentTab.data.pages[currentIndex]
  end

  local totalItems, totalPages = 0, 0

  for pageId, v in pairs(self.searchedPages) do
    if v.count == 0 then goto continue end

    totalItems = totalItems + v.count
    totalPages = totalPages + 1

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

  widget.setText("search.results", string.format(Strings.searchResultText, totalItems, totalPages))
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

  if not (slot and self.searchedPages[pageId]) then
    self:searchPage(pageId, pageIndex, tab)
  else
    local item = ItemGrid:getSlotItem(slot)
    local matches = self:searchItem(item)

    local pageResults = self.searchedPages[pageId]
    pageResults.slots[slot.index] = matches
    pageResults.count = 0
    for _, v in pairs(pageResults.slots) do
      if v then pageResults.count = pageResults.count + 1 end
    end
  end

  self:highlightResults()
end

function Searcher:searchPage(id, index, parent)
  local items = InvData:getPageItems(id)
  local count = 0
  local matchingSlots = {}
  for i, item in pairs(items) do
    if self:searchItem(item) then
      matchingSlots[i] = true
      count = count + 1
    end
  end
  local result = { parentTab = parent, pageIndex = index, slots = matchingSlots, count = count }
  self.searchedPages[id] = result
  return result
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

  local currentTab = TabList:getSelected()
  local currentPage
  if currentTab then
    --add current page first
    local pageIndex, pages = currentTab.data.pageIndex, currentTab.data.pages
    currentPage = pages[pageIndex]
    addPage(currentTab, pageIndex, currentPage)

    --then add the rest of the current tab's pages
    for index, id in ipairs(pages) do
      addPage(currentTab, index, id)
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
    local result = self:searchPage(page.id, page.index, page.parent)

    if result.count > 0 and not foundPage and self.goToResult then
      foundPage = true
      if page.id ~= currentPage then
        page.parent:select()
        changePage(page.index)
      end
    end

    local now = os.clock()
    if now - start > maxTime then
      start = now
      self:highlightResults()
      coroutine.yield()
    end
  end

  self:highlightResults()
end

function Searcher:nextResult(prev)
  if not self.currentSearch then return end
  
  local currentTab = TabList:getSelected()
  local currentIndex, currentId
  if currentTab then
    currentIndex = currentTab.data.pageIndex
    currentId = currentTab.data.pages[currentIndex]
  end

  local pages = {}
  local start = 1
  for _, tab in ipairs(TabList.tabs) do
    for _, id in ipairs(tab.data.pages) do
      table.insert(pages, id)
      if tab == currentTab and id == currentId then
        start = #pages
      end
    end
  end

  local count = #pages

  local init, final, step = 1, count, 1
  if prev then
    init, final, step = count - 1, 0, -1
  end

  for i = init, final, step do
    local index = ((i + start - 1) % count) + 1
    local pageId = pages[index]
    local searchedPage = self.searchedPages[pageId]
    if not searchedPage then goto continue end

    if searchedPage.count > 0 then
      searchedPage.parentTab:select()
      changePage(searchedPage.pageIndex)
      break
    end

    ::continue::
  end
end
