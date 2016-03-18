local Dict = {store={}}

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
  local val_t = type(val)
  if val_t == "string" or val_t == "boolean" or val_t == "number" then
    self.store[key] = val
    return true, nil
  end
  return false, nil
end

function Dict:flush_all()
  self.store = {}
end

return Dict
