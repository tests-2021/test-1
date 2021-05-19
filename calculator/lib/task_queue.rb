class TaskQueue
  def initialize(max_count)
    @max_count = max_count
    @queue = []
    @current = []
  end

  def add_task(task)
    @queue.push(task)
    next_task
  end

  private

  def complete(task)
    @current.delete(task)
    next_task
  end

  def next_task
    if @current.count < @max_count
      task = @queue.shift
      unless task.nil?
        @current.push(task)
        Thread.new do
          task.run
          complete(task)
        end
      end
    end
  end
end
