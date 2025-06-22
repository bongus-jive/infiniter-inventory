iiData = {ID = "pat-infiniteinventory"}

function iiData:load()
  local vJson = player.getProperty(self.ID)
  if vJson then
    return root.loadVersionedJson(vJson, self.ID)
  end
  return {}
end

function iiData:save(data)
  local vJson = root.makeCurrentVersionedJson(self.ID, data)
  player.setProperty(self.ID, vJson)
end
