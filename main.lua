local config = require('config')
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

ngx.var.target = config.s3_host.."/"..meta.webroot..ngx.var.request_uri

if string.sub(ngx.var.target, -1) == "/" then
  ngx.var.target = ngx.var.target.."index.html"
end

ngx.log(ngx.INFO, "URI: ", ngx.var.scheme.."://"..ngx.var.target)
