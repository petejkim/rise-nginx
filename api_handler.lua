local _M = {
  err_not_found = "not_found",
}

local prefix_handler = require('prefix_handler')
local ssl_handler = require('ssl_handler')

local function post_invalidate(host)
  prefix_handler.invalidate_cache(host)
  ssl_handler.invalidate_cache(host)
  return '{"invalidated": true}'
end

function _M.handle(method, path) -- returns (json_body, err, err_log)
  if method == "POST" and path:find("/invalidate/") == 1 then
    local host = path:sub(#"/invalidate/" + 1)
    if #host > 1 then
      return post_invalidate(host)
    end
  end
  return '{"status": "not_found"}', _M.err_not_found, nil
end

return _M
