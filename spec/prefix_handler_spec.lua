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

    context("prefix and force_https are not cached", function()
      context("when domain.get_meta returns a prefix and force_https", function()
        before_each(function()
          get_meta_stub = stub_fn(domain, "get_meta", function(host)
            return {
              prefix = "a1b2c3-123",
              force_https = true
            }, nil
          end)
        end)

        it("fetches meta.json to obtain prefix and force_https and caches prefix and force_https", function()
          local pfx, fh, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, "a1b2c3-123")
          assert.is_true(fh)
          assert.is_nil(err)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
          assert.are.equal(cache:get("foo-bar-express.rise.cloud:fh"), true)
        end)
      end)

      context("when domain.get_meta returns a prefix", function()
        before_each(function()
          get_meta_stub = stub_fn(domain, "get_meta", function(host)
            return {
              prefix = "a1b2c3-123"
            }, nil
          end)
        end)

        it("fetches meta.json to obtain prefix and force_https and caches prefix and force_https", function()
          local pfx, fh, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, "a1b2c3-123")
          assert.is_false(fh)
          assert.is_nil(err)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
          assert.are.equal(cache:get("foo-bar-express.rise.cloud:fh"), false)
        end)
      end)

      context("when domain.get_meta returns not found error", function()
        before_each(function()
          get_meta_stub = stub_fn(domain, "get_meta", function(host)
            return nil, domain.err_not_found
          end)
        end)

        it("returns an error", function()
          local pfx, fh, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, nil)
          assert.is_nil(fh)
          assert.are.equal(err, prefix_handler.err_not_found)
          assert.are.equal(err_log, 'Failed to fetch metadata for "foo-bar-express.rise.cloud" due to "'..domain.err_not_found..'"')

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")

          assert.is_nil(cache:get("foo-bar-express.rise.cloud:pfx"))
          assert.is_nil(cache:get("foo-bar-express.rise.cloud:fh"))
        end)
      end)
    end)

    context("force_https is not cached", function()
      before_each(function()
        cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")
      end)

      context("when domain.get_meta returns a prefix and force_https", function()
        before_each(function()
          get_meta_stub = stub_fn(domain, "get_meta", function(host)
            return {
              prefix = "a1b2c3-123",
              force_https = true
            }, nil
          end)
        end)

        it("fetches meta.json to obtain prefix and force_https and caches prefix and force_https", function()
          local pfx, fh, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, "a1b2c3-123")
          assert.is_true(fh)
          assert.is_nil(err)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
          assert.are.equal(cache:get("foo-bar-express.rise.cloud:fh"), true)
        end)
      end)
    end)


    context("prefix and force_https are cached", function()
      before_each(function()
        get_meta_stub = stub_fn(domain, "get_meta")
        cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")
        cache:set("foo-bar-express.rise.cloud:fh", true)
      end)

      it("fetches prefix from cache", function()
        local pfx, fh, err, err_log = prefix_handler.handle("foo-bar-express.rise.cloud", "/foo")

        assert.are.equal(pfx, "x0y1z2-012")
        assert.is_true(fh)
        assert.is_nil(err)
        assert.is_nil(err_log)

        assert.spy(get_meta_stub).was_not_called()

        assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "x0y1z2-012")
        assert.is_true(cache:get("foo-bar-express.rise.cloud:fh"))
      end)
    end)
  end)

  describe(".invalidate_cache", function()
    it("invalidates prefix cache for given host name", function()
      cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")
      cache:set("foo-bar-express.rise.cloud:fh", true)
      cache:set("foo-bar-express.com:pfx", "a1b2c3-123")
      cache:set("foo-bar-express.com:fh", true)

      prefix_handler.invalidate_cache("foo-bar-express.rise.cloud")

      assert.is_nil(cache:get("foo-bar-express.rise.cloud:pfx"))
      assert.is_nil(cache:get("foo-bar-express.rise.cloud:fh"))
      assert.are.equal(cache:get("foo-bar-express.com:pfx"), "a1b2c3-123")
      assert.is_true(cache:get("foo-bar-express.com:fh"))
    end)
  end)
end)
