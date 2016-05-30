local sha256 = require "resty.sha256"
local string = require "resty.string"
local auth = require('auth')

describe("auth", function()
  describe(".authenticate", function()
    it("returns 'invalid_header' when header is empty", function()
      local err, _ = auth.authenticate(nil, "user", "pa55w0rd")

      assert.are.equal(err, auth.err_invalid_header)
    end)

    it("returns 'invalid_header' when header does not contain 'Basic'", function()
      local err, _ = auth.authenticate('Something hihi', "user", "pa55w0rd")

      assert.are.equal(err, auth.err_invalid_header)
    end)

    it("returns 'invalid_header' when header does not contain base64 encoded credential", function()
      local err, _ = auth.authenticate('Basic notvalidbase64', "user", "pa55w0rd")

      assert.are.equal(err, auth.err_invalid_header)
    end)

    it("returns 'invalid_username' when header does not contain valid username", function()
      local err, _ = auth.authenticate('Basic aGVsbG86cGE1NXcwcmQ=\n', "user", "pa55w0rd")

      assert.are.equal(err, auth.err_invalid_username)
    end)

    it("returns 'invalid_password' when header does not contain valid password", function()
      local sha256_writer = sha256:new()
      sha256_writer:update("user:password")
      local encrypted_password = string.to_hex(sha256_writer:final())

      local encoded_credentials = ngx.encode_base64("user:pa55w0rd")
      local err, _ = auth.authenticate('Basic '..encoded_credentials, "user", encrypted_password)

      assert.are.equal(err, auth.err_invalid_password)
    end)

    it("returns nil when header contains valid username and password", function()
      local sha256_writer = sha256:new()
      sha256_writer:update("user:password")
      local encrypted_password = string.to_hex(sha256_writer:final())

      local encoded_credentials = ngx.encode_base64("user:password")
      local err, _ = auth.authenticate('Basic '..encoded_credentials, "user", encrypted_password)

      assert.is_nil(err)
    end)
  end)
end)
