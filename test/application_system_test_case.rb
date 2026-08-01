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

  # Bootstrap's fade animations move elements while Capybara computes click
  # coordinates, so clicks can land on the backdrop and dismiss modals
  # instead of hitting their buttons.
  Capybara.disable_animation = true

  # The clubsite sign-in flow bounces through absolute apex URLs
  # (Settings.coreURL), so the apex URL must point at the test server. The
  # server port is fixed so the URL can be built before the server boots.
  Capybara.server_port = 45_671
  Settings.coreURL = "http://#{Settings.host}:#{Capybara.server_port}"

  setup do
    # The browser can only reach the test server over plain http, so the SSO
    # redirects onto club domains must not use the fixtures' https protocol.
    Club.where(domain_protocol: 'https').update_all(domain_protocol: 'http')
  end

  # Browser console errors almost always mean broken JS wiring; fail loudly.
  # Individual tests can allow expected noise via allow_console_errors(/pattern/).
  # Third-party hosts are unreachable in tests (everything resolves to the
  # local server), so their load failures are expected noise.
  IGNORED_CONSOLE_ERRORS = [
    %r{/favicon\.ico}, %r{/apple-touch-icon}, %r{/redactor/},
    /Google Maps/i, /maps\.googleapis/, /flickr/i,
    /facebook/i, /juicer/i, /oss\.maxcdn\.com/, /pinterest/i
  ].freeze

  teardown do
    raise_on_console_errors if passed?
  end

  # Runs before the framework's screenshot-and-reset hook: the page is still
  # live here, so the captured URL and HTML reflect the failure state.
  def before_teardown
    save_failure_page unless passed?
    super
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
    # The page carries a second user[email] field (forgot password)
    within "form[action='/users/sign_in']" do
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: password
      click_button 'Sign in'
    end
    # The submit goes through rails-ujs, so the driver's click does not wait
    # for the resulting navigation. Wait for the signed-in page before
    # returning, or a caller's next visit races the in-flight redirect and can
    # be silently dropped.
    assert_selector 'a', text: 'Sign out'
  end

  # Signs in on the apex domain, then follows the SSO handoff so the club
  # domain has a signed-in session too.
  def sign_in_to_club(user, club: clubs(:cluba))
    sign_in_through_browser(user)
    visit_club '/users/login', club: club
    assert_selector 'a', text: 'Sign out'
    assert_equal club.domain, URI.parse(current_url).host
  end

  # Waits for a database-side effect of an in-page AJAX call. Prefer Capybara
  # matchers whenever the effect is visible in the DOM.
  def wait_for_condition(timeout: Capybara.default_max_wait_time, message: 'condition not met in time')
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      flunk message if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.1
    end
  end

  private

  # Companion to the automatic failure screenshot: the final URL and page HTML
  # make redirect-flow failures diagnosable from CI artifacts.
  def save_failure_page
    dir = Rails.root.join('tmp/screenshots')
    FileUtils.mkdir_p(dir)
    slug = "failures_#{method_name.parameterize(separator: '_')}"
    File.write(dir.join("#{slug}.url.txt"), "#{current_url}\n")
    File.write(dir.join("#{slug}.html"), page.html)
  rescue StandardError => e
    warn "Could not save failure page: #{e.message}"
  end

  def raise_on_console_errors
    logs = page.driver.browser.logs.get(:browser)
    ignored = IGNORED_CONSOLE_ERRORS + (@allowed_console_errors || [])
    errors = logs.select { |entry| entry.level == 'SEVERE' }
                 .reject { |entry| ignored.any? { |pattern| entry.message =~ pattern } }
    assert errors.empty?, "Browser console errors:\n#{errors.map(&:message).join("\n")}"
  end
end
