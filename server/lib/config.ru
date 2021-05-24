# falcon serve -c config.ru

require 'sinatra/base'
require 'async'
require 'json'

# Middleware that responds to incoming requests:
class Server < Sinatra::Base
  OVERHEAT_LIMITS = { a: 3, b: 2, c: 1 }.freeze
  WORK_TIMES = { a: 1, b: 2, c: 1 }.freeze
  WORK = {
    a: ->(value) { Digest::MD5.hexdigest(value) },
    b: ->(value) { Digest::SHA256.hexdigest(value) },
    c: ->(value) { Digest::SHA512.hexdigest(value) }
  }
  OVERHEAT_PENALTY = 10 # seconds

  def initialize(args)
    super
    setup
  end

  before do
    content_type :json
  end

  # GET /a?value=1
  get '/a' do
    process(:a, params).to_json
  end

  get '/b' do
    process(:b, params).to_json
  end

  get '/c' do
    process(:c, params).to_json
  end

  private

  def setup
    @@count = { a: 0, b: 0, c: 0 }
    @@mutex = Mutex.new
  end

  def process(type, params)
    start = Time.now
    increment_count(type)

    result = async_result(type, params).wait

    decrement_count(type)
    finish = Time.now

    {
      result: result,
      type: type,
      start: start,
      finish: finish,
      diff: (finish - start).round(2)
    }
  end

  def increment_count(type)
    @@mutex.synchronize do
      @@count[type] += 1
    end
  end

  def async_result(type, params)
    Async do |task|
      protect_from_overheat(type: type, task: task)
      log "#{type.to_s.upcase} starts to work"
      task.sleep WORK_TIMES[type]
      result = WORK[type].call(params['value'].to_s)
      log "#{type.to_s.upcase} is done working with #{result}"
      result
    end
  end

  def decrement_count(type)
    @@mutex.synchronize do
      @@count[type] -= 1
    end
  end

  def protect_from_overheat(type:, task:)
    return unless @@count[type] > OVERHEAT_LIMITS[type]

    log "Counters: #{@@count}"
    log "OVERHEAT IN #{type}!!!"
    log "SLEEP FOR #{OVERHEAT_PENALTY} SECONDS TO COOL DOWN!"
    task.sleep OVERHEAT_PENALTY
    log "Counters: #{@@count}"
  end

  def log(msg)
    puts msg
  end
end

# Build the middleware stack:
use Server # Then, it will get to Sinatra.
run ->(_env) { [404, {}, []] } # Bottom of the stack, give 404.
