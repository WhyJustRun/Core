require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  test 'formatted_clubs_list escapes club-supplied acronym and location' do
    club = Club.new(url: 'https://cluba.example', acronym: '<script>alert(1)</script>',
                    location: 'Town</strong><img src=x onerror=alert(1)>')
    html = formatted_clubs_list([club])

    assert_not_includes html, '<script>alert(1)</script>'
    assert_not_includes html, '<img src=x onerror=alert(1)>'
    assert_includes html, '&lt;script&gt;'
  end
end
