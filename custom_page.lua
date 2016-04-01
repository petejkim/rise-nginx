local http = require('resty.http')

local _M = {
  err_not_found = "not_found",
  err_internal_server_error = "internal_server_error",

  cache = ngx.shared.rise
}

function _M.fetch(prefix, status_code, url) -- returns (content, err, err_log)
  local custom_page_presence_cache_key = prefix..":"..status_code..":ctc"
  local custom_page_cache_key = prefix..":"..status_code..":ctp"

  local custom_page_presence = _M.cache:get(custom_page_presence_cache_key)
  if custom_page_presence then
    local content = _M.cache:get(custom_page_cache_key)
    if content then
      return content, nil, nil
    else
      return nil, _M.err_not_found, nil
    end
  end

  local httpc = http.new()
  local res, err = httpc:request_uri("http://"..url, { method = "GET" })
  if err then
    return nil, _M.internal_server_error, "failed to fetch custom page("..status_code..") from "..url.." due to "..err
  end

  if res.status ~= 200 and res.status ~= 403 then
    return nil, _M.internal_server_error, "unexpected status code from s3: "..res.status
  end

  if res.status == 403 then
    _M.cache:set(custom_page_presence_cache_key, true)
    return nil, _M.err_not_found, nil
  end

  _M.cache:set(custom_page_cache_key, res.body)
  _M.cache:set(custom_page_presence_cache_key, true)

  return res.body, nil
end

return _M
