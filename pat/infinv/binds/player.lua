local cfg
local paneId
local openTicks

function init()
  cfg = root.assetJson("/pat/infinv/infinv.config")

  local function setLocalHandler(name, func)
    message.setHandler(name, function(_, isLocal, ...)
      if isLocal then return func(...) end
    end)
  end
  setLocalHandler("pat_infinv_open", open)
  setLocalHandler("pat_infinv_shouldClose", shouldClose)
end

function update()
  if input then
    if input.bindDown("pat_infinv", "open") then
      open()
    elseif input.bindDown("pat_infinv", "openWithInv") then
      open(true)
    end
  end

  if openTicks then
    openTicks = openTicks - 1
    if openTicks <= 0 then
      openTicks = nil
      player.interact("ScriptPane", cfg)
    end
  end
end

function open(withInventory)
  paneId = os.clock()
  cfg._paneId = paneId
  cfg.openWithInventory = withInventory
  cfg.closeWithInventory = withInventory
  openTicks = 2
end

function shouldClose(id)
  if not paneId or id == paneId then return false end
  
  openTicks = nil
  return true
end
