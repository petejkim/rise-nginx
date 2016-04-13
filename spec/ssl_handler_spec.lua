local ssl_handler = require('ssl_handler')
local http = require('resty.http')
local Dict = require('spec/support/fake_shared_dict')

local stub_fn, unstub_fn = _G.stub_fn, _G.unstub_fn
local crt_aes, key_aes, crt_der, key_der
local domain = require('domain')

describe('ssl_handler', function()
  local cache
  local reader

  setup(function()
    cache = Dict:new()
    ssl_handler.cache = cache
    reader = {}


    -- Read the certs
    function reader.read_file(filename)
      local f = assert(io.open(filename, 'r'))
      local data = f:read('*all')
      f:close()
      return data
    end

    crt_aes = reader.read_file('spec/support/ssl/ssl.crt.aes')
    key_aes = reader.read_file('spec/support/ssl/ssl.key.aes')
    crt_der = reader.read_file('spec/support/ssl/ssl.crt.der')
    key_der = reader.read_file('spec/support/ssl/ssl.key.der')
  end)

  describe('.handle', function()
    before_each(function()
      cache:flush_all()

      local httpc_stub = {}
      stub(http, 'new', httpc_stub)
      httpc_stub.request_uri = function(self, uri, opts)
        assert(false,'should not be executed')
      end
    end)

    after_each(function()
      http.new:revert()
    end)

    context('when ssl certs are fetched properly', function()
      before_each(function()
        stub_fn(domain, 'get_ssl', function(host)
          return crt_aes, key_aes, nil
        end)
      end)

      after_each(function()
        unstub_fn(domain, 'get_ssl')
      end)

      it ('caches the DER format of the cert', function()
        local _, _, err, _ = ssl_handler.handle('www.foobar.com')
        assert.is_nil(err)
        assert.are.equal(cache:get('www.foobar.com:ssl:der_crt'), crt_der)
        assert.are.equal(cache:get('www.foobar.com:ssl:der_key'), key_der)
      end)
    end)

    context('certs are cached', function()
      before_each(function()
        stub_fn(domain, 'get_ssl', function(host)
          assert(false, 'This should not happen')
        end)
      end)

      after_each(function()
        unstub_fn(domain, 'get_ssl')
      end)

      it('fetches the certs from the cache', function()
        cache:set('foo-bar-express.rise.cloud:ssl:der_crt', 'DER-CRT')
        cache:set('foo-bar-express.rise.cloud:ssl:der_key', 'DER-KEY')

        local c, k, err = ssl_handler.handle('foo-bar-express.rise.cloud')
        assert.is_nil(err)
        assert.are.equal(c, 'DER-CRT')
        assert.are.equal(k, 'DER-KEY')

        assert.are.equal(cache:get('foo-bar-express.rise.cloud:ssl:der_crt'), 'DER-CRT')
        assert.are.equal(cache:get('foo-bar-express.rise.cloud:ssl:der_key'), 'DER-KEY')
      end)
    end)

    context('domain.get_ssl returns error', function()
      before_each(function()
        stub_fn(domain, 'get_ssl', function(host)
          return nil, nil, 'err'
        end)
      end)

      after_each(function()
        unstub_fn(domain, 'get_ssl')
      end)

      it('returns an error', function()
        local c, k, err = ssl_handler.handle('inexistent.domain.com')
        assert.is_nil(c)
        assert.is_nil(k)
        assert.is_not_nil(err)
      end)
    end)

    context('certs are invalid', function()
      before_each(function()
        stub_fn(domain, 'get_ssl', function(host)
          return "This is not a valid CRT", "This is not a valid KEY", nil
        end)
      end)

      after_each(function()
        unstub_fn(domain, 'get_ssl')
      end)

      local c, k, err = ssl_handler.handle('foo-bar-express.rise.cloud')
      assert.is_nil(c)
      assert.is_nil(k)
      assert.is_not_nil(err)
    end)
  end)
end)
