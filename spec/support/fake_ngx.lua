local _M = {}

_M.new = function()
  local fngx = {
    print_calls = {},
    exit_calls = {},
    status = nil,
    header = {}
  }

  fngx.reset = function()
    fngx.print_calls = {}
    fngx.exit_calls = {}
    fngx.status = nil
    fngx.header = {}
  end

  fngx.print = function(data)
    table.insert(fngx.print_calls, data)
  end

  fngx.exit = function(code)
    table.insert(fngx.exit_calls, code)
  end

  return fngx
end

return _M
