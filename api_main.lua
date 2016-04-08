local api_handler = require('api_handler')

local json_body, err, err_log = api_handler.handle(ngx.req.get_method(), ngx.var.request_uri)

ngx.var.rise_content_type = "application/json"

ngx.print(json_body)

if err then
  if not err_log then
    ngx.log(ngx.ERR, err_log)
  end

  if err == api_handler.err_not_found then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  end
  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

return ngx.exit(ngx.HTTP_OK)
