local domain = require('domain')
local http = require('resty.http')
local s3_utils = require('s3_utils')
local stub_fn, unstub_fn = _G.stub_fn, _G.unstub_fn

describe("domain", function()
  describe(".get_meta", function()
    local httpc_stub

    before_each(function()
      httpc_stub = {request_uri=function() end}
      stub(http, 'new', httpc_stub)
    end)

    after_each(function()
      http.new:revert()
    end)

    context("when metadata json file cannot be fetched", function()
      context("when s3 returns 403", function()
        before_each(function()
          httpc_stub.request_uri = function(self, uri, opts)
            assert.are.equal(uri, "http://test-s3.example.com/domains/foo-bar-express.rise.cloud/meta.json")
            assert.is_not_nil(opts)
            assert.are.equal(opts.method, "GET")
            return {
              status = 403,
              body = ""
            }, nil
          end
        end)

        it("returns nil and an error", function()
          local j, err = domain.get_meta("foo-bar-express.rise.cloud")
          assert.is_nil(j)
          assert.are.equal(err, "not found")
        end)
      end)

      context("when s3 returns some other errorneous response code", function()
        before_each(function()
          httpc_stub.request_uri = function(self, uri, opts)
            assert.are.equal(uri, "http://test-s3.example.com/domains/foo-bar-express.rise.cloud/meta.json")
            assert.is_not_nil(opts)
            assert.are.equal(opts.method, "GET")
            return {
              status = 500,
              body = "<XML>foobar</XML>"
            }, nil
          end
        end)

        it("returns nil and an error", function()
          local j, err = domain.get_meta("foo-bar-express.rise.cloud")
          assert.is_nil(j)
          assert.are.equal(err, "500 <XML>foobar</XML>")
        end)
      end)
    end)

    context("when metadata json file can be fetched successfully", function()
      before_each(function()
        httpc_stub.request_uri = function(self, uri, opts)
          assert.are.equal(uri, "http://test-s3.example.com/domains/foo-bar-express.rise.cloud/meta.json")
          assert.is_not_nil(opts)
          assert.are.equal(opts.method, "GET")
          return {
            status = 200,
            body = '{"prefix": "bafb79-26"}'
          }, nil
        end
      end)

      it("returns info and no error", function()
        local j, err = domain.get_meta("foo-bar-express.rise.cloud")
        assert.is_nil(err)
        assert.are.same(j, { prefix = "bafb79-26" })
      end)
    end)
  end)

  describe(".get_ssl", function()
    after_each(function()
      unstub_fn(s3_utils, "get_s3_private_file")
    end)

    context("when ssl certs can be fetched successfully", function()

      local requests = {}
      requests["/certs/foo-bar-express.rise.cloud/ssl.crt"] = "my private certificate"
      requests["/certs/foo-bar-express.rise.cloud/ssl.key"] = "my private key"

      before_each(function()
        stub_fn(s3_utils, "get_s3_private_file", function(cfg, path)
          return requests[path], nil
        end)
      end)

      it("returns certs and no error", function()
        local crt, key, err = domain.get_ssl("foo-bar-express.rise.cloud")
        assert.is_not_nil(crt)
        assert.is_not_nil(key)
        assert.is_nil(err)
        assert.are.same(crt, 'my private certificate')
        assert.are.same(key, 'my private key')
      end)
    end)

    context("when ssl certs can't be fetched", function()
      before_each(function()
        stub_fn(s3_utils, "get_s3_private_file", function(cfg, path)
          return nil, s3_utils.err_not_found
        end)
      end)

      it("returns error", function()
        local _, _, err = domain.get_ssl("foo-bar-express.rise.cloud")
        assert.is_not_nil(err)
      end)
    end)
  end)
end)
