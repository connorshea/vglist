# frozen_string_literal: true

# Serves the Vue SPA's index.html for client-side routing.
# In production, the built frontend is copied to public/.
class SpaController < ActionController::API
  def index
    if Rails.env.development?
      vite_port = ENV.fetch('VITE_PORT', '5173')
      redirect_to "http://localhost:#{vite_port}#{request.fullpath}", allow_other_host: true
      return
    end

    index_path = Rails.root.join("public/index.html")

    if File.exist?(index_path)
      set_csp_header
      render file: index_path, layout: false, content_type: 'text/html'
    else
      render json: { error: 'Frontend not built. Run: cd frontend && yarn build && cp -r dist/* ../public/' }, status: :not_found
    end
  end

  private

  def set_csp_header
    digital_ocean_spaces = 'https://vglist.sfo2.digitaloceanspaces.com'
    cloudflare_insights  = 'https://static.cloudflareinsights.com'

    directives = [
      "default-src 'self'",
      "base-uri 'self'",
      "form-action 'self'",
      "object-src 'none'",
      "frame-ancestors 'none'",
      "font-src 'self' data:",
      # Game covers and user avatars are served from our DO Spaces bucket.
      "img-src 'self' data: #{digital_ocean_spaces}",
      # Cloudflare Web Analytics auto-injects its beacon from static.cloudflareinsights.com.
      "script-src 'self' #{cloudflare_insights}",
      # Vue's :style bindings render inline style attributes at runtime, which require
      # 'unsafe-inline' under CSP. We never render untrusted HTML so this is low-risk.
      "style-src 'self' 'unsafe-inline'"
    ]

    if Rails.env.production?
      directives << "connect-src 'self' https://cloudflareinsights.com #{cloudflare_insights} #{digital_ocean_spaces} https://*.sentry.io"

      sentry_uri = ENV['SENTRY_SECURITY_REPORT_URI']
      commit_sha = ENV['GIT_COMMIT_SHA']
      directives << "report-uri #{sentry_uri}&sentry_environment=production&sentry_release=#{commit_sha}" if sentry_uri.present?
    else
      directives << "connect-src 'self' https: ws://localhost:* http://localhost:*"
    end

    response.headers['Content-Security-Policy'] = directives.join('; ')
  end
end
