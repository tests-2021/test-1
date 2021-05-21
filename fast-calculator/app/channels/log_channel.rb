class LogChannel < ApplicationCable::Channel
  def subscribed
    stream_from "log_#{params[:type]}"
  end

  def receive(data)
    if data['run'] == 'calculate'
      Calculator.new(data['id']).call
    else
      ActionCable.server.broadcast("log_#{params[:type]}", data)
    end
  end
end
