local context = describe
local target = require('target')
local http = require('resty.http')

describe("target", function()
  describe(".resolve", function()
    local drop_dot_html = false

    before_each(function()
      local remote_fs = {
        ["/index.html"] = true,
        ["/pricing/index.html"] = true,
        ["/pricing/orgs.html"] = true,
        ["/jobs.html"] = true,
        ["/license"] = true,
        ["/license.html"] = true,
        ["/support/contact.html"] = true,
        ["/images/logo.png"] = true,
        ["/not.png.html"] = true
      }

      local httpstub = {}
      stub(http, 'new', httpstub)
      httpstub.request_uri = function(self, uri, opts)
        assert.are.equal(uri:find("http://s3.example.com/web"), 1)
        local uri_sans_webroot = uri:gsub("http://s3.example.com/web", "")
        if remote_fs[uri_sans_webroot] then
          return {
            status = 200
          }, nil
        end
        return {
          status = 403 -- s3 returns 403 forbidden when not found
        }, nil
      end
    end)

    after_each(function()
      http.new:revert()
    end)

    local case = function(description, path, return_vals)
      it(description, function()
        local target_path, should_redirect, err = target.resolve(path, "s3.example.com/web", drop_dot_html)
        assert.are.same(return_vals, {target_path, should_redirect, err})
      end)
    end

    context("when drop_dot_html option is true", function()
      before_each(function() drop_dot_html = true end)

      case("/           -> load /index.html", "/",           {"/index.html", false, nil})
      case("/index.html -> redirect to /",    "/index.html", {"/", true, nil})
      case("/index      -> redirect to /",    "/index",      {"/", true, nil})

      case("/pricing/   -> load /pricing/index.html", "/pricing/", {"/pricing/index.html", false, nil})
      case("/pricing    -> redirect to /pricing/",    "/pricing",  {"/pricing/", true, nil})

      case("/pricing/index.html -> redirect to /pricing/",     "/pricing/index.html", {"/pricing/", true, nil})
      case("/pricing/index      -> redirect to /pricing/",     "/pricing/index",      {"/pricing/", true, nil})
      case("/pricing/orgs.html  -> redirect to /pricing/orgs", "/pricing/orgs.html",  {"/pricing/orgs", true, nil})

      case("/jobs.html -> redirect to /jobs", "/jobs.html",  {"/jobs", true, nil})
      case("/jobs      -> load /jobs.html",   "/jobs",       {"/jobs.html", false, nil})

      case("/license.html -> load /license.html", "/license.html", {"/license.html", false, nil})
      case("/license      -> load /license",      "/license",      {"/license", false, nil})

      case("/support/contact.html -> redirect to /support/contact", "/support/contact.html", {"/support/contact", true, nil})
      case("/support/contact      -> load /support/contact.html",   "/support/contact",      {"/support/contact.html", false, nil})

      case("/images/logo.png -> load /images/logo.png", "/images/logo.png", {"/images/logo.png", false, nil})
      case("/not.png -> load /not.png.html", "/not.png", {"/not.png.html", false, nil})
    end)

    context("when drop_dot_html option is false", function()
      before_each(function() drop_dot_html = false end)

      case("/           -> load /index.html", "/",           {"/index.html", false, nil})
      case("/index.html -> redirect to /",    "/index.html", {"/", true, nil})

      case("/pricing/     -> load /pricing/index.html", "/pricing/",     {"/pricing/index.html", false, nil})
      case("/pricing.html -> load /pricing.html",       "/pricing.html", {"/pricing.html", false, nil})
      case("/pricing      -> load /pricing",            "/pricing",      {"/pricing", false, nil})

      case("/pricing/index.html -> redirect to /pricing/",     "/pricing/index.html", {"/pricing/", true, nil})
      case("/pricing/index      -> load /pricing/index",       "/pricing/index",      {"/pricing/index", false, nil})
      case("/pricing/orgs.html  -> load /pricing/orgs.html",   "/pricing/orgs.html",  {"/pricing/orgs.html", false, nil})
      case("/pricing/orgs       -> load /pricing/orgs",        "/pricing/orgs",       {"/pricing/orgs", false, nil})

      case("/jobs.html -> load /jobs.html", "/jobs.html", {"/jobs.html", false, nil})
      case("/jobs      -> load /jobs",      "/jobs",      {"/jobs", false, nil})

      case("/license.html -> load /license.html", "/license.html", {"/license.html", false, nil})
      case("/license      -> load /license",      "/license",      {"/license", false, nil})

      case("/support/contact.html -> load /support/contact.html", "/support/contact.html", {"/support/contact.html", false, nil})
      case("/support/contact      -> load /support/contact",      "/support/contact",      {"/support/contact", false, nil})

      case("/images/logo.png -> load /images/logo.png", "/images/logo.png", {"/images/logo.png", false, nil})
      case("/not.png -> load /not.png", "/not.png", {"/not.png", false, nil})
    end)
  end)
end)
