class PagesController < ApplicationController
  skip_before_action :require_authentication

  layout "marketing"

  def home
    redirect_to dashboard_path if resume_session
  end

  def privacy
  end

  def terms
  end

  def cookies_policy
  end

  def sitemap
    @sitemap_urls = [
      {
        loc: root_url,
        lastmod: Date.current,
        changefreq: "weekly",
        priority: 1.0
      },
      {
        loc: pricing_url,
        lastmod: Date.current,
        changefreq: "monthly",
        priority: 0.8
      },
      {
        loc: privacy_url,
        lastmod: Date.current,
        changefreq: "yearly",
        priority: 0.5
      },
      {
        loc: terms_url,
        lastmod: Date.current,
        changefreq: "yearly",
        priority: 0.5
      },
      {
        loc: cookies_path,
        lastmod: Date.current,
        changefreq: "yearly",
        priority: 0.5
      }
    ]
    render layout: false
  end
end
