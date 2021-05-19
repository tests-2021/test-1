require 'sinatra/base'
require 'sinatra/cors'
require_relative 'calculator.rb'

class CalculatorApp < Sinatra::Base
  register Sinatra::Cors

  set :allow_origin, "http://localhost:9294"
  set :allow_methods, "GET"

  get "/calculate" do
    Calculator.new.optimized_call
  end

  get "/reference" do
    Calculator.new.call
  end
end

# Build the middleware stack:
use CalculatorApp # Then, it will get to Sinatra.
run lambda {|env| [404, {}, []]} # Bottom of the stack, give 404.
