local http = require('resty.http')
local custom_page = require('custom_page')
local Dict = require("spec/support/fake_shared_dict")

describe("custom_page", function()
  local cache

  setup(function()
    cache = Dict:new()
    custom_page.cache = cache
  end)

  describe(".fetch", function()
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
      http.new:revert()
    end)

    context("custom page is not cached", function()
      it("fetches custom page and cache it", function()
        httpc_stub.request_uri = function(self, uri, opts)
          assert.are.equal(uri, "http://test-s3.example.com/deployments/a1b2c3-123/webroot/404.html")
          assert.are.same(opts, { method = "GET" })
          return {
            body = "<h1> page not found in foo-bar-express </h1>",
            status = 200
          }
        end

        local content, err, err_log = custom_page.fetch("a1b2c3-123", 404, "test-s3.example.com/deployments/a1b2c3-123/webroot/404.html")

        assert.are.equal(content, "<h1> page not found in foo-bar-express </h1>")
        assert.is_nil(err)
        assert.is_nil(err_log)

        assert.is_true(cache:get("a1b2c3-123:404:ctc"))
        assert.are.same(cache:get("a1b2c3-123:404:ctp"), "<h1> page not found in foo-bar-express </h1>")
      end)

      context("custom page does not exist", function()
        it("only caches presence of the cache", function()
          httpc_stub.request_uri = function(self, uri, opts)
            assert.are.equal(uri, "http://test-s3.example.com/deployments/a1b2c3-123/webroot/404.html")
            assert.are.same(opts, { method = "GET" })
            return {
              body = "<h1> some aws s3 stuff </h1>",
              status = 403
            }
          end

          local content, err, err_log = custom_page.fetch("a1b2c3-123", 404, "test-s3.example.com/deployments/a1b2c3-123/webroot/404.html")

          assert.is_nil(content)
          assert.are.equal(err, custom_page.err_not_found)
          assert.is_nil(err_log)

          assert.is_true(cache:get("a1b2c3-123:404:ctc"))
          assert.is_nil(cache:get("a1b2c3-123:404:ctp"))
        end)
      end)
    end)

    context("custom page is cached", function()
      it("fetches from cache", function()
        cache:set("a1b2c3-123:404:ctc", true)
        cache:set("a1b2c3-123:404:ctp", "<h1> your site is hacked! </h1>")

        local content, err, err_log = custom_page.fetch("a1b2c3-123", 404, "test-s3.example.com/deployments/a1b2c3-123/webroot/404.html")

        assert.are.equal(content, "<h1> your site is hacked! </h1>")
        assert.is_nil(err)
        assert.is_nil(err_log)

        assert.is_true(cache:get("a1b2c3-123:404:ctc"))
        assert.are.same(cache:get("a1b2c3-123:404:ctp"), "<h1> your site is hacked! </h1>")
      end)

      context("content is nil", function()
        it("returns not found error", function()
          cache:set("a1b2c3-123:404:ctc", true)
          cache:set("a1b2c3-123:404:ctp", nil)

          local content, err, err_log = custom_page.fetch("a1b2c3-123", 404, "test-s3.example.com/deployments/a1b2c3-123/webroot/404.html")

          assert.is_nil(content)
          assert.are.same(err, custom_page.err_not_found)
          assert.is_nil(err_log)

          assert.is_true(cache:get("a1b2c3-123:404:ctc"))
          assert.are.same(cache:get("a1b2c3-123:404:ctp"), nil)
        end)
      end)
    end)
  end)
end)
