local domain = require('domain')

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
  new_tab = function (narr, nrec) return {} end
end

local _M = {
  err_not_found = "not_found",

  cache = ngx.shared.rise
}

function _M.handle(host) -- returns (meta = {prefix, force_https, basic_auth_username, basic_auth_password}, err, err_log)
  local prefix_cache_key = host..":pfx"
  local force_https_cache_key = host..":fh"
  local basic_auth_username_cache_key = host..":bau"
  local basic_auth_password_cache_key = host..":bap"

  local prefix = _M.cache:get(prefix_cache_key)
  local force_https = _M.cache:get(force_https_cache_key)
  local basic_auth_username = _M.cache:get(basic_auth_username_cache_key)
  local basic_auth_password = _M.cache:get(basic_auth_password_cache_key)

  if not prefix or force_https == nil then
    -- cache miss for HOST:prefix
    local meta, err = domain.get_meta(host)
    if err then
      return nil, _M.err_not_found, 'Failed to fetch metadata for "'..host..'" due to "'..err..'"'
    end

    if not meta.prefix then
      return nil, _M.internal_server_error, 'meta.json for "'..host..'" did not contain prefix'
    end

    prefix = meta.prefix
    -- This is to make nil to false
    -- force_https is false by default
    force_https = not not meta.force_https
    basic_auth_username = meta.basic_auth_username
    basic_auth_password = meta.basic_auth_password

    _M.cache:set(prefix_cache_key, prefix)
    _M.cache:set(force_https_cache_key, force_https)

    _M.cache:set(basic_auth_username_cache_key, basic_auth_username)
    _M.cache:set(basic_auth_password_cache_key, basic_auth_password)
  end

  local result = new_tab(0, 2)
  result.prefix = prefix
  result.force_https = force_https
  result.basic_auth_username = basic_auth_username
  result.basic_auth_password = basic_auth_password

  return result, nil, nil
end

function _M.invalidate_cache(host)
  _M.cache:delete(host..":pfx")
  _M.cache:delete(host..":fh")
  _M.cache:delete(host..":bau")
  _M.cache:delete(host..":bap")
end

return _M
