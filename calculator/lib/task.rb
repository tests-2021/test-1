require 'faraday'

class Task
  SERVER_HOST = "http://#{ENV['SERVER_HOST']}:#{ENV['SERVER_PORT']}".freeze

  attr_reader :name, :answer

  def initialize(type, name = '', depends = [], &value)
    @type = type
    @depends = depends
    @name = name
    @answer = nil
    @value = value
    @on_done = nil
    @started_at = nil
    @completed_at = nil
  end

  def process(parent = nil, &on_done)
    @parent = parent
    @on_done = on_done

    @depends.each do |depend|
      depend.process(self)
    end

    depend_complete  if @depends.empty?
  end

  def completed?
    !@answer.nil?
  end

  def depend_complete
    QUEUES[@type].add_task(self) if depends_completed?
  end

  def run
    if depends_completed?
      @started_at = Time.now
      @answer = Faraday.get("#{SERVER_HOST}/#{@type}?value=#{@value.call(depend_hash).to_s}").body
      @on_done&.call(@answer, timelog)
      @completed_at = Time.now
      @parent.depend_complete unless @parent.nil?
    end
  end

  def timelog
    {
      name: @name,
      type: @type,
      started_at: @started_at,
      completed_at: @completed_at,
      depends: @depends.map(&:timelog)
    }
  end

  private

  def depends_completed?
    @depends.all?(&:completed?)
  end

  def depend_hash
    @depends.map { |depend| [depend.name.to_sym, depend.answer] }.to_h
  end
end
