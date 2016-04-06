local config = require('config')
local domain = require('domain')
local target = require('target')
local http = require('resty.http')

local _M = {
  err_not_found = "not_found",
  err_redirect = "redirect",
  err_internal_server_error = "internal_server_error",
  err_asset_not_found = "asset_not_found",

  cache = ngx.shared.rise
}

function _M.handle(host, path) -- returns (prefix, target, err, err_log)
  local prefix_cache_key = host..":pfx"
  local prefix = _M.cache:get(prefix_cache_key)
  if not prefix then
    -- cache miss for HOST:prefix
    local meta, err = domain.get_meta(host)
    if err then
      return nil, nil, _M.err_not_found, "Failed to fetch metadata for "..host.." due to "..err
    end

    if not meta.prefix then
      return nil, nil, _M.internal_server_error, "meta.json for "..host.." did not contain prefix"
    end

    prefix = meta.prefix
    _M.cache:set(host..":pfx", prefix)
  end

  local webroot_uri = config.s3_host.."/deployments/"..prefix.."/webroot"
  local target_path_cache_key = prefix..":"..path..":tgt"
  local should_redirect_cache_key = prefix..":"..path..":rdr"
  local asset_presence_cache_key = prefix..":"..path..":prs"

  local target_path = _M.cache:get(target_path_cache_key)
  local should_redirect = _M.cache:get(should_redirect_cache_key)
  local asset_presence = _M.cache:get(asset_presence_cache_key)

  -- should_redirect and asset_present are boolean
  if not target_path or should_redirect == nil or asset_presence == nil then
    local err

    target_path, should_redirect, err = target.resolve(path, webroot_uri, true)
    if err or not target_path then
      return nil, nil, _M.internal_server_error, "could not resolve "..host..path
    end

    local httpc = http.new()
    local url = "http://"..webroot_uri..target_path
    local res

    res, err = httpc:request_uri(url, { method = "HEAD" })
    if err then
      return nil, nil, _M.internal_server_error, "failed to fetch "..url.." due to "..err
    end

    if res.status ~= 200 and res.status ~= 403 then
      return nil, nil, _M.internal_server_error, "unexpected status code from s3: "..res.status
    end

    if res.status == 403 then
      target_path = '/404.html'
      should_redirect = false
      asset_presence = false
    else
      asset_presence = true
    end

    _M.cache:set(target_path_cache_key, target_path)
    _M.cache:set(should_redirect_cache_key, should_redirect)
    _M.cache:set(asset_presence_cache_key, asset_presence)
  end

  if should_redirect then
    return prefix, target_path, _M.err_redirect, nil
  end

  if not asset_presence then
    return prefix, webroot_uri..target_path, _M.err_asset_not_found, nil
  end

  return prefix, webroot_uri..target_path, nil, nil
end

return _M
