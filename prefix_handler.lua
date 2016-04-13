local domain = require('domain')

local _M = {
  err_not_found = "not_found",

  cache = ngx.shared.rise
}

function _M.handle(host) -- returns (prefix, err, err_log)
  local prefix_cache_key = host..":pfx"
  local prefix = _M.cache:get(prefix_cache_key)

  if not prefix then
    -- cache miss for HOST:prefix
    local meta, err = domain.get_meta(host)
    if err then
      return nil, _M.err_not_found, 'Failed to fetch metadata for "'..host..'" due to "'..err..'"'
    end

    if not meta.prefix then
      return nil, _M.internal_server_error, 'meta.json for "'..host..'" did not contain prefix'
    end

    prefix = meta.prefix
    _M.cache:set(host..":pfx", prefix)
  end

  return prefix, nil, nil
end

return _M
