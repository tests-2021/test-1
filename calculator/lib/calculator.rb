require_relative 'task_queue'
require_relative 'task'

QUEUES = {
  a: TaskQueue.new(3),
  b: TaskQueue.new(2),
  c: TaskQueue.new(1)
}

class Calculator
  def call(&block)
    a11 = Task.new(:a, 'a11') { 11 }
    a12 = Task.new(:a, 'a12') { 12 }
    a13 = Task.new(:a, 'a13') { 13 }
    b1 = Task.new(:b, 'b1') { 1 }

    c1 = Task.new(:c, 'c1', [a11, a12, a13, b1]) do |a11:, a12:, a13:, b1:|
      "#{collect_sorted([a11, a12, a13])}-#{b1}"
    end

    a21 = Task.new(:a, 'a21') { 21 }
    a22 = Task.new(:a, 'a22') { 22 }
    a23 = Task.new(:a, 'a23') { 23 }
    b2 = Task.new(:b, 'b2') { 2 }

    c2 = Task.new(:c, 'c2', [a21, a22, a23, b2]) do |a21:, a22:, a23:, b2:|
      "#{collect_sorted([a21, a22, a23])}-#{b2}"
    end

    a31 = Task.new(:a, 'a31') { 31 }
    a32 = Task.new(:a, 'a32') { 32 }
    a33 = Task.new(:a, 'a33') { 33 }
    b3 = Task.new(:b, 'b3') { 3 }

    c3 = Task.new(:c, 'c3', [a31, a32, a33, b3]) do |a31:, a32:, a33:, b3:|
      "#{collect_sorted([a31, a32, a33])}-#{b3}"
    end

    a123 = Task.new(:a, 'a123', [c1, c2, c3]) do |c1:, c2:, c3:|
      collect_sorted([c1, c2, c3])
    end

    a123.process { |answer| block.call(answer) }
  end

  private

  def collect_sorted(arr)
    arr.sort.join('-')
  end
end