Recaptcha.configure do |config|
  config.site_key = Settings.recaptchaSiteKey
  config.secret_key = Settings.recaptchaSecretKey
end
