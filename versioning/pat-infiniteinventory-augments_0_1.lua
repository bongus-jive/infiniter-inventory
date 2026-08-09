local function absolutePath(directory, file)
  if file and file:sub(1, 1) ~= "/" then return directory .. file end
  return file
end

local function makeCallbacks(itemDesc, itemConfig, instance)
  local rand = sb.makeRandomSource()

  config = {}
  function config.getParameter(path, default)
    return sb.jsonQuery(instance, path, default) end

  item = {}
  function item.name()
    return itemDesc.name end

  function item.count()
    return itemDesc.count end

  function item.setCount(count)
    count = math.max(0, count)
    itemDesc.count = math.min(count, item.maxStack())
    return count - itemDesc.count
  end

  function item.maxStack()
    return instance.maxStack or root.assetJson("/items/defaultParameters.config:defaultMaxStack") end

  function item.matches(desc, exact)
    return root.itemDescriptorsMatch(itemDesc, desc, exact) end

  function item.consume(count)
    if itemDesc.count >= count then
      itemDesc.count = math.max(0, itemDesc.count - count)
      return true
    end
    return false
  end

  function item.empty()
    return itemDesc.count <= 0 end

  function item.descriptor()
    return sb.jsonMerge(itemDesc) end

  function item.description()
    return instance.description or "" end

  function item.friendlyName()
    return instance.shortdescription or "" end

  function item.price()
    return instance.price * itemDesc.count end

  function item.fuelAmount()
    return math.max(0, math.floor(instance.fuelAmount or 0)) end

  function item.largeImage()
    return absolutePath(itemConfig.directory, instance.largeImage) end

  function item.tooltipKind()
    return instance.tooltipKind or "" end

  function item.category()
    return instance.category or "" end

  function item.pickupSound()
    local sounds = instance.pickupSounds or {}
    if #sounds == 0 then sounds = root.assetJson("/items/defaultParameters.config:pickupSounds") end
    return sounds[rand:randUInt(#sounds)]
  end

  function item.twoHanded()
    return instance.twoHanded == true end

  function item.timeToLive()
    return instance.timeToLive or root.assetJson("/items/defaultParameters.config:defaultTimeToLive") end

  function item.learnBlueprintsOnPickup()
    if not instance.learnBlueprintsOnPickup then return {} end
    local list = jarray()
    for i, blue in ipairs(instance.learnBlueprintsOnPickup) do
      list[i] = root.createItem(blue)
    end
    return list
  end

  function item.hasItemTag(tag)
    return root.itemHasTag(itemDesc.name, tag) end

  function item.rarityString()
    return instance.rarity:lower() end

  do local rarities = { common = 0, uncommon = 1, rare = 2, legendary = 3, essential = 4 }
    function item.rarity()
      return rarities[instance.rarity:lower()] end
  end
  
  -- todo
  function item.iconDrawables() error() end
  function item.dropDrawables() error() end
  function item.pickupQuestTemplates() error() end
end

function update(data)
  assert(data[1] and data[2], "that's not items")

  local targetItem = root.createItem(data[1])
  local augmentItem = root.createItem(data[2])

  assert(root.itemType(augmentItem.name) == "augmentitem", "that's not an augment")
  
  local augmentConfig = root.itemConfig(augmentItem)
  local instance = sb.jsonMerge(augmentConfig.config, augmentConfig.parameters)
  local applied = false

  if instance.scripts then
    makeCallbacks(augmentItem, augmentConfig, instance)
    
    for _, script in ipairs(instance.scripts) do
      script = absolutePath(augmentConfig.directory, script)
      require(script)
    end

    if type(apply) == "function" then
      local output, consume = apply(targetItem)
      if output then
        applied = true
        targetItem = output
        if consume and consume > 0 then item.consume(consume) end
      end
    end
  end

  return { applied, targetItem, augmentItem }
end
