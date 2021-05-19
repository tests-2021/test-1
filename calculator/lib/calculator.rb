require 'faraday'

class Calculator
  def call
    process
  end

  def acall
    together_process
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

  # Решение с распараллеливанием запросов к API
  def together_process()
    start_time = Time.now
    results = { a: {}, b: {}, c: {} }
    timelog = []

    c_arg = ->(i) do
      n = i * 10
      a1 = results[:a][n+1]
      a2 = results[:a][n+2]
      a3 = results[:a][n+3]
      b = results[:b][i]
      "#{collect_sorted([a1, a2, a3])}-#{b}"
    end

    # Запуск запроса в рамках одного уровня
    start_within = ->(tier, func, arg, num = nil) do
      index = num || arg
      timelog << { name: "#{func}#{index}", time: Time.now - start_time }
      tier << Thread.new(arg, index) {|a, i| result = send(func, a); results[func][i] = result }
    end

    # Ожидание выполнения запросов одного уровня
    wait_for = ->(tier) { tier.each {|t| t.join } }

    tier_a1, tier_a2, tier_a3 = [], [], []
    tier_b1, tier_b2 = [], []
    tier_c1, tier_c2 = [], []

    start_within.call(tier_a1, :a, 11)
    start_within.call(tier_a1, :a, 12)
    start_within.call(tier_a1, :a, 13)
    start_within.call(tier_b1, :b, 1)
    start_within.call(tier_b1, :b, 2)

    wait_for.call(tier_a1)

    start_within.call(tier_a2, :a, 21)
    start_within.call(tier_a2, :a, 22)
    start_within.call(tier_a2, :a, 23)

    wait_for.call(tier_a2 + tier_b1)

    start_within.call(tier_a2, :a, 31)
    start_within.call(tier_a2, :a, 32)
    start_within.call(tier_a2, :a, 33)
    start_within.call(tier_b2, :b, 3)
    ab1 = c_arg.call(1)
    start_within.call(tier_c1, :c, ab1, 1)

    wait_for.call(tier_a3 + tier_c1)

    ab2 = c_arg.call(2)
    start_within.call(tier_c2, :c, ab2, 2)

    wait_for.call(tier_c2 + tier_b2)

    timelog << { name: 'c3', time: Time.now - start_time }
    ab3 = c_arg.call(3)
    results[:c][3] = c(ab3)

    timelog << { name: 'ac', time: Time.now - start_time }
    c123 = collect_sorted([results[:c][1], results[:c][2], results[:c][3]])
    result = a(c123)
    log "RESULT = #{result}"

    [200, {}, [{ result: result, timelog: timelog }.to_json]]
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

    [200, {}, [result]]
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def log(str)
    puts str
  end
end
