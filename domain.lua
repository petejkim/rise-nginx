local config = require('config')
local http = require('resty.http')
local cjson = require('cjson')

local domain = {}

function domain.get_meta(domain_name)
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
    return nil, "not found"
  elseif res.status ~= 200 then
    return nil, res.status.." "..res.body
  end

  local j
  local ok, err = pcall(function()
    j = cjson.decode(res.body)
  end)

  if not ok then
    return nil, err
  end

  return j, nil
end

return domain
