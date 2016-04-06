local config = require('config')
local handler = require('handler')
local http = require('resty.http')
local domain = require('domain')
local target = require('target')
local Dict = require("spec/support/fake_shared_dict")

local stub_fn, unstub_fn = _G.stub_fn, _G.unstub_fn

describe("handler", function()
  local cache

  setup(function()
    cache = Dict:new()
    handler.cache = cache
  end)

  describe(".handle", function()
    local get_meta_stub
    local resolve_stub
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
      unstub_fn(target, "resolve")

      http.new:revert()
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
        httpc_stub.request_uri = function(self, uri, opts)
          assert.are.equal(uri, "http://test-s3.example.com/deployments/a1b2c3-123/webroot/index.html")
          assert.are.same(opts, { method = "HEAD" })
          return {
            status = 200
          }
        end

        local pfx, tgt, err, err_log = handler.handle("foo-bar-express.rise.cloud", "/")

        assert.are.equal(pfx, "a1b2c3-123")
        assert.are.equal(tgt, config.s3_host.."/deployments/a1b2c3-123/webroot/index.html")
        assert.is_nil(err)
        assert.is_nil(err_log)

        assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")
        assert.spy(resolve_stub).was_called_with("/", config.s3_host.."/deployments/a1b2c3-123/webroot", true)

        assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
        assert.are.equal(cache:get("a1b2c3-123:/:tgt"), "/index.html")
        assert.is_false(cache:get("a1b2c3-123:/:rdr"))
        assert.is_true(cache:get("a1b2c3-123:/:prs"))
      end)

      context("the file does not exist on s3", function()
        it("return /404.html page", function()
          httpc_stub.request_uri = function(self, uri, opts)
            assert.are.equal(uri, "http://test-s3.example.com/deployments/a1b2c3-123/webroot/index.html")
            assert.are.same(opts, { method = "HEAD" })
            return {
              status = 403
            }
          end

          local pfx, tgt, err, err_log = handler.handle("foo-bar-express.rise.cloud", "/")

          assert.are.equal(pfx, "a1b2c3-123")
          assert.are.equal(tgt, config.s3_host.."/deployments/a1b2c3-123/webroot/404.html")
          assert.are.equal(err, handler.err_asset_not_found)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_called_with("foo-bar-express.rise.cloud")
          assert.spy(resolve_stub).was_called_with("/", config.s3_host.."/deployments/a1b2c3-123/webroot", true)

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "a1b2c3-123")
          assert.are.equal(cache:get("a1b2c3-123:/:tgt"), "/404.html")
          assert.is_false(cache:get("a1b2c3-123:/:rdr"))
          assert.is_false(cache:get("a1b2c3-123:/:prs"))
        end)
      end)
    end)

    context("prefix is cached", function()
      before_each(function()
        get_meta_stub = stub_fn(domain, "get_meta")
        resolve_stub = stub_fn(target, "resolve")
      end)

      context("when should_redirect is true", function()
        it("fetches prefix, target and should_redirect from cache", function()
          cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")
          cache:set("x0y1z2-012:/foo:tgt", "/foo/")
          cache:set("x0y1z2-012:/foo:rdr", true)
          cache:set("x0y1z2-012:/foo:prs", true)

          local pfx, tgt, err, err_log = handler.handle("foo-bar-express.rise.cloud", "/foo")

          assert.are.equal(pfx, "x0y1z2-012")
          assert.are.equal(tgt, "/foo/")
          assert.are_equal(err, handler.err_redirect)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_not_called()
          assert.spy(resolve_stub).was_not_called()

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "x0y1z2-012")
          assert.are.equal(cache:get("x0y1z2-012:/foo:tgt"), "/foo/")
          assert.is_true(cache:get("x0y1z2-012:/foo:rdr"))
          assert.is_true(cache:get("x0y1z2-012:/foo:prs"))
        end)
      end)

      context("when asset_presence is true", function()
        it("fetches prefix, target and should_redirect from cache", function()
          cache:set("foo-bar-express.rise.cloud:pfx", "x0y1z2-012")
          cache:set("x0y1z2-012:/foo:tgt", "/404.html")
          cache:set("x0y1z2-012:/foo:rdr", false)
          cache:set("x0y1z2-012:/foo:prs", false)

          local pfx, tgt, err, err_log = handler.handle("foo-bar-express.rise.cloud", "/foo")

          assert.are.equal(pfx, "x0y1z2-012")
          assert.are.equal(tgt, config.s3_host.."/deployments/x0y1z2-012/webroot/404.html")
          assert.are_equal(err, handler.err_asset_not_found)
          assert.is_nil(err_log)

          assert.spy(get_meta_stub).was_not_called()
          assert.spy(resolve_stub).was_not_called()

          assert.are.equal(cache:get("foo-bar-express.rise.cloud:pfx"), "x0y1z2-012")
          assert.are.equal(cache:get("x0y1z2-012:/foo:tgt"), "/404.html")
          assert.is_false(cache:get("x0y1z2-012:/foo:rdr"))
          assert.is_false(cache:get("x0y1z2-012:/foo:prs"))
        end)
      end)
    end)
  end)
end)
