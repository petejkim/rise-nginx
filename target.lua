local context = describe
local config = require('config')
local http = require('resty.http')

local target = {}

function target.resolve(path, webroot, drop_dot_html) -- returns (target_path, should_redirect, err)
  if string.sub(path, -1) == "/" then
    return path.."index.html", false, nil
  end

  -- if path ends with "/index.html", redirect to "/"
  if string.sub(path, -11) == "/index.html" then
    return string.sub(path, 1, -11), true, nil
  end

  if drop_dot_html then
    local httpc = http.new()
    local res, err

    -- if path ends with ".html"
    if string.sub(path, -5) == ".html" then
      path_sans_html = string.sub(path, 1, -6)
      -- check whether there exists a file without the ".html" extension
      res, err = httpc:request_uri("http://"..webroot..path_sans_html, { method = "HEAD" })
      if err then
        -- TODO: log this error
        return nil, false, "internal server error"
      end

      -- file does not exist, safe to redirect
      if res.status ~= 200 then
        return path_sans_html, true, nil
      end
    end

    -- check whether an asset with exact same path exists
    -- e.g. /foo --> /foo
    res, err = httpc:request_uri("http://"..webroot..path, { method = "HEAD" })
    if err then
      -- TODO: log this error
      return nil, false, "internal server error"
    end

    if res.status == 200 then
      return path, false, nil
    end

    -- if that doesn't exist, try path with ".html" appended
    -- e.g. /foo --> /foo.html
    res, err = httpc:request_uri("http://"..webroot..path..".html", { method = "HEAD" })
    if err then
      -- TODO: log this error
      return nil, false, "internal server error"
    end

    if res.status == 200 then
      -- if this ends up pointing to ".../index.html", redirect to ".../"
      if string.sub(path, -6) == "/index" then
        return string.sub(path, 1, -6), true, nil
      end
      return path..".html", false, nil
    end

    -- finally, try ".../index.html"
    -- e.g. /foo --> /foo/index.html
    res, err = httpc:request_uri("http://"..webroot..path.."/index.html", { method = "HEAD" })
    if err then
      -- TODO: log this error
      return nil, false, "internal server error"
    end

    -- redirect to "/foo/"
    if res.status == 200 then
      return path.."/", true, nil
    end
  end

  return path, false, nil
end

return target
