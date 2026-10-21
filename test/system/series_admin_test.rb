require 'application_system_test_case'

class SeriesAdminTest < ApplicationSystemTestCase
  test "creating a series with the color picker shows its color on club pages" do
    sign_in_to_club users(:webmaster)
    visit_club '/series/edit'
    assert_selector 'h1', text: 'Edit Series'

    fill_in 'series[acronym]', with: 'SL'
    fill_in 'series[name]', with: 'Summer League'

    # The color picker pops up from the input group addon
    find('.color-picker .input-group-addon').click
    assert_selector '.colorpicker.colorpicker-visible'
    fill_in 'series[color]', with: 'rgba(0,128,0,1)'
    find('h1', text: 'Edit Series').click
    assert_no_selector '.colorpicker.colorpicker-visible'

    check 'series[is_current]'
    click_button 'Save'

    assert_text 'The series has been updated.'
    assert_selector 'h1', text: 'Series'
    series = Series.find_by(club: clubs(:cluba), name: 'Summer League')
    assert_not_nil series
    assert_equal 'SL', series.acronym
    assert_equal 'rgba(0,128,0,1)', series.color
    assert series.is_current

    # The series color reaches the calendar legend through the series CSS
    visit_club '/events/index'
    legend_item = find(".series-legend li.series-#{series.id}", text: 'Summer League')
    assert_equal 'rgb(0, 128, 0)', legend_item.evaluate_script('getComputedStyle(this).color')
  end

  test "editing a series updates its color everywhere" do
    series = series(:cluba_wednesday)
    sign_in_to_club users(:webmaster)
    visit_club '/series/index'

    within find('tr', text: 'Wednesday Evening Series') do
      find('a[href="/series/edit/' + series.id.to_s + '"]').click
    end
    assert_selector 'h1', text: 'Edit Series'
    # The color picker rehydrates the stored color (its HSB round trip may
    # shift the value by a hair)
    assert_match(/\A#ff6[56]00\z/, find_field('series[color]').value)

    # The picker keeps the stored format (hex here), so edit with a hex color
    fill_in 'series[color]', with: '#ff00ff'
    click_button 'Save'

    assert_text 'The series has been updated.'
    assert_equal '#ff00ff', series.reload.color

    visit_club '/events/index'
    legend_item = find(".series-legend li.series-#{series.id}", text: 'Wednesday Evening Series')
    assert_equal 'rgb(255, 0, 255)', legend_item.evaluate_script('getComputedStyle(this).color')
  end
end
