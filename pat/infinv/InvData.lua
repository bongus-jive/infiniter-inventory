InvData = {}

local INV_ID = "pat-infiniteinventory"
local PAGE_ID = "pat-infiniteinventory-page"
local PAGE_NAME = "pat-infiniteinventory-%s"
local fmt = string.format

function InvData:load()
  local vJson = player.getProperty(INV_ID)
  local data = vJson and root.loadVersionedJson(vJson, INV_ID) or {}
  self.data = data
  
  if not data.unusedIds then data.unusedIds = jarray() end
  if not data.bags then data.bags = {} end

  self.pages = {}
  self.newIds = {}
  self.unsavedIds = {}
  self.unusedIds = {}
  for _, id in pairs(data.unusedIds) do self.unusedIds[id] = true end

  if data._pages_2_3 then
    for id, items in pairs(data._pages_2_3) do
      self.newIds[id] = true
      self:setPageItems(id, items)
    end
    jremove(data, "_pages_2_3")
  end

  return data.bags
end

function InvData:save(bags)
  if bags then self.data.bags = bags end

  self.data.unusedIds = jarray()
  for id, _ in pairs(self.unusedIds) do
    table.insert(self.data.unusedIds, id)
  end

  local vJson = root.makeCurrentVersionedJson(INV_ID, self.data)
  player.setProperty(INV_ID, vJson)

  for _, id in pairs(self.unsavedIds) do
    local items = self.pages[id]
    local data = items and root.makeCurrentVersionedJson(PAGE_ID, items) or nil
    player.setProperty(fmt(PAGE_NAME, id), data)
  end
  self.unsavedIds = {}
end


function InvData:removePage(id)
  self.pages[id] = nil
  
  if self.newIds[id] then
    self.newIds[id] = nil
    return
  end
  
  self.unusedIds[id] = true
  table.insert(self.unsavedIds, id)
end

function InvData:newPageId()
  for id, _ in pairs(self.unusedIds) do
    self.unusedIds[id] = nil
    return id
  end

  local id = sb.makeUuid()
  self.newIds[id] = true
  return id
end

function InvData:getPageItems(id)
  if self.pages[id] then
    return self.pages[id]
  end

  local items
  local vJson = player.getProperty(fmt(PAGE_NAME, id), "undefined")
  if vJson == "undefined" then
    self.newIds[id] = true
    items = jarray()
  else
    items = vJson and root.loadVersionedJson(vJson, PAGE_ID) or jarray()
  end

  self.pages[id] = items
  return items
end

function InvData:setPageItems(id, items)
  items = items or jarray()
  self.pages[id] = items
  self.unusedIds[id] = nil
  
  if self.newIds[id] and not next(items) then return end
  
  self.newIds[id] = nil
  table.insert(self.unsavedIds, id)
end
