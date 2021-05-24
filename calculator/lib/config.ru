require 'sinatra/base'
require 'sinatra/cors'
require 'json'

require_relative 'calculator'
require_relative 'async_calculator'
require_relative 'async_requester'

class CalculatorApp < Sinatra::Base
  register Sinatra::Cors

  set :allow_origin, 'http://localhost:4200'
  set :allow_methods, 'GET, HEAD, POST, OPTIONS'

  get '/calculate' do
    content_type :json

    AsyncCalculator.new.call.to_json
  end

  get '/reference' do
    Calculator.new.call
  end
end

# Build the middleware stack:
use CalculatorApp # Then, it will get to Sinatra.
run ->(_env) { [404, {}, []] } # Bottom of the stack, give 404.
