class AsyncCalculator
  def call
    {
      result: process,
      history: @history
    }
  end

  %i[a b c].each do |kind|
    define_method(kind) do |value|
      AsyncRequester.new.async.send(kind, value)
    end
  end

  private

  def process
    a11 = a(11)
    a12 = a(12)
    a13 = a(13)
    b1 = b(1)
    b2 = b(2)

    ab1 = "#{collect_sorted([value(a11), value(a12), value(a13)])}-#{value(b1)}"
    log "AB1 = #{ab1}"

    a21 = a(21)
    a22 = a(22)
    a23 = a(23)
    b3 = b(3)
    c1 = c(ab1)

    ab2 = "#{collect_sorted([value(a21), value(a22), value(a23)])}-#{value(b2)}"
    log "AB2 = #{ab2}"
    log "C1 = #{value(c1)}"


    a31 = a(31)
    a32 = a(32)
    a33 = a(33)
    c2 = c(ab2)

    ab3 = "#{collect_sorted([value(a31), value(a32), value(a33)])}-#{value(b3)}"
    log "AB3 = #{ab3}"
    log "C2 = #{value(c2)}"

    c3 = c(ab3)
    log "C3 = #{value(c3)}"

    c123 = collect_sorted([value(c1), value(c2), value(c3)])

    result = value a(c123)
    log "RESULT = #{result}"

    result
  end

  def value(data)
    value = data.value
    (@history ||= []) << value

    value['result']
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def log(str)
    puts str
  end
end
