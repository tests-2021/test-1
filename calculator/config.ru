require 'sinatra/base'
require 'sinatra/async'
require 'eventmachine'
require_relative 'lib/calculator'
require_relative 'lib/reference_calculator'
require 'thin'

class ThreadedThinBackend < ::Thin::Backends::TcpServer
  def initialize(host, port, options)
    super(host, port)
    @threaded = true
  end
end

class CalculatorApp < Sinatra::Base
  register Sinatra::Async
  set :bind, '0.0.0.0'

  configure do
    set :server, :thin

    class << settings
      def server_settings
        { :backend => ThreadedThinBackend }
      end
    end
  end

  aget "/calculate" do
    ::Calculator.new.call { |answer| body answer }
  end

  get "/reference" do
    ::ReferenceCalculator.new.call
  end
end

CalculatorApp.start!
