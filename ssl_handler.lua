local domain = require('domain')
local ssl = require('ngx.ssl')
local aes = require('resty.aes')
local config = require('config')

local _M = {
  err_not_found = 'not_found',
  cache = ngx.shared.rise_ssl
}

function _M.handle(host) -- returns cert, key, err, err_log
  local der_crt, der_key, err
  der_crt, der_key = _M.get_from_cache_certs(host)
  if not der_crt or not der_key then
    local crt_body, key_body, crt, key
    crt_body, key_body, err = domain.get_ssl(host)
    if err then
      return nil, nil, _M.err_not_found, 'Failed to fetch ssl information for "'..host..'" due to "'..err..'"'
    end

    crt, key, err = _M.decrypt_certs(crt_body, key_body)
    if err then
      return nil, nil, err, 'Failed to convert and decrypt ssl cert for "'..host..'" due to "'..err..'"'
    end

    der_crt, der_key, err = _M.convert_certs(host, crt, key)
    if err then
      return nil, nil, err, 'Failed to convert to der format for "'..host..'" due to "'..err..'"'
    end
    _M.cache_certs(host, der_crt, der_key)
  end

  return der_crt, der_key, nil, nil
end

function _M.convert_certs(host, crt, key) -- returns der_cert, der_key, err
  local der_crt, der_key, err
  der_crt, err = ssl.cert_pem_to_der(crt)
  if not der_crt then
    return nil, nil, err
  end

  der_key, err = ssl.priv_key_pem_to_der(key)
  if not der_key then
    return nil, nil, err
  end

  return der_crt, der_key, nil
end

function _M.aes_decrypt(s) -- returns decrypted, err
  local iv = s:sub(1, 16) -- Extract IV from content
  local content = s:sub(17) -- Rest of content is actual encrypted cert

  local aes_192_ctr, err = aes:new(
    config.aes_key, -- aes key
    nil, -- salt
    aes.cipher(192, 'ctr'), -- AES Mode
    {['iv']=iv} -- hash table for options.
  )
  if err then
    return nil, err
  end

  local decrypted = aes_192_ctr:decrypt(content)
  return decrypted, nil
end


function _M.decrypt_certs(crt, key) -- returns crt_decrypted, key_decrypted, error
  local crt_decrypted, key_decrypted, err
  crt_decrypted, err = _M.aes_decrypt(crt)
  if err then
    return nil, nil, err
  end

  key_decrypted, err = _M.aes_decrypt(key)
  if err then
    return nil, nil, err
  end

  return crt_decrypted, key_decrypted, nil
end

function _M.cache_certs(host, crt, key)
  _M.cache:set(host..':dcrt', crt)
  _M.cache:set(host..':dkey', key)
end

function _M.get_from_cache_certs(host)
  return _M.cache:get(host..':dcrt'), _M.cache:get(host..':dkey')
end

function _M.invalidate_cache(host)
  _M.cache:delete(host..':dcrt')
  _M.cache:delete(host..':dkey')
end

return _M
