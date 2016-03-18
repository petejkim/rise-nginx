local api_handler = {
  err_not_found = "not_found",

  cache = ngx.shared.rise
}

local function post_invalidate(domain)
  api_handler.cache:delete(domain..":pfx")
  return '{"purged": true}'
end

function api_handler.handle(method, path) -- returns (json_body, err, err_log)
  if method == "POST" and path:find("/invalidate/") == 1 then
    local domain = path:sub(#"/invalidate/" + 1)
    if #domain > 1 then
      return post_invalidate(domain)
    end
  end
  return '{"status": "not_found"}', api_handler.err_not_found, nil
end

return api_handler
