local ID = "pat_infiniteinventory"
InvData = {}

function InvData.load()
  local vJson = player.getProperty(ID)
  if vJson then
    return root.loadVersionedJson(vJson, ID)
  end
  return {}
end

function InvData.save(data)
  local vJson = root.makeCurrentVersionedJson(ID, data)
  player.setProperty(ID, vJson)
end
