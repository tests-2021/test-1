require 'sinatra/base'
require 'sinatra/cors'
require_relative 'calculator.rb'
require 'sinatra'
require 'sinatra-websocket'

class CalculatorApp < Sinatra::Base
  register Sinatra::Cors

  set :allow_origin, "http://localhost:9294"
  set :allow_methods, "GET"

  set :server, 'thin'
  set :sockets, []

  get "/calculate" do
    Calculator.new.optimized_call
  end

  get "/reference" do
    Calculator.new.call
  end

  get '/websocket' do
    if !request.websocket?
      erb :index
    else
      puts 'ssssocket'
      request.websocket do |ws|
        ws.onopen do
          ws.send("Hello World!")
          settings.sockets << ws
        end
        ws.onmessage do |msg|
          EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        end
        ws.onclose do
          warn("websocket closed")
          settings.sockets.delete(ws)
        end
      end
    end
  end
end

# Build the middleware stack:
use CalculatorApp # Then, it will get to Sinatra.
run lambda {|env| [404, {}, []]} # Bottom of the stack, give 404.
