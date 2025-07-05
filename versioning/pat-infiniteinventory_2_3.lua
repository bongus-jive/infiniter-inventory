function update(data)
  local bags = data

  data = jobject()
  data.bags = bags
  data._pages_2_3 = jobject()

  for _, bag in ipairs(bags) do
    for index, page in ipairs(bag.pages) do
      local id = sb.makeUuid()
      local items = page
      bag.pages[index] = id
      data._pages_2_3[id] = items
    end
  end
  
  return data
end
