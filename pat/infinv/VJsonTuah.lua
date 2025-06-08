VJsonTuah = {}

function VJsonTuah:new(id)
  local new = {}
  setmetatable(new, {__index = self})
  new.ID = id
  return new
end

function VJsonTuah:load()
  local vJson = player.getProperty(self.ID)
  if vJson then
    return root.loadVersionedJson(vJson, self.ID)
  end
  return {}
end

function VJsonTuah:save(data)
  local vJson = root.makeCurrentVersionedJson(self.ID, data)
  player.setProperty(self.ID, vJson)
end
