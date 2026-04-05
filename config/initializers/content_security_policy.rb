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
  # Require unsafe_inline for Vue DevTools in development.
  # https://github.com/vuejs/vue-devtools/issues/616
  policy.script_src :self, :https, :unsafe_eval, :report_sample

  # Allow unsafe_inline because vue-select uses inline styles I guess?
  policy.style_src :self, :https, :unsafe_inline, :report_sample

  # Allow webpack connections in development.
  if Rails.env.development?
    policy.connect_src :self, :https, 'webpack://*'
  # Allow Cloudflare Web Analytics in production, and allow loading and
  # uploading images from DigitalOcean.
  elsif Rails.env.production?
    policy.connect_src :self,
                       'https://cloudflareinsights.com',
                       'https://static.cloudflareinsights.com',
                       'https://vglist.sfo2.digitaloceanspaces.com',
                       'https://*.sentry.io'
  end

  # Specify Sentry URI for CSP violation reports in production
  policy.report_uri "#{ENV.fetch('SENTRY_SECURITY_REPORT_URI')}&sentry_environment=#{Rails.env}&sentry_release=#{ENV.fetch('GIT_COMMIT_SHA')}" if Rails.env.production?
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# We do not currently use this with style-src because v-tooltip doesn't work
# properly with it. May want to move to a different library in the future.
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
