require "test_helper"

class HomeController < ActionController::Base
  def index
    render :text => 'Hi there!'
  end

  def error
    raise "Breaking"
    render :text => 'Hi there!'
  end
end

class IntegrationTest < ActionController::TestCase
  EMPTY_LINE = ""
  attr_accessor :app, :output

  def initialize!(&block)
    app.configure(&block) if block_given?

    app.initialize!

    Rails.logger = ActiveSupport::Logger.new(output)
    Rails.logger.formatter = lambda { |s, d, p, m| "#{m}\n" }
  end

  def request(uri)
    Rack::MockRequest.env_for(uri)
  end

  def test_quiet_assets_pattern
    assert_match ShutUpAssets.config.shut_up_assets.pattern, '/assets/picture'
  end

  def test_assets_url_with_option_by_default
    initialize!

    app.call request('/assets/picture')

    assert_equal EMPTY_LINE, output.string
  end

  def test_assets_url_with_turned_on_option
    initialize! { config.quiet_assets = true }

    app.call request('/assets/picture')

    assert_equal EMPTY_LINE, output.string
  end

  def test_in_multi_thread_env
    initialize! { config.quiet_assets = true }

    th1 = Thread.new do
      sleep 0.1
      app.call request('/assets/picture')
    end

    th2 = Thread.new do
      sleep 0.1
      app.call request('/')
    end

    th3 = Thread.new do
      sleep 0.1
      app.call request('/assets/picture')
    end

    [th1, th2, th3].map { |i| i.join }

    n = output.string.lines.select{|i| i.match(/Started GET "\/"/) }

    assert_equal 1, n.size
  end

  def test_assets_url_with_turned_off_option
    initialize! { |app| app.config.quiet_assets = false }\

    app.call request('/assets/picture')

    assert_match(/Started GET \"\/assets\/picture\" for  at/, output.string)
  end

  def test_regular_url
    initialize!

    app.call request('/')

    assert_match(/Started GET \"\/\" for  at/, output.string)
  end

  def test_full_url_with_couple_slashes
    initialize!

    app.call request('http://some-url.com//assets/picture')

    assert_equal EMPTY_LINE, output.string
  end

  def test_quiet_url
    initialize!

    app.call request('/quiet/this')

    assert_match(/Started GET \"\/quiet\/this\" for  at/, output.string)
  end

  def test_quiet_url_with_paths_option_as_string_equality
    initialize! { config.shut_up_assets.paths = '/quiet/' }

    app.call request('/quiet/this')

    assert_equal EMPTY_LINE, output.string
  end

  def test_quiet_url_with_paths_option_as_string_appending
    initialize! { config.shut_up_assets.paths << '/quiet/' }

    app.call request('/quiet/this')

    assert_equal EMPTY_LINE, output.string
  end

  def test_quiet_url_with_paths_option_as_array
    initialize! { config.shut_up_assets.paths += ['/quiet/'] }

    app.call request('/quiet/this')

    assert_equal EMPTY_LINE, output.string
  end
end

