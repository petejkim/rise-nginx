local Dict = {store={}}

local allowed_types = {
  ["string"] = true,
  ["boolean"] = true,
  ["number"] = true,
  ["nil"] = true
}

function Dict:new(d)
  d = d or {}
  setmetatable(d, self)
  self.__index = self
  return d
end

function Dict:get(key)
  return self.store[key]
end

function Dict:set(key, val)
  if allowed_types[type(val)] then
    self.store[key] = val
    return true, nil
  end
  return false, nil
end

function Dict:delete(key)
  return self:set(key, nil)
end

function Dict:flush_all()
  self.store = {}
end

return Dict
