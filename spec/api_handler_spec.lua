local api_handler = require('api_handler')
local Dict = require("spec/support/fake_shared_dict")

describe("api_handler", function()
  local cache

  setup(function()
    cache = Dict:new()
    api_handler.cache = cache
  end)

  describe("POST /invalidate/:domain", function()
    before_each(function()
      cache:set("sample-shop.rise.cloud:pfx", "beef00-1007")
      cache:set("foo-bar-express.rise.cloud:pfx", "q8w9e0-678")
      cache:set("namu-wiki.rise.cloud:pfx", "n1am0u-257")
    end)

    it("invalidates cached prefix for a given domain", function()
      api_handler.handle("POST", "/invalidate/foo-bar-express.rise.cloud")
      assert.is_nil(cache:get("foo-bar-express.rise.cloud:pfx"))
      assert.are.equal(cache:get("sample-shop.rise.cloud:pfx"), "beef00-1007")
      assert.are.equal(cache:get("namu-wiki.rise.cloud:pfx"), "n1am0u-257")
    end)
  end)
end)
