require 'faraday'
require 'concurrent-ruby'

class Calculator
  attr_accessor :current_result, :id

  def initialize(id)
    @id = id
    @current_result = Concurrent::Hash.new
    @current_result = init_result

    @@semaphore_a ||= Concurrent::Semaphore.new(3)
    @@semaphore_b ||= Concurrent::Semaphore.new(2)
    @@semaphore_c ||= Concurrent::Semaphore.new(1)
  end

  def call
    process_calls
  end

  private

  # Есть три типа эндпоинтов API
  # Тип A:
  #   - работает 1 секунду
  #   - одновременно можно запускать не более трёх
  # Тип B:
  #   - работает 2 секунды
  #   - одновременно можно запускать не более двух
  # Тип C:
  #   - работает 1 секунду
  #   - одновременно можно запускать не более одного
  #
  def a(value)
    Faraday.get("http://server:9292/a?value=#{value}").body
  end

  def b(value)
    Faraday.get("http://server:9292/b?value=#{value}").body
  end

  def c(value)
    Faraday.get("http://server:9292/c?value=#{value}").body
  end

  def init_result
    {
      a11: { type: :a, param: 11, result: nil, latch: nil, dependencies: [] },
      a12: { type: :a, param: 12, result: nil, latch: nil, dependencies: [] },
      a13: { type: :a, param: 13, result: nil, latch: nil, dependencies: [] },
      b1: { type: :b, param: 1, result: nil, latch: nil, dependencies: [] },
      c1: { type: :c, param: :ab1, result: nil, latch: Concurrent::CountDownLatch.new(4), dependencies: [:a11, :a12, :a13, :b1] },
      a21: { type: :a, param: 21, result: nil, latch: nil, dependencies: [] },
      a22: { type: :a, param: 22, result: nil, latch: nil, dependencies: [] },
      a23: { type: :a, param: 23, result: nil, latch: nil, dependencies: [] },
      b2: { type: :b, param: 2, result: nil, latch: nil, dependencies: [] },
      c2: { type: :c, param: :ab2, result: nil, latch: Concurrent::CountDownLatch.new(4), dependencies: [:a21, :a22, :a23, :b2] },
      a31: { type: :a, param: 31, result: nil, latch: nil, dependencies: [] },
      a32: { type: :a, param: 32, result: nil, latch: nil, dependencies: [] },
      a33: { type: :a, param: 33, result: nil, latch: nil, dependencies: [] },
      b3: { type: :b, param: 3, result: nil, latch: nil, dependencies: [] },
      c3: { type: :c, param: :ab3, result: nil, latch: Concurrent::CountDownLatch.new(4), dependencies: [:a31, :a32, :a33, :b3] },
      c123: { type: :a, param: :c123, result: nil, latch: Concurrent::CountDownLatch.new(3), dependencies: [:c1, :c2, :c3] },
    }
  end

  def abX(a1,a2,a3,b,number)
    aX1 = current_result.try(:[], a1).try(:[], :result)
    aX2 = current_result.try(:[], a2).try(:[], :result)
    aX3 = current_result.try(:[], a3).try(:[], :result)
    bX = current_result.try(:[], b).try(:[], :result)
    return unless aX1 && aX2 && aX3 && bX
    result = "#{collect_sorted([aX1, aX2, aX3])}-#{bX}"
    log "AB#{number.to_s} = #{result}"
    result
  end

  def ab1
    abX(:a11,:a12,:a13,:b1,1)
  end

  def ab2
    abX(:a21,:a22,:a23,:b2,2)
  end

  def ab3
    abX(:a31,:a32,:a33,:b3,3)
  end

  def c123
    c1 = current_result.try(:[], :c1).try(:[], :result)
    c2 = current_result.try(:[], :c2).try(:[], :result)
    c3 = current_result.try(:[], :c3).try(:[], :result)
    return unless c1 && c2 && c3
    result = collect_sorted([c1, c2, c3])
    log "C123 = #{result}"
    result
  end

  # Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
  # Надо сделать в пределах 7 секунд

  def process_calls
    current_result.each do |key, value|
      Thread.new do
        value[:latch].wait() if value[:latch]
        eval("@@semaphore_" + value[:type].to_s).acquire

        param = value[:param]
        param = send(param) if param.class == Symbol
        result = JSON.parse(send(value[:type], param)).with_indifferent_access
        value[:result] = result[:result]

        eval("@@semaphore_" + value[:type].to_s).release
        release_latch(key)

        log("#{result[:type]}: #{key.to_s.upcase} -> #{result[:result]} "\
            "#{DateTime.parse(result[:started_at]).localtime.strftime('%T')}, "\
            "#{(DateTime.parse(result[:completed_at]).to_i -
                DateTime.parse(result[:started_at]).to_i)}")
      end
    end
  end

  def release_latch(done_key)
    current_result.select { |k, v| v[:dependencies].include?(done_key) }.each do |k ,v|
      v[:latch].count_down
    end
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def log(str)
    message = { id: @id, time: Time.now.strftime("%T"), info: str }
    ActionCable.server.broadcast("log_calculate", message)
  end
end
