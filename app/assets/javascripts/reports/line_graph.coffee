class Houston.LineGraph

  constructor: ->
    @_margin = {top: 10, right: 10, bottom: 25, left: 50}
    @_width = 960
    @_height = 260
    @_dateFormat = "%-m/%-d"
    @_data = []

  margin: (@_margin)-> @
  width: (@_width)-> @
  height: (@_height)-> @
  min: (@_min)-> @
  max: (@_max)-> @
  selector: (@_selector)-> @
  data: (@_data)-> @
  tickFormat: (@_tickFormat)-> @
  domain: (@_domain)-> @
  timeFrame: (@_timeFrame) -> @


  render: ->
    graphWidth = @_width - @_margin.left - @_margin.right
    graphHeight = @_height - @_margin.top - @_margin.bottom

    formatDate = d3.time.format('%A')

    @x = x = d3.time.scale().range([0, graphWidth])
    @y = y = d3.scale.linear().range([graphHeight, 0])

    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .ticks(6)
      .tickFormat(d3.time.format(@_dateFormat))

    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')
      .tickSize(graphWidth)
      .ticks(3)
    yAxis = yAxis.tickFormat(@_tickFormat) if @_tickFormat

    line = d3.svg.area()
      .interpolate('monotone')
      .x((d)-> x(d.date))
      .y((d)-> y(d.y))
      # .defined((d)-> d.y?)

    data = @_data.map (d) ->
      date: new Date(d.timestamp)
      y: if _.isNull(d.value) then null else +d.value

    if @_timeFrame
      x.domain @_timeFrame
    else
      x.domain d3.extent(data, (d)-> d.date)

    [min, max] = d3.extent(data, (d)-> d.y)
    min = d3.min([min, @_min])
    max = d3.max([max, @_max])
    y.domain [min, max]

    $(@_selector).empty()
    svg = d3.select(@_selector).append('svg')
        .attr('width', @_width)
        .attr('height', @_height)
      .append('g')
        .attr('transform', "translate(#{@_margin.left},#{@_margin.top})")

    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{graphHeight})")
      .call(xAxis)

    svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{graphWidth},0)")
      .call(yAxis)

    svg.append('path')
      .attr('class', 'line')
      .attr('d', line(data))
      .attr('style', 'stroke: #333; stroke-width: 2px')
