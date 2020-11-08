Rails.application.configure do
    config.action_mailer.smtp_settings = Settings.smtpSettings.to_hash
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { :host => Settings.host }
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
end