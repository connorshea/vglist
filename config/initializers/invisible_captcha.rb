# Configuration for https://github.com/markets/invisible_captcha
InvisibleCaptcha.setup do |config|
  # Disable timestamp and spinner checking so the test suite doesn't get caught by it.
  config.timestamp_enabled = !Rails.env.test?
  config.spinner_enabled = !Rails.env.test?
  # Custom text for the field, no one will ever see this but it's still fun.
  config.sentence_for_humans = 'If you are a gamer, ignore this field.'
end
