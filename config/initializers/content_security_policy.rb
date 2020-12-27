# typed: strict
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src :self, :https, :data
  policy.img_src :self, :https, :data
  policy.object_src :none
  # TODO: Disable unsafe_eval in production.
  # Maybe with this? https://github.com/rails/webpacker/issues/1520#issuecomment-399112369
  policy.script_src :self, :https, :unsafe_eval
  # Allow unsafe_inline because vue-select uses inline styles I guess?
  policy.style_src :self, :https, :unsafe_inline

  # Allow Webpacker to connect in development
  policy.connect_src :self, :https, 'http://localhost:3035', 'ws://localhost:3035' if Rails.env.development?
  # Allow Cloudflare Web Analytics in production, and allow loading and
  # uploading images from DigitalOcean.
  policy.connect_src :self, 'https://cloudflareinsights.com', 'https://static.cloudflareinsights.com', 'https://vglist.sfo2.digitaloceanspaces.com' if Rails.env.production?

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
