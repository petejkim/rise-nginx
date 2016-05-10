local domain = require('domain')

local _M = {
  err_not_found = "not_found",

  cache = ngx.shared.rise
}

function _M.handle(host) -- returns (prefix, err, err_log)
  local prefix_cache_key = host..":pfx"
  local force_https_cache_key = host..":fh"

  local prefix = _M.cache:get(prefix_cache_key)
  local force_https = _M.cache:get(force_https_cache_key)

  if not prefix or force_https == nil then
    -- cache miss for HOST:prefix
    local meta, err = domain.get_meta(host)
    if err then
      return nil, nil, _M.err_not_found, 'Failed to fetch metadata for "'..host..'" due to "'..err..'"'
    end

    if not meta.prefix then
      return nil, nil, _M.internal_server_error, 'meta.json for "'..host..'" did not contain prefix'
    end

    prefix = meta.prefix
    -- This is to make nil to false
    -- force_https is false by default
    force_https = not not meta.force_https
    _M.cache:set(prefix_cache_key, prefix)
    _M.cache:set(force_https_cache_key, force_https)
  end

  return prefix, force_https, nil, nil
end

function _M.invalidate_cache(host)
  _M.cache:delete(host..":pfx")
  _M.cache:delete(host..":fh")
end

return _M
