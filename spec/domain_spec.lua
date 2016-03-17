local context = describe
local domain = require('domain')
local http = require('resty.http')

describe("domain", function()
  describe(".get_meta", function()
    local httpstub

    before_each(function()
      httpstub = {request_uri=function() end}
      stub(http, 'new', httpstub)
    end)

    after_each(function()
      http.new:revert()
    end)

    context("when metadata json file cannot be fetched", function()
      context("when s3 returns 403", function()
        before_each(function()
          httpstub.request_uri = function(self, uri, opts)
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
          j, err = domain.get_meta("foo-bar-express.rise.cloud")
          assert.is_nil(j)
          assert.are.equal(err, "not found")
        end)
      end)

      context("when s3 returns some other errorneous response code", function()
        before_each(function()
          httpstub.request_uri = function(self, uri, opts)
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
          j, err = domain.get_meta("foo-bar-express.rise.cloud")
          assert.is_nil(j)
          assert.are.equal(err, "500 <XML>foobar</XML>")
        end)
      end)
    end)

    context("when metadata json file can be fetched successfully", function()
      before_each(function()
        httpstub.request_uri = function(self, uri, opts)
          assert.are.equal(uri, "http://test-s3.example.com/domains/foo-bar-express.rise.cloud/meta.json")
          assert.is_not_nil(opts)
          assert.are.equal(opts.method, "GET")
          return {
            status = 200,
            body = '{"webroot": "deployments/bafb79-26/webroot"}'
          }, nil
        end
      end)

      it("returns info and no error", function()
        j, err = domain.get_meta("foo-bar-express.rise.cloud")
        assert.is_nil(err)
        assert.are.same(j, { webroot = "deployments/bafb79-26/webroot" })
      end)
    end)
  end)
end)
