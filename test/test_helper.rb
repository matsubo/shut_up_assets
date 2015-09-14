require 'bundler/setup'
require 'minitest/autorun'
require 'rails'
require 'action_controller'
require 'shut_up_assets'

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

ActiveSupport.test_order = :sorted

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(:color => true)

ActionController::TestCase.class_eval do
  def setup
    @output = StringIO.new

    @app = Class.new(Rails::Application)

    @app.configure do
      config.active_support.deprecation = :notify
      config.secret_token = '685e1a60792fa0d036a82a52c0f97e42'
      config.eager_load = false

      routes do
        root :to => 'home#index'
        get 'assets/picture' => 'home#index'
        get 'quiet/this' => 'home#index'
      end
    end

    @routes = @app.routes
  end
end