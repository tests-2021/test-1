require 'faraday'
require 'sinatra/json'
require 'concurrent'

class Calculator
  def initialize()
    super
    @a = {}
    @b = {}
    @c = []
    @ab = []
    @sockets = []
    @c_thread_pool = get_pool(1)
  end
  def call
    process
  end

  def optimized_call(sockets)
    @sockets = sockets
    optimized_process
    [200, {}, { result: 'ok' }.to_json]
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
    parsed_response Faraday.get("http://server:9292/a?value=#{value}").body
  end

  def b(value)
    parsed_response Faraday.get("http://server:9292/b?value=#{value}").body
  end

  def c(value)
    parsed_response Faraday.get("http://server:9292/c?value=#{value}").body
  end

  def parsed_response response
    JSON.parse(response)['result']
  end

  # Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
  # Надо сделать в пределах 7 секунд
  def process()
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

    [200, {}, { result: result }.to_json]
  end

  def optimized_process()
    concurrent_exec_a
    concurrent_exec_b
  end

  def concurrent_exec_a
    thread_pool = get_pool(3)
     ['1','2','3'].map do |first_key|
      @a[first_key] ||= []
      ['1','2','3'].map do |second_key|
        (Concurrent::Promise.new executor: thread_pool do
          value = first_key + second_key
          result_a = a(value)
          @a[first_key] << result_a
          send_message("a#{value}=#{result_a}")
          check_readiness(first_key)
        end).execute
      end
    end
  end

  def concurrent_exec_b
    thread_pool = get_pool(2)
    ['1','2','3'].map do |hash_key|
      (Concurrent::Promise.new executor: thread_pool do
        @b[hash_key] = b(hash_key)
        send_message("b[#{hash_key}]=#{@b[hash_key]}")
        check_readiness(hash_key)
      end).execute
    end
  end

  def check_readiness(hash_key)
    if @a[hash_key].length == 3 && @b[hash_key]
      ab_value = "#{collect_sorted(@a[hash_key])}-#{@b[hash_key]}"
      @ab << ab_value
      concurrent_exec_c(ab_value, hash_key)
    end
  end

  def concurrent_exec_c(ab_value, hash_key)
    (Concurrent::Promise.new executor: @c_thread_pool do
      result_c = c(ab_value)
      @c << result_c
      send_message("c#{hash_key}=#{result}")
      if @c.size == 3
        c123 = collect_sorted(@c)
        result = a(c123)
        puts "RESULT"
        puts result
        send_message("RESULT=#{result}")
      end
    end).execute
  end

  def get_pool(max_threads)
    threadPool = Concurrent::ThreadPoolExecutor.new(
      max_threads: max_threads,
      overflow_policy: :caller_runs
    )
  end

  def send_message(msg)
    EM.next_tick { @sockets.each{|s| s.send(msg) } }
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def log(str)
    puts str
  end
end
