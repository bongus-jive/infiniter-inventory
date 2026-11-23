local cfg = { baseConfig = "/pat/infinv/infinv.config", gui = {} }
local paneId, openTicks

function init()
  setSize(storage.size)

  local function setLocalHandler(name, func)
    message.setHandler(name, function(_, isLocal, ...)
      if isLocal then return func(...) end
    end)
  end
  setLocalHandler("pat_infinv_open", open)
  setLocalHandler("pat_infinv_shouldClose", shouldClose)
  setLocalHandler("pat_infinv_setSize", setSize)
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

function setSize(size)
  if not size then
    if storage.size then jremove(storage, "size") end
    cfg.gui.pane = nil
    return
  end

  storage.size = size
  cfg.gui.pane = {
    type = "background",
    fileBody = "",
    fileFooter = "",
    fileHeader = ("/pat/infinv/images/panesize.png?scalenearest=%s;%s"):format(size[1], size[2])
  }
end
