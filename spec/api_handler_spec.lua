local api_handler = require('api_handler')
local prefix_handler = require('prefix_handler')
local ssl_handler = require('ssl_handler')
local Dict = require("spec/support/fake_shared_dict")

describe("api_handler", function()
  local cache

  setup(function()
    cache = Dict:new()
    prefix_handler.cache = cache
    ssl_handler.cache = cache
  end)

  describe("POST /invalidate/:domain", function()
    before_each(function()
      cache:set("sample-shop.rise.cloud:pfx", "beef00-1007")
      cache:set("foo-bar-express.rise.cloud:pfx", "q8w9e0-678")
      cache:set("namu-wiki.rise.cloud:pfx", "n1am0u-257")

      cache:set("sample-shop.rise.cloud:dcrt", "sample-shop-certificate")
      cache:set("sample-shop.rise.cloud:dkey", "sample-shop-private-key")

      cache:set("foo-bar-express.rise.cloud:dcrt", "foo-bar-express-certificate")
      cache:set("foo-bar-express.rise.cloud:dkey", "foo-bar-express-private-key")

      cache:set("namu-wiki.rise.cloud:dcrt", "namu-wiki-certificate")
      cache:set("namu-wiki.rise.cloud:dkey", "namu-wiki-private-key")
    end)

    it("invalidates cached prefix for a given domain", function()
      api_handler.handle("POST", "/invalidate/foo-bar-express.rise.cloud")
      assert.is_nil(cache:get("foo-bar-express.rise.cloud:pfx"))
      assert.are.equal(cache:get("sample-shop.rise.cloud:pfx"), "beef00-1007")
      assert.are.equal(cache:get("namu-wiki.rise.cloud:pfx"), "n1am0u-257")
    end)

    it("invalidates cached ssl cert for a given domain", function()
      api_handler.handle("POST", "/invalidate/foo-bar-express.rise.cloud")
      assert.is_nil(cache:get("foo-bar-express.rise.cloud:dcrt"))
      assert.is_nil(cache:get("foo-bar-express.rise.cloud:dkey"))

      assert.are.equal(cache:get("sample-shop.rise.cloud:dcrt"), "sample-shop-certificate")
      assert.are.equal(cache:get("sample-shop.rise.cloud:dkey"), "sample-shop-private-key")

      assert.are.equal(cache:get("namu-wiki.rise.cloud:dcrt"), "namu-wiki-certificate")
      assert.are.equal(cache:get("namu-wiki.rise.cloud:dkey"), "namu-wiki-private-key")
    end)
  end)
end)
