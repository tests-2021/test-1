require 'concurrent-ruby'
require 'faraday'

class AsyncRequester

  include Concurrent::Async

  def a(value)
    JSON.parse Faraday.get("http://server:9292/a?value=#{value}").body
  end

  def b(value)
    JSON.parse Faraday.get("http://server:9292/b?value=#{value}").body
  end

  def c(value)
    JSON.parse Faraday.get("http://server:9292/c?value=#{value}").body
  end

end
