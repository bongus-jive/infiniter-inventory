local function absolutePath(directory, file)
  if file and file:sub(1, 1) ~= "/" then return directory .. file end
  return file
end

local function makeCallbacks(itemDesc, instance, directory)
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
    return instance.largeImage and absolutePath(directory, instance.largeImage) or "" end

  function item.tooltipKind()
    return instance.tooltipKind or "" end

  function item.category()
    return instance.category or "" end

  function item.pickupSound()
    local sounds = instance.pickupSounds or {}
    if #sounds == 0 then sounds = root.assetJson("/items/defaultParameters.config:pickupSounds") end
    return sounds[rand:randUInt(1, #sounds)]
  end

  function item.twoHanded()
    return instance.twoHanded == true end

  function item.timeToLive()
    return instance.timeToLive or root.assetJson("/items/defaultParameters.config:defaultTimeToLive") end

  function item.learnBlueprintsOnPickup()
    if not instance.learnBlueprintsOnPickup then return {} end
    local list = {}
    for i, blue in ipairs(instance.learnBlueprintsOnPickup) do
      list[i] = {name = blue, count = 1, parameters = {}}
    end
    return sb.jsonMerge(list)
  end

  function item.hasItemTag(tag)
    return root.itemHasTag(itemDesc.name, tag) end

  function item.rarityString()
    return instance.rarity:lower() end

  do local rarities = { common = 0, uncommon = 1, rare = 2, legendary = 3, essential = 4 }
    function item.rarity()
      return rarities[instance.rarity:lower()] end
  end

  do
    local function drawableMakeImage(image, position)
      image = absolutePath(directory, image)
      local size = root.imageSize(image)
      return {
        image = image,
        position = position or {0, 0},
        transformation = {{1, 0, -size[1] / 2}, {0, 1, -size[2] / 2}, {0, 0, 1} },
        color = {255, 255, 255},
        fullbright = false
      }
    end

    local function combineBox(a, b)
      if not b then return end
      a[1] = math.min(a[1], b[1])
      a[2] = math.min(a[2], b[2])
      a[3] = math.max(a[3], b[3] or b[1])
      a[4] = math.max(a[4], b[4] or b[2])
    end

    local function getBoundBox(draw)
      local reg = root.nonEmptyRegion(draw.image)
      if not reg then return end

      local mat = draw.transformation
      local function transform(vec)
        local x = (mat[1][1] * vec[1]) + (mat[1][2] * vec[2]) + mat[1][3]
        local y = (mat[2][1] * vec[1]) + (mat[2][2] * vec[2]) + mat[2][3]
        return {x, y}
      end
      
      local box = {0, 0, 0, 0}
      combineBox(box, transform{reg[1], reg[2]})
      combineBox(box, transform{reg[3], reg[2]})
      combineBox(box, transform{reg[1], reg[4]})
      combineBox(box, transform{reg[3], reg[4]})

      local pos = draw.position
      box[1], box[3] = box[1] + pos[1], box[3] + pos[1]
      box[2], box[4] = box[2] + pos[2], box[4] + pos[2]

      return box
    end

    local function scaleDrawables(drawables, s)
      for _, d in ipairs(drawables) do
        local t = d.transformation
        t[1] = {t[1][1] * s, t[1][2] * s, t[1][3] * s}
        t[2] = {t[2][1] * s, t[2][2] * s, t[2][3] * s}
        d.position[1] = d.position[1] * s
        d.position[2] = d.position[2] * s
      end
      return drawables
    end

    function item.iconDrawables()
      local drawables = {}
      local icon = instance.inventoryIcon or root.assetJson("/items/defaultParameters.config:missingIcon")
      if type(icon) == "table" then
        for i, draw in ipairs(icon) do
          drawables[i] = drawableMakeImage(draw.image, sb.jsonQuery(draw, "position", {0, 0}))
        end
      else
        drawables[1] = drawableMakeImage(icon)
      end

      local box = {0, 0, 0, 0}
      for _, draw in ipairs(drawables) do
        combineBox(box, getBoundBox(draw))
      end
      
      local center = {(box[1] + box[3]) / 2, (box[2] + box[4]) / 2}
      for _, draw in ipairs(drawables) do
        draw.position[1] = draw.position[1] - center[1]
        draw.position[2] = draw.position[2] - center[2]
      end
      
      local zoom = 16 / math.max(box[3] - box[1], box[4] - box[2])
      if zoom < 1 then scaleDrawables(drawables, zoom) end

      return sb.jsonMerge(drawables)
    end

    function item.dropDrawables()
      return scaleDrawables(item.iconDrawables(), 0.125)
    end
  end

  --todo
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
    makeCallbacks(augmentItem, instance, augmentConfig.directory)
    
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
