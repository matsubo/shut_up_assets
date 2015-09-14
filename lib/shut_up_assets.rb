require 'rails/railtie'
require 'rails/rack/logger'
require 'active_support/configurable'

class ShutUpAssets < Rails::Railtie # :nodoc-all:
  class << self
    def enabled?
      config.quiet_assets
    end

    def suppress_on?(request)
      enabled? && request.get? && request.filtered_path =~ config.shut_up_assets.pattern
    end
  end

  class RackLogger < Rails::Rack::Logger
    def call_app(request, env)
      return super unless ShutUpAssets.suppress_on?(request)
      logger.silence(::Logger::WARN) { super }
    end
  end

  config.quiet_assets = true
  config.shut_up_assets = ActiveSupport::OrderedOptions.new
  config.shut_up_assets.paths   = []
  config.shut_up_assets.pattern = nil

  initializer 'shut_up_assets.set_matching_pattern', after: 'sprockets.environment' do |app|
    config = app.config
    options = app.config.shut_up_assets

    if ShutUpAssets.enabled?
      config.assets.logger = false
      options.pattern = begin
        pattern = "\/{0,2}#{config.assets.prefix}"
        pattern = "(#{Regexp.union([pattern].concat(Array.wrap(options.paths))).source})" if options.paths.size > 0
        /\A#{pattern}/
      end
    end

    ActiveSupport.on_load(:shut_up_assets) do
      options.each { |k,v| config.shut_up_assets.send("#{k}=", v) }
    end
  end

  config.app_middleware.swap Rails::Rack::Logger, ShutUpAssets::RackLogger

  ActiveSupport.run_load_hooks(:shut_up_assets, self)
end