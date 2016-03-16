require('config')

local domain = require('domain')
local host = ngx.var.host

local meta, err = domain.get_meta(host)
if err then
  ngx.log(ngx.ERR, "Failed to fetch metadata for ", host, "due to ", err)
  return ngx.exit(404)
end

if not meta.webroot then
  ngx.log(ngx.ERR, "'webroot' is not specified for ", host)
  return ngx.exit(404)
end

ngx.var.target = _G.CONFIG.s3_host.."/"..meta.webroot

if ngx.var.request_uri == "/" then
  ngx.var.target = ngx.var.target.."/index.html"
else
  ngx.var.target = ngx.var.target..ngx.var.request_uri
end

ngx.log(ngx.INFO, "URI: ", ngx.var.scheme.."://"..ngx.var.target)
