class CollectingSender
  attr_reader :collected

  def initialize
    @collected = []
  end

  def send_to_airbrake(data)
    @collected << data
  end
end
