local config = require('config')
local http = require('resty.http')
local cjson = require('cjson')
local s3_utils = require('s3_utils')

local _M = {
  err_not_found = "not found"
}

function _M.get_meta(domain_name) -- returns (meta, err)
  -- use http instead of https because metadata does not contain sensitive info anyway
  local domains_url = "http://"..config.s3_host.."/domains"

  local httpc = http.new()
  local res, err = httpc:request_uri(domains_url.."/"..domain_name.."/meta.json", {
    method = "GET"
  })
  if err then
    -- TODO: log this error
    return nil, err
  end

  if res.status == 403 then -- s3 returns 403 when a non-existent path is requested
    return nil, _M.err_not_found
  elseif res.status ~= 200 then
    return nil, res.status.." "..res.body
  end

  local j, ok
  ok, err = pcall(function()
    j = cjson.decode(res.body)
  end)

  if not ok then
    return nil, err
  end

  return j, nil
end

function _M.get_ssl(domain_name)
  local crt_body, key_body, err
  crt_body, err = s3_utils.get_s3_private_file(config, "/certs/"..domain_name.."/ssl.crt")
  if err then
    return nil, nil, err
  end

  key_body, err = s3_utils.get_s3_private_file(config, "/certs/"..domain_name.."/ssl.key")
  if err then
    return nil, nil, err
  end

  return crt_body, key_body, nil
end

return _M
