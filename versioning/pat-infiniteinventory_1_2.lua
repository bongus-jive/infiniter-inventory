function update(data)
  for _, bag in ipairs(data) do
    bag.pageIndex = 1
    bag.pages = jarray()
    bag.pages[1] = bag.items
    jremove(bag, "items")
  end
  
  return data
end
