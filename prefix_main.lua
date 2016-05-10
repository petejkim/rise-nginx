local prefix_handler = require('prefix_handler')
local config = require('config')

local prefix, force_https, err, err_log = prefix_handler.handle(ngx.var.host, ngx.var.request_uri)

if err then
  if err_log then
    ngx.log(ngx.ERR, err_log)
  end

  if err == prefix_handler.err_not_found then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  else
    ngx.log(ngx.ERR, err)
  end

  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if force_https then
  local https_url
  if config.ssl_port then
    https_url = "https://"..ngx.var.host..":"..config.ssl_port..ngx.var.request_uri
  else
    https_url = "https://"..ngx.var.host..ngx.var.request_uri
  end
  return ngx.redirect(https_url, ngx.HTTP_MOVED_TEMPORARILY)
end

ngx.var.rise_prefix = prefix
