local config = require('config')
local handler = require('handler')
local domain = require('domain')
local target = require('target')
local Dict = require("spec/support/fake_shared_dict")

describe("handler", function()
  local cache

  setup(function()
    cache = Dict:new()
    handler.cache = cache
  end)

  describe(".handle", function()
    local get_meta_stub
    local resolve_stub

    before_each(function()
      cache:flush_all()
    end)

    after_each(function()
      unstub_fn(domain, "get_meta")
      unstub_fn(target, "resolve")
    end)

    context("prefix is not cached", function()
      before_each(function()
        get_meta_stub = stub_fn(domain, "get_meta", function(host)
          return {
            prefix = "a1b2c3-123"
          }, nil
        end)

        resolve_stub = stub_fn(target, "resolve", function(path, webroot, drop_dot_html)
          return "/index.html", false, nil
        end)
      end)

      it("fetches meta.json to obtain prefix and caches prefix, target and should_redirect", function()
        local t, err, err_log = handler.handle("foo-bar-express.rise.cloud", "/")

        assert.are.equal(t, config.s3_host.."/deployments/a1b2c3-123/webroot/index.html")
        assert.is_nil(err)
        assert.is_nil(err_log)

        assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")
        assert.spy(resolve_stub).was_called_with("/", config.s3_host.."/deployments/a1b2c3-123/webroot", true)

        assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
        assert.are.equal(cache:get("a1b2c3-123:/:tgt"), "/index.html")
        assert.is_false(cache:get("a1b2c3-123:/:rdr"))
      end)
    end)

    context("prefix is cached", function()
      before_each(function()
        get_meta_stub = stub_fn(domain, "get_meta")
        resolve_stub = stub_fn(target, "resolve")
      end)

      it("fetches prefix, target and should_redirect from cache", function()
        cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")
        cache:set("x0y1z2-012:/foo:tgt", "/foo/")
        cache:set("x0y1z2-012:/foo:rdr", true)

        local t, err, err_log = handler.handle("foo-bar-express.rise.cloud", "/foo")

        assert.are.equal(t, "/foo/")
        assert.are_equal(err, handler.err_redirect)
        assert.is_nil(err_log)

        assert.spy(get_meta_stub).was_not_called()
        assert.spy(resolve_stub).was_not_called()

        assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "x0y1z2-012")
        assert.are.equal(cache:get("x0y1z2-012:/foo:tgt"), "/foo/")
        assert.is_true(cache:get("x0y1z2-012:/foo:rdr"))
      end)
    end)
  end)
end)
