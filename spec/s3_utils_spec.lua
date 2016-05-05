local http = require('resty.http')
local config = require('config')
local s3_utils = require('s3_utils')

describe("s3_utils", function()
  describe(".get_s3_private_file", function()
    local httpc_stub
    local time_stub

    before_each(function()
      httpc_stub = {request_uri=function() end}
      stub(http, 'new', httpc_stub)

      -- Neded for checking the signature validation of the S3 signed urls
      time_stub = function() return 1460579519 - config.s3_valid_period end
      stub(ngx, 'time', time_stub)
    end)

    after_each(function()
      http.new:revert()
      ngx.time:revert()
    end)

    context("when ssl certs can be fetched successfully", function()
      before_each(function()
        httpc_stub.request_uri = function(self, uri, opts)
          assert.are.equal(uri, "https://s3-us-west-2.amazonaws.com/rise-development-usw2/certs/foo-bar-express.rise.cloud/ssl.crt?AWSAccessKeyId=AKIAJZHYMGEHIL3THKWA&Expires=1460579519&Signature=J7qxNwJQ3bZmE8dvj9daZalg5Fg%3D")
          assert.is_not_nil(opts)
          assert.are.equal(opts.method, 'GET')
          return {
            status = 200,
            body = 'my private certificate'
          }, nil
        end
      end)

      it("returns certs and no error", function()
        local crt, err = s3_utils.get_s3_private_file(config, "/certs/foo-bar-express.rise.cloud/ssl.crt")
        assert.is_not_nil(crt)
        assert.is_nil(err)
        assert.are.same(crt, 'my private certificate')
      end)
    end)

    context("when ssl certs can't be fetched", function()
      before_each(function()
        httpc_stub.request_uri = function(self, uri, opts)
          assert.are.equal(uri, "https://s3-us-west-2.amazonaws.com/rise-development-usw2/certs/foo-bar-express.rise.cloud/ssl.crt?AWSAccessKeyId=AKIAJZHYMGEHIL3THKWA&Expires=1460579519&Signature=J7qxNwJQ3bZmE8dvj9daZalg5Fg%3D")
          assert.is_not_nil(opts)
          assert.are.equal(opts.method, "GET")
          return {
            status = 403,
            body = '<XML>Failed</XML>'
          }, nil
        end
      end)

      it("returns error if AWS returns 403", function()
        local _, err = s3_utils.get_s3_private_file(config, "/certs/foo-bar-express.rise.cloud/ssl.crt")
        assert.is_not_nil(err)
      end)
    end)
  end)
end)
