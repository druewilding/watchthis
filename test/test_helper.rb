ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"

BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
    set_fixture_class media: Media

    def stub_oembed(response)
      original = Net::HTTP.method(:get)
      Net::HTTP.define_singleton_method(:get) { |*| response }
      yield
    ensure
      Net::HTTP.define_singleton_method(:get, original)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
