Rails.application.configure do
    config.action_mailer.smtp_settings = Settings.smtpSettings.to_hash
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { :host => Settings.host }
end