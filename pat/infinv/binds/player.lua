local cfg
local shared = getmetatable''

function init()
  cfg = root.assetJson("/pat/infinv/infinv.config")

  message.setHandler("pat_infinv_open", function(_, isLocal)
    if isLocal then open() end
  end)

  if storage.restore then
    open(storage.restore.inv)
    jremove(storage, "restore")
  end

  if not input then
    return script.setUpdateDelta(0)
  end
end

function update()
  if input.bindDown("pat_infinv", "open") then open(true) end
end

function open(withInventory)
  if shared.pat_infinv_dismiss then
    pcall(shared.pat_infinv_dismiss)
    shared.pat_infinv_dismiss = nil
    if withInventory then return end
  end

  cfg.openWithInventory = withInventory
  cfg.closeWithInventory = withInventory
  player.interact("ScriptPane", cfg)
end

function uninit()
  if shared.pat_infinv_dismiss then
    pcall(shared.pat_infinv_dismiss)
    shared.pat_infinv_dismiss = nil
    storage.restore = { inv = cfg.openWithInventory }
  end
end
