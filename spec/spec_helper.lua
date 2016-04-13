local config = require("config")
local spy = require('luassert.spy')
require('crypto')

config.s3_host = "test-s3.example.com"

_G.stub_fn = function(table, fn_name, fn)
  local orig_fn = table[fn_name]
  if type(orig_fn) == "function" then
    table[fn_name.."_orig"] = orig_fn
    fn = fn or function() end
    local s = spy.new(fn)
    table[fn_name] = s
    return s
  end
  return nil
end

_G.unstub_fn = function(table, fn_name)
  local orig_key = fn_name.."_orig"
  local orig_fn = table[orig_key]
  if type(orig_fn) == "function" then
    table[fn_name] = orig_fn
    table[orig_key] = nil
  end
end
