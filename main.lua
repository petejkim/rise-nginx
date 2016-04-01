local handler = require('handler')
local custom_page = require('custom_page')

local function handle_not_found(prefix, asset_path)
  local content, err, err_log = custom_page.fetch(prefix, ngx.HTTP_NOT_FOUND, asset_path)
  if content then
    -- Set header before content to be written
    -- ngx.say triggers response header sending
    -- https://github.com/openresty/lua-resty-redis/issues/15
    ngx.status = ngx.HTTP_NOT_FOUND
    ngx.say(content)
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  else
    if err_log then
      ngx.log(ngx.ERR, err_log)
    end

    ngx.var.rise_prefix = prefix
    ngx.var.rise_target = asset_path
    return
  end
end

local prefix, target, err, err_log = handler.handle(ngx.var.host, ngx.var.request_uri)

if err then
  if err_log then
    ngx.log(ngx.ERR, err_log)
  end

  if err == handler.err_not_found then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
  elseif err == handler.err_redirect then
    return ngx.redirect(target, ngx.HTTP_MOVED_TEMPORARILY)
  elseif err == handler.err_asset_not_found then
    handle_not_found(prefix, target)
    return
  end

  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.var.rise_prefix = prefix
ngx.var.rise_target = target
