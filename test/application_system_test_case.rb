require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  CHROMIUM_BIN = '/usr/bin/chromium-browser'.freeze
  CHROMEDRIVER = '/usr/bin/chromedriver'.freeze

  # Use the system chromedriver when present (the Docker image installs a
  # matching chromium + chromedriver pair); otherwise Selenium Manager picks
  # one, which hangs inside the container.
  driver_options = { screen_size: [1400, 1400] }
  if File.exist?(CHROMEDRIVER)
    driver_options[:options] = { service: ::Selenium::WebDriver::Chrome::Service.new(path: CHROMEDRIVER) }
  end

  driven_by :selenium, using: :headless_chrome, **driver_options do |options|
    # Club fixture domains use .test; resolve them all to the local server
    options.add_argument('--host-resolver-rules=MAP * 127.0.0.1')
    options.add_argument('--no-sandbox')
    # Without this the GPU process hangs Chrome startup inside the container
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-dev-shm-usage')
    options.add_option('goog:loggingPrefs', { browser: 'ALL' })
    options.binary = CHROMIUM_BIN if File.exist?(CHROMIUM_BIN)
  end

  Capybara.always_include_port = true

  # Browser console errors almost always mean broken JS wiring; fail loudly.
  # Individual tests can allow expected noise via allow_console_errors(/pattern/).
  # Third-party hosts are unreachable in tests (everything resolves to the
  # local server), so their load failures are expected noise.
  IGNORED_CONSOLE_ERRORS = [
    %r{/favicon\.ico}, %r{/apple-touch-icon}, %r{/redactor/},
    /Google Maps/i, /maps\.googleapis/, /flickr/i,
    /facebook/i, /juicer/i, /oss\.maxcdn\.com/
  ].freeze

  teardown do
    raise_on_console_errors if passed?
  end

  def allow_console_errors(pattern)
    (@allowed_console_errors ||= []) << pattern
  end

  def visit_club(path = '/', club: clubs(:cluba))
    visit "http://#{club.domain}#{path}"
  end

  def visit_apex(path = '/')
    visit "http://#{Settings.host}#{path}"
  end

  def sign_in_through_browser(user, password: 'password123')
    user.update!(password: password, password_confirmation: password)
    visit_apex '/users/sign_in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: password
    click_button 'Log in'
  end

  private

  def raise_on_console_errors
    logs = page.driver.browser.logs.get(:browser)
    ignored = IGNORED_CONSOLE_ERRORS + (@allowed_console_errors || [])
    errors = logs.select { |entry| entry.level == 'SEVERE' }
                 .reject { |entry| ignored.any? { |pattern| entry.message =~ pattern } }
    assert errors.empty?, "Browser console errors:\n#{errors.map(&:message).join("\n")}"
  end
end
