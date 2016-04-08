local _M = {}

-- Makes a request, but instead of reading the entire body into the memory,
-- it reads in chunks, and invokes res_callback with response and invokes
-- data_callback with each chunk of body read.
-- if res_callback or data_callback returns false, it stops reading body.
function _M.request_uri_stream(httpc, uri, params, res_callback, data_callback)
  if not params then
    params = {}
  end

  local parsed_uri, err = httpc:parse_uri(uri)
  if err or not parsed_uri then
    return nil, err
  end

  local scheme, host, port, path = unpack(parsed_uri)
  if not params.path then
    params.path = path
  end

  local c
  c, err = httpc:connect(host, port)
  if err or not c then
    return nil, err
  end

  if scheme == "https" then
    local verify = true
    if params.ssl_verify == false then
      verify = false
    end

    local ok
    ok, err = httpc:ssl_handshake(nil, host, verify)
    if err or not ok then
      return nil, err
    end
  end

  local res
  res, err = httpc:request(params)
  if err or not res then
    return nil, err
  end

  local read_body = true
  if type(res_callback) == "function" then
    if res_callback(res) == false then -- specifically false, not just falsy
      read_body = false
    end
  end

  if read_body and type(data_callback) == "function" then
    local chunk;
    repeat
      chunk, err = res.body_reader(8192)
      if err then
        break
      end

      if chunk then
        if data_callback(chunk) == false then
          break
        end
      end
    until not chunk
  end

  httpc:set_keepalive()
  return res, err
end

return _M
