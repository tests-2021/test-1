require 'sinatra/base'
require "sinatra/cors"
require_relative 'calculator.rb'

class CalculatorApp < Sinatra::Base
  get '/' do
    File.read(File.join('public', 'index.html'))
  end

  get "/calculate" do
    Calculator.new.call
  end

  get "/reference" do
    Calculator.new.call
  end
end

# Build the middleware stack:
use CalculatorApp # Then, it will get to Sinatra.
run lambda {|env| [404, {}, []]} # Bottom of the stack, give 404.
