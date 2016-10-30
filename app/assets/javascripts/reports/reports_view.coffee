class @ReportsView extends Backbone.View

  initialize: (options) ->
    @sections = options.sections
    @end = new Date()
    @start = 1.month().ago()
    @requests = []

    view = @
    $("#reports_timeframes [role=tab]").click (e) ->
      switch $(@).attr("href")
        when "#week" then view.start = 1.week().ago()
        when "#month" then view.start = 1.month().ago()
        when "#3months" then view.start = 3.months().ago()
        when "#6months" then view.start = 6.months().ago()
      view.rerender()

  render: ->
    html = ""
    i = 0
    for section in @sections
      width = section.reports.length * 5.5 - 0.85
      width = width * 23.625
      html += """
<div class="report-section">
  <h2><span style="width: #{width}px">#{section.section}</span></h2>
  <div class="report-tiles">
"""
      for report in section.reports
        html += """
    <dl class="report-tile" id="report_#{i}">
      <dt>
        <h3>#{report.name}</h3>
        <span class="report-big-number">&nbsp;</span>
      </dt>
      <dd>
        <div id="report_graph_#{i}" class="report-graph"></div>
      </dd>
    </dl>
"""
        @loadReport report, "#report_#{i}"
        i += 1

      html += """
  </div>
</div>
"""
    @$el.html html
    @rerender()

  abortAll: ->
    for request in @requests
      request.abort()
    @requests = []

  rerender: ->
    @abortAll()

    @$el.find(".report-big-number, .report-graph").empty()

    i = 0
    for section in @sections
      for report in section.reports
        @loadReport report, "#report_#{i}"
        i += 1

  loadReport: (report, selector) ->
    params = _.extend report.measurements,
      start: App.serverDateFormat(@start)
      end: App.serverDateFormat(@end)
    jqXHR = $.getJSON "/api/v1/measurements", params, (data, response, jqXHR) =>
      i = @requests.indexOf(jqXHR)
      @requests.splice(i, 1)
      @renderReport($(selector), report, data)
    @requests.push jqXHR

  renderReport: ($report, report, measurements) ->
    data = if report.map then report.map(measurements) else measurements
    mean = if report.mean then report.mean(measurements) else d3.mean(data, (measurement) ->
      if _.isNull(measurement.value) then null else +measurement.value)

    tickFormat = switch report.units
      when "%" then (n) -> d3.format(report.format ? ".1f")(n) + "%"
      when "ms" then (n) -> d3.format(report.format ? "f")(n) + "ms"
      else d3.format(report.format ? ",f")
    $report.find(".report-big-number").text(tickFormat(mean))

    graph = new Houston.LineGraph()
      .selector($report.find(".report-graph")[0])
      .width(324)
      .height(102)
      .min(report.min)
      .max(report.max)
      .tickFormat(tickFormat)
      .timeFrame([@start, @end])
      .data(data)
      .render()
