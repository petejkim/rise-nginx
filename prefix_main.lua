local prefix_handler = require('prefix_handler')

local prefix, err, err_log = prefix_handler.handle(ngx.var.host, ngx.var.request_uri)

if err then
  if not err_log then
    ngx.log(ngx.ERR, err_log)
  end

  if err == prefix_handler.err_not_found then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  end

  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.var.rise_prefix = prefix
