local handler = require('handler')

local prefix, target, err, err_log = handler.handle(ngx.var.host, ngx.var.request_uri)

if err then
  if not err_log then
    ngx.log(ngx.ERR, err_log)
  end

  if err == handler.err_not_found then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  elseif err == handler.err_redirect then
    return ngx.redirect(target, ngx.HTTP_MOVED_TEMPORARILY)
  end

  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.var.rise_prefix = prefix
ngx.var.rise_target = target
