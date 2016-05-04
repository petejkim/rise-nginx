local ssl_handler = require('ssl_handler')

-- Setup TLS related.
local ssl = require "ngx.ssl"
local server_name = ssl.server_name()
local der_crt, der_key, err_log
local ok, err = ssl.clear_certs()

if not ok then
  return ngx.exit(ngx.ERROR)
end

der_crt, der_key, err, err_log = ssl_handler.handle(server_name)
if err then
  if err_log then
    ngx.log(ngx.ERR, err_log)
  end

  if err == ssl_handler.err_not_found then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  else
    ngx.log(ngx.ERR, err)
  end

  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ok, err = ssl.set_der_cert(der_crt)
if not ok then
  ngx.log(ngx.ERR, "failed to set DER cert: ", err)
  return ngx.exit(ngx.ERROR)
end

ok, err = ssl.set_der_priv_key(der_key)
if not ok then
  ngx.log(ngx.ERR, "failed to set DER private key: ", err)
  return ngx.exit(ngx.ERROR)
end
