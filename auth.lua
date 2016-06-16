local sha256 = require "resty.sha256"
local string = require "resty.string"

local _M = {
  err_invalid_header = 'invalid_header',
  err_invalid_username = 'invalid_username',
  err_invalid_password = 'invalid_password'
}

function _M.authenticate(auth_header, username, encrypted_password) -- returns err, err_log
  if auth_header == nil then
    return _M.err_invalid_header, 'Authorization header is empty'
  end

  if auth_header:find(' ') == nil then
    return _M.err_invalid_header, 'Authorization header is invalid: '..auth_header
  end

  local divider = auth_header:find(' ')
  if auth_header:sub(0, divider-1) ~= 'Basic' then
    return _M.err_invalid_header, 'Authorization header is invalid: '..auth_header
  end

  local auth = ngx.decode_base64(auth_header:sub(divider+1))
  if auth == nil or auth:find(':') == nil then
    return _M.err_invalid_header, 'Authorization header is invalid: '..auth_header
  end

  divider = auth:find(':')
  if auth:sub(0, divider-1) ~= username then
    return _M.err_invalid_username, 'The username is not valid: '..auth_header
  end

  local sha256_writer = sha256:new()
  sha256_writer:update(auth) -- username:password
  local digest = string.to_hex(sha256_writer:final())

  if digest ~= encrypted_password then
    return _M.err_invalid_password, 'The password is not valid: '..auth_header
  end

  return nil, nil
end

return _M
