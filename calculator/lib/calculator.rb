require 'faraday'
require 'async'
require 'json'

class Calculator

  def initialize()
    @statistics = { }
    @mutex = Mutex.new
  end


  def call
    calculate
  end

  private

  #
  # kinds: a,b,c - тип вычисления 
  # r - результат
  #
  def execute(name, kind, &block)
    @mutex.synchronize do
      @statistics[name] = nil
    end
          
    started_at = Time.now
    result = yield
    completed_at = Time.now
    duration = completed_at - started_at

    @mutex.synchronize do
      @statistics[name] = {
        started_at: started_at.to_f,
        completed_at: completed_at.to_f,
        duration: duration,
        result: result,
        kind: kind
      }
    end

    result
  end

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

  # Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
  # Надо сделать в пределах 7 секунд
  def process()
    started_at = Time.now
    a11 = a(11)
    a12 = a(12)
    a13 = a(13)
    b1 = b(1)

    ab1 = "#{collect_sorted([a11, a12, a13])}-#{b1}"
    log "AB1 = #{ab1}"

    c1 = c(ab1)
    log "C1 = #{c1}"

    a21 = a(21)
    a22 = a(22)
    a23 = a(23)
    b2 = b(2)

    ab2 = "#{collect_sorted([a21, a22, a23])}-#{b2}"
    log "AB2 = #{ab2}"

    c2 = c(ab2)
    log "C2 = #{c2}"

    a31 = a(31)
    a32 = a(32)
    a33 = a(33)
    b3 = b(3)

    ab3 = "#{collect_sorted([a31, a32, a33])}-#{b3}"
    log "AB3 = #{ab3}"

    c3 = c(ab3)
    log "C3 = #{c3}"

    c123 = collect_sorted([c1, c2, c3])
    result = a(c123)

    log "RESULT = #{result}"
    completed_at = Time.now
    duration = completed_at - started_at

    log "start: #{started_at}, completed_at: #{completed_at}, duration: #{duration}"

    [200, {}, [result]]
  end


  def calculate()
    started_at = Time.now
    #
    # Одновременно считаем знаения для a(1|2)* и b(1|2)
    #
    thread_pool_1 = [
      Thread.new {
        [
          Thread.new { execute(:a11, :a) { a(11) } },
          Thread.new { execute(:a12, :a) { a(12) } },
          Thread.new { execute(:a13, :a) { a(13) } },
        ].map(&:value) + [
          Thread.new { execute(:a21, :a) { a(21) } },
          Thread.new { execute(:a22, :a) { a(22) } },
          Thread.new { execute(:a23, :a) { a(23) } },
        ].map(&:value)
      },

      Thread.new {
        [
          Thread.new { execute(:b1, :b) { b(1) } }, 
          Thread.new { execute(:b2, :b) { b(2) } }
        ].map(&:value)
      }
    ].map(&:value)

    a_1_2_vals = thread_pool_1[0]
    b_1_2_vals = thread_pool_1[1]
    
    a11 = a_1_2_vals[0]
    a12 = a_1_2_vals[1]
    a13 = a_1_2_vals[2]
    b1  = b_1_2_vals[0]

    a21 = a_1_2_vals[3]
    a22 = a_1_2_vals[4]
    a23 = a_1_2_vals[5]
    b2  = b_1_2_vals[1]
    
    ab1 = "#{collect_sorted([a11, a12, a13])}-#{b1}"
    ab2 = "#{collect_sorted([a21, a22, a23])}-#{b2}"
    #
    # Одновременно считаем знаения для a3* и b3 и c(1|2)
    #
    thread_pool_2 = [
      Thread.new { execute(:a31, :a) { a(31) } },
      Thread.new { execute(:a32, :a) { a(32) } },
      Thread.new { execute(:a33, :a) { a(33) } },
      Thread.new { execute(:b3, :b) { b(3) } },
      Thread.new { [
        execute(:c1, :c) { c(ab1) },
        execute(:c2, :c) { c(ab2) }
      ] }
    ].map(&:value)

    a31 = thread_pool_2[0]
    a32 = thread_pool_2[1]
    a33 = thread_pool_2[2]
    b3  = thread_pool_2[3]

    c_1_2_vals = thread_pool_2[4]
    c1  = c_1_2_vals[0]
    c2  = c_1_2_vals[1]

    ab3 = "#{collect_sorted([a31, a32, a33])}-#{b3}"
    #
    # Осталось посчитать только c3 и result
    #
    c3 = execute(:c3, :c) { c(ab3) }

    c123 = collect_sorted([c1, c2, c3])

    result = execute(:r, :r) { a(c123) }
    
    completed_at = Time.now
    duration = completed_at - started_at

    log "RESULT = #{result}"
    log "start: #{started_at}, completed_at: #{completed_at}, duration: #{duration}"
    
    json = JSON.generate({ 
      result: result, 
      statistics: @statistics,
      started_at: started_at.to_f,
      completed_at: completed_at.to_f,
      duration: duration
    })

    [200, {}, [json]]
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def log(str)
    puts str
  end
end
