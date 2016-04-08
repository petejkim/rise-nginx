local handler = require('handler')

local prefix = ngx.req.get_headers()['X-Rise-Prefix']

-- openresty's req.get_headers() retardedly returns either table (array) or string
-- depending on the number of times the header appears in the request
if type(prefix) == 'table' then
  ngx.exit(ngx.HTTP_BAD_REQUEST)
  return
end

local target, err, err_log = handler.handle(prefix, ngx.var.request_uri)

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

if target then
  ngx.var.rise_target = target
end
