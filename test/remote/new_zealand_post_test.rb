require 'test_helper'

class NewZealandPostTest < Test::Unit::TestCase

  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier   = NewZealandPost.new(fixtures(:new_zealand_post).merge(:test => true))
  end
    
  def test_valid_credentials
    assert @carrier.valid_credentials?
  end
    
  def test_successful_rates_request
    response = @carrier.find_rates(@locations[:wellington],
                                   @locations[:wellington],
                                   @packages[:book])
                                   
    assert response.is_a?(RateResponse)
    assert response.success?
    assert response.rates.any?
    assert response.rates.first.is_a?(RateEstimate)
  end

  def test_successful_rates_request_with_multiple_packages
    response = @carrier.find_rates(@locations[:wellington],
                                   @locations[:wellington],
                                   @packages.values_at(:book, :wii))
                                   
    assert response.is_a?(RateResponse)
    assert response.success?
    assert response.rates.any?
    assert response.rates.first.is_a?(RateEstimate)
  end

  def test_failure_rates_request
    begin
      @carrier.find_rates(@locations[:wellington],
                          @locations[:wellington],
                          @packages[:shipping_container])
                   
      flunk "expected an ActiveMerchant::Shipping::ResponseError to be raised"
    rescue ActiveMerchant::Shipping::ResponseError => e
      assert_match /Length can only be between 0 and 150cm/, e.message
    end
  end

  def test_multiple_packages_are_combined_correctly
    response_wii = @carrier.find_rates(@locations[:wellington],
                                       @locations[:wellington],
                                       @packages[:wii])
    response_book = @carrier.find_rates(@locations[:wellington],
                                        @locations[:wellington],
                                        @packages[:book])
    response_combined = @carrier.find_rates(@locations[:wellington],
                                            @locations[:wellington],
                                            @packages.values_at(:book, :wii))

    # ensure we got something back
    assert response_combined.is_a?(RateResponse)
    assert response_combined.success?

    assert_equal 1, response_wii.rate_estimates.size, 'the API should have selected the cheapest postage_only product (just one)'
    assert response_wii.rates.first.is_a?(RateEstimate)
    assert_equal 1, response_book.rate_estimates.size, 'the API should have selected the cheapest postage_only product (just one)'
    assert response_book.rates.first.is_a?(RateEstimate)
    assert_equal 1, response_combined.rate_estimates.size, 'should have created a single combined rate_estimate'
    assert response_combined.rates.first.is_a?(RateEstimate)

    assert_equal response_combined.rates.first.total_price, response_wii.rates.first.total_price + response_book.rates.first.total_price

    #uncomment this test for visual display of combining rates
    # puts "\nWii:"
    # response_wii.rate_estimates.each{ |r| puts "\nTotal Price: #{r.total_price}\nService Name: #{r.service_name} (#{r.service_code})" }
    # puts "\nBook:"
    # response_book.rate_estimates.each{ |r| puts "\nTotal Price: #{r.total_price}\nService Name: #{r.service_name} (#{r.service_code})" }
    # puts "\nCombined"
    # response_combined.rate_estimates.each{ |r| puts "\nTotal Price: #{r.total_price}\nService Name: #{r.service_name} (#{r.service_code})" }
  end
end
