class MeasurementGraphOptions
  attr_reader :measurements,
              :options

  SUBJECT_TYPES = {
    "p" => "Project",
    "u" => "User"
  }.freeze

  PARAMETERS = %i{
    subject_type
    projects
    start_time
    end_time
    min
    max
    width
    height
  }.freeze



  def self.from_params(params)
    self.new(params.each_with_object({}) do |(key, value), options|
      case key
      # Data params
      when "n" then options[:measurements] = value.split(";")
      when "t" then options[:subject_type] = SUBJECT_TYPES[value]
      when "p" then options[:projects] = value.split(",")
      when "s" then options[:start_time] = Time.at(value.to_i)
      when "e" then options[:end_time] = Time.at(value.to_i)

      # Graph params
      when "l" then options[:min] = value.to_i
      when "u" then options[:max] = value.to_i
      when "w" then options[:width] = value.to_i
      when "h" then options[:height] = value.to_i
      end
    end)
  end

  def to_params
    # Data params
    params = { "n" => measurements.join(";") }
    params["t"] = SUBJECT_TYPES.key(subject_type) unless default?(:subject_type)
    params["p"] = projects.join(",") unless default?(:projects)
    params["s"] = start_time.to_i unless default?(:start_time)
    params["e"] = end_time.to_i unless default?(:end_time)

    # Graph params
    params["l"] = min unless default?(:min)
    params["u"] = max unless default?(:max)
    params["w"] = width unless default?(:width)
    params["h"] = height unless default?(:height)
    params
  end



  def initialize(options)
    @measurements = Array.wrap(options.fetch(:measurements))
    @options = options.except(:measurements)

    unexpected_keys = (@options.keys - PARAMETERS)
    raise ArgumentError, "Unexpected options: #{unexpected_keys.map(&:inspect).join(", ")}" if unexpected_keys.any?
  end

  def start_time
    options.fetch(:start_time, 1.month.ago)
  end

  def end_time
    options.fetch(:end_time, Time.now)
  end

  def min
    options.fetch(:min, nil)
  end

  def max
    options.fetch(:max, nil)
  end

  def width
    options.fetch(:width, 342)
  end

  def height
    options.fetch(:height, 102)
  end

  def subject_type
    options.fetch(:subject_type, nil)
  end

  def projects
    Array(options.fetch(:projects, []))
  end

  def default?(value)
    !options.key?(value)
  end



  def data
    @data ||= begin
      data = Measurement.named(measurements).taken_between(start_time, end_time)
      data = data.where(subject_type: subject_type) unless default?(:subject_type)
      data = data.where(subject: Project.where(slug: projects)) unless default?(:projects)
      data
    end
  end

  def to_json(options={})
    MultiJson.dump(as_json(options))
  end

  def as_json(options={})
    { data: MeasurementsPresenter.new(data),
      min: min,
      max: max,
      width: width,
      height: height }
  end

  def to_url
    "http://graph.houst.in/line.png?#{to_params.to_query}"
  end

end
