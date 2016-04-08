local config = require('config')
local target = require('target')
local http = require('resty.http')
local util = require('util')

local _M = {
  err_not_found = "not_found",
  err_redirect = "redirect",
  err_internal_server_error = "internal_server_error",

  cache = ngx.shared.rise,
  _ngx = ngx
}

function _M.handle(prefix, path) -- returns (target, err, err_log)
  local webroot_uri = config.s3_host.."/deployments/"..prefix.."/webroot"
  local target_path_cache_key = prefix..":"..path..":tgt"
  local should_redirect_cache_key = prefix..":"..path..":rdr"
  local target_path, should_redirect = _M.cache:get(target_path_cache_key), _M.cache:get(should_redirect_cache_key)

  if not target_path or should_redirect == nil then -- should_redirect is boolean
    local err
    target_path, should_redirect, err = target.resolve(path, webroot_uri, true)
    if err or not target_path then
      return nil, _M.internal_server_error, 'could not resolve "'..prefix..path..'"'
    end

    if not should_redirect then
      local httpc = http.new()
      local url = "http://"..webroot_uri..target_path
      local res

      res, err = httpc:request_uri(url, { method = "HEAD" })
      if err then
        return nil, _M.internal_server_error, 'failed to fetch "'..url..'" due to "'..err..'"'
      end

      if res.status == 403 or res.status == 404 then
        local custom_404_found = false

        util.request_uri_stream(httpc, "http://"..webroot_uri.."/404.html", {}, function(r)
          custom_404_found = r.status == 200
          if custom_404_found then
            _M._ngx.status = 404
            if r.headers then
              for k, v in pairs(r.headers) do
                _M._ngx.header[k] = v
              end
            end
          else -- custom 404 not found
            return false -- stop reading body
          end
        end, function(chunk)
          _M._ngx.print(chunk) -- pipe body to response
          return true -- continue reading body
        end)
        if custom_404_found then
          _M._ngx.exit(404)
        else
          _M._ngx.exit(403)
        end
        return nil, nil, nil
      end
    end

    _M.cache:set(target_path_cache_key, target_path)
    _M.cache:set(should_redirect_cache_key, should_redirect)
  end

  if should_redirect then
    return target_path, _M.err_redirect, nil
  end

  return webroot_uri..target_path, nil, nil
end

return _M
