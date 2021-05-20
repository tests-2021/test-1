require 'faraday'
require 'sinatra/json'
require 'concurrent'
require 'date'

class Calculator
  def initialize()
    @a = {}
    @b = {}
    @c = []
    @ab = []
    @c_thread_pool = get_pool(1)
    @start_time = Time.now
  end
  def call
    process
  end

  def optimized_call
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
  def a(value, with_timestamps=false)
    get_parsed_response('a', value, with_timestamps)
  end

  def b(value, with_timestamps=false)
    get_parsed_response('b', value, with_timestamps)
  end

  def c(value, with_timestamps=false)
    get_parsed_response('c', value, with_timestamps)
  end

  def get_parsed_response(kind, value, with_timestamps)
    parsed = JSON.parse(Faraday.get("http://server:9292/#{kind}?value=#{value}").body)
    with_timestamps ? parsed : parsed['result']
  end

  # Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
  # Надо сделать в пределах 7 секунд
  def process()
    a11 = a(11)
    a12 = a(12)
    a13 = a(13)
    b1 = b(1)

    ab1 = "#{collect_sorted([a11, a12, a13])}-#{b1}"
    send_message "AB1 = #{ab1}"

    c1 = c(ab1)
    send_message "C1 = #{c1}"

    a21 = a(21)
    a22 = a(22)
    a23 = a(23)
    b2 = b(2)

    ab2 = "#{collect_sorted([a21, a22, a23])}-#{b2}"
    send_message "AB2 = #{ab2}"

    c2 = c(ab2)
    send_message "C2 = #{c2}"

    a31 = a(31)
    a32 = a(32)
    a33 = a(33)
    b3 = b(3)

    ab3 = "#{collect_sorted([a31, a32, a33])}-#{b3}"
    send_message "AB3 = #{ab3}"

    c3 = c(ab3)
    send_message "C3 = #{c3}"

    c123 = collect_sorted([c1, c2, c3])
    result = a(c123)
    send_message "RESULT = #{result}, Work time(sec.) = #{Time.now - @start_time}"

    [200, {}, { result: result }.to_json]
  end

  def optimized_process()
    concurrent_exec_a
    concurrent_exec_b
  end

  def concurrent_exec_a
    thread_pool = get_pool(3)
     %w[1 2 3].map do |first_key|
      @a[first_key] = []
      %w[1 2 3].map do |second_key|
        (Concurrent::Promise.new executor: thread_pool do
          value = first_key + second_key
          result = a(value, true)
          @a[first_key] << result['result']
          result_messages("A#{value}", result['result'], result['start_time'], result['finish_time'])
          check_readiness(first_key)
        end).execute
      end
    end
  end

  def concurrent_exec_b
    thread_pool = get_pool(2)
    %w[1 2 3].map do |hash_key|
      (Concurrent::Promise.new executor: thread_pool do
        result = b(hash_key, true)
        @b[hash_key] = result['result']
        result_messages("B#{hash_key}", result['result'], result['start_time'], result['finish_time'])
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
      result = c(ab_value, true)
      @c << result['result']
      result_messages("C#{hash_key}", result['result'], result['start_time'], result['finish_time'])
      if @c.size == 3
        c123 = collect_sorted(@c)
        final_result = a(c123)
        send_message "RESULT=#{final_result}, Work time(sec.) = #{Time.now - @start_time}"
      end
    end).execute
  end

  def get_pool(max_threads)
    threadPool = Concurrent::ThreadPoolExecutor.new(
      max_threads: max_threads,
      overflow_policy: :caller_runs
    )
  end

  def result_messages(var_name, result, start, finish)
    send_message("Kind: #{var_name}")
    send_message("Result: #{result}")
    send_message("Beginning time: #{Time.at(start)}")
    send_message("Completion time: #{Time.at(finish)}")
    send_message("Work time(sec.): #{finish - start}")
    send_message("_")
  end

  def send_message(msg)
    CalculatorApp.settings.sockets.each{|s| s.send(msg) }
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def log(str)
    puts str
  end
end
