Recaptcha.configure do |config|
  config.public_key = Settings.recaptchaPublicKey 
  config.private_key = Settings.recaptchaPrivateKey
end
