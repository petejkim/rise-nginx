local hmac = require('resty.hmac')
local http = require('resty.http')

local _M = {
  err_not_found = 'not found'
}

local urlencode = function(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str
end

-- Gets a private file from an S3 bucket
-- http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html#RESTAuthenticationQueryStringAuth
function _M.get_s3_private_file(config, path)
  local time = ngx.time() + config.s3_valid_period

  local string_to_sign = 'GET\n\n\n'..time..'\n/'..config.s3_bucket..path
  local hm, err = hmac:new(config.s3_secret_key)
  local sig
  sig, err = hm:generate_signature('sha1', string_to_sign)
  if err then
    return nil, err
  end

  local encoded_sig = urlencode(sig)
  local url = 'https://'..config.s3_domain..'/'..config.s3_bucket..path..'?AWSAccessKeyId='..config.s3_access_key..'&Expires='..time..'&Signature='..encoded_sig
  local httpc = http.new()
  local res

  res, err = httpc:request_uri(url, {
    method = 'GET',
    ssl_verify = false -- TODO: Check how to add main s3 certificates to nginx
  })
  if err then
    return nil, err
  end

  if res.status == 403 then -- s3 returns 403 when a non-existent path is requested
    return nil, _M.err_not_found
  elseif res.status ~= 200 then
    return nil, res.status..' '..res.body
  end

  return res.body, nil
end

return _M
