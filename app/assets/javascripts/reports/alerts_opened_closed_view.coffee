class @AlertsOpenedClosedView extends Backbone.View

  initialize: (options)->
    @data = options.data
    @margin = {top: 10, right: 1, bottom: 24, left: 30}
    width = options.width || 940
    height = options.height || width * 0.25
    @width = width - @margin.left - @margin.right
    @height = height - @margin.top - @margin.bottom

    domain = options.domain
    unless domain
      max = Math.max d3.max(@data, (d)-> d.closed), d3.max(@data, (d)-> d.opened)
      domain = [-max, max]

    @y = d3.scale.linear()
      .range [@height, 0]
      .domain domain

    @x = d3.scale.ordinal()
      .rangeRoundBands([0, @width], .1)
      .domain @data.map (d)-> d.date

    @xAxis = d3.svg.axis()
      .orient("bottom")

    switch options.axis
      when "week"
        @xAxis
          .scale(@x)
          .tickFormat d3.time.format("%A")
      when "auto"
        [min, max] = d3.extent(@x.range())
        max = max + @x.rangeBand()
        xt = d3.time.scale()
          .range [min, max]
          .domain d3.extent @data, (d)-> d.date
        @xAxis.scale(xt)
      else
        throw new Error "The value of 'options.axis' must be either 'week' or 'auto'"

    @yAxis = d3.svg.axis()
      .scale(@y)
      .orient("left")

  render: ->
    svg = @$el.html('<svg class="alerts-opened-closed-graph"></svg>').children()[0]
    @chart = d3.select(svg)
      .attr("width", @width + @margin.left + @margin.right)
      .attr("height", @height + @margin.top + @margin.bottom)
      .append("g")
        .attr("transform", "translate(#{@margin.left},#{@margin.top})")

    @chart.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0,#{@height})")
      .call(@xAxis)

    @chart.append("g")
      .attr("class", "y axis")
      .call(@yAxis)

    @chart.selectAll(".bar.alerts-opened")
        .data(@data)
      .enter().append("rect")
        .attr("class", "bar alerts-opened")
        .attr("x", (d)=> @x(d.date))
        .attr("y", (d)=> @y(d.opened))
        .attr("height", (d)=> @y(0) - @y(d.opened))
        .attr("width", @x.rangeBand())

    @chart.selectAll(".bar.alerts-closed")
        .data(@data)
      .enter().append("rect")
        .attr("class", "bar alerts-closed")
        .attr("x", (d)=> @x(d.date))
        .attr("y", (d)=> @y(0))
        .attr("height", (d)=> @y(0) - @y(d.closed))
        .attr("width", @x.rangeBand())
