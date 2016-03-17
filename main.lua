local config = require('config')
local domain = require('domain')
local target = require('target')

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

local webroot_uri = config.s3_host.."/"..meta.webroot
local target_uri, should_redirect = target.resolve(ngx.var.request_uri, webroot_uri, true)

if should_redirect then
  return ngx.redirect(target_uri, ngx.HTTP_MOVED_TEMPORARILY)
end

ngx.var.target = webroot_uri..target_uri

ngx.log(ngx.INFO, "URI: ", ngx.var.scheme.."://"..ngx.var.target)
