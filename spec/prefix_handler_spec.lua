local prefix_handler = require('prefix_handler')
local http = require('resty.http')
local domain = require('domain')
local Dict = require("spec/support/fake_shared_dict")

local stub_fn, unstub_fn = _G.stub_fn, _G.unstub_fn

describe("prefix_handler", function()
  local cache

  setup(function()
    cache = Dict:new()
    prefix_handler.cache = cache
  end)

  describe(".handle", function()
    local get_meta_stub
    local httpc_stub

    before_each(function()
      cache:flush_all()

      httpc_stub = {}
      stub(http, 'new', httpc_stub)
      httpc_stub.request_uri = function(self, uri, opts)
        assert(false,'should not be executed')
      end
    end)

    after_each(function()
      unstub_fn(domain, "get_meta")

      http.new:revert()
    end)

    context("prefix is not cached", function()
      context("when domain.get_meta returns a prefix", function()
        before_each(function()
          get_meta_stub = stub_fn(domain, "get_meta", function(host)
            return {
              prefix = "a1b2c3-123"
            }, nil
          end)
        end)

        it("fetches meta.json to obtain prefix and caches prefix", function()
          local pfx, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, "a1b2c3-123")
          assert.is_nil(err)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
        end)
      end)

      context("when domain.get_meta returns not found error", function()
        before_each(function()
          get_meta_stub = stub_fn(domain, "get_meta", function(host)
            return nil, domain.err_not_found
          end)
        end)

        it("fetches meta.json to obtain prefix and caches prefix", function()
          local pfx, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, nil)
          assert.are.equal(err, prefix_handler.err_not_found)
          assert.are.equal(err_log, 'Failed to fetch metadata for "foo-bar-express.rise.cloud" due to "'..domain.err_not_found..'"')

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")

          assert.is_nil(cache:get("foo-bar-express.rise.cloud:pfx"))
        end)
      end)
    end)

    context("prefix is cached", function()
      before_each(function()
        get_meta_stub = stub_fn(domain, "get_meta")
      end)

      it("fetches prefix from cache", function()
        cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")

        local pfx, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/foo")

        assert.are.equal(pfx, "x0y1z2-012")
        assert.is_nil(err)
        assert.is_nil(err_log)

        assert.spy(get_meta_stub).was_not_called()

        assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "x0y1z2-012")
      end)
    end)
  end)
end)
