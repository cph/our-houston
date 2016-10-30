class @TimesheetView extends Backbone.View

  initialize: (options) ->
    @users = options.users
    @end = new Date()
    @start = 1.month().ago()
    @requests = []
    @data = []
    @components = [
      "itsm",
      "exception",
      "support",
      "chore",

      "ix-design",
      "development",

      "project-maintenance",

      "planning",
      "ux-research"
    ]
    @colors = [
      'rgba(220, 81, 27, 0.75)',
      'rgba(232, 113, 48, 0.75)',
      'rgba(239, 146, 59, 0.75)',
      'rgba(251, 195, 84, 0.75)',

      'rgba(122, 194, 197, 0.5)',
      'rgba(91, 195, 199, 0.5)',

      'rgba(26, 123, 105, 0.5)',

      'rgba(28, 28, 28, 0.5)',
      'rgba(140, 135, 134, 0.5)'
    ]

    view = @
    $("#reports_timeframes [role=tab]").click (e) ->
      switch $(@).attr("href")
        when "#week" then view.start = 1.week().ago()
        when "#month" then view.start = 1.month().ago()
        when "#3months" then view.start = 3.months().ago()
        when "#6months" then view.start = 6.months().ago()
      view.fetch()

  fetch: ->
    @abortAll()
    params =
      start: App.serverDateFormat(@start)
      end: App.serverDateFormat(@end)
      subject_type: "User"
      name: ["daily.hours.{off,worked}", "daily.hours.charged.{#{@components.join(",")}}"]
    jqXHR = $.getJSON "/api/v1/measurements", params, (measurements, response, jqXHR) =>
      i = @requests.indexOf(jqXHR)
      @requests.splice(i, 1)
      @setTimesheets measurements
      @render()
    @requests.push jqXHR

  abortAll: ->
    for request in @requests
      request.abort()
    @requests = []

  setTimesheets: (measurements) ->
    bySubjectId = {}
    for measurement in measurements.reverse()
      n = bySubjectId[measurement.subject.id] ||= { subject: measurement.subject, measurements: [] }
      n.measurements.push measurement
    @timesheets = _.values(bySubjectId)

  render: ->
    # for each subject, render a new stacked bar graph
    @$el.empty()
    for timesheet in @timesheets when @users[timesheet.subject.id]
      @$el.append """
<li class="timesheet" id="timesheet_#{timesheet.subject.id}">
  <div class="timesheet-employee">#{@users[timesheet.subject.id]}</div>
  <div class="timesheet-graph"></div>
</li>
"""
      @drawGraph(timesheet)

  drawGraph: (timesheet) ->
    stacksByDate = {}
    ceilsByDate = {}
    ptoByDate = {}
    emptyStack = Array(@components.length).fill(0)
    domain = []
    date = @start
    while date < @end
      if date.getDay() > 0 and date.getDay() < 6
        domain.push date
        stacksByDate[App.serverDateFormat(date)] = [date].concat(_.clone(emptyStack))
        ceilsByDate[App.serverDateFormat(date)] = [date, 0]
        ptoByDate[App.serverDateFormat(date)] = [date, 0, 0]
      date = 1.day().after(date)

    for {timestamp, name, value} in timesheet.measurements
      date = new Date(timestamp)
      stack = stacksByDate[App.serverDateFormat(date)]
      continue unless stack

      if name == "daily.hours.worked"
        ceilsByDate[App.serverDateFormat(date)][1] += +value
        ptoByDate[App.serverDateFormat(date)][1] += +value
        ptoByDate[App.serverDateFormat(date)][2] += +value
      else if name == "daily.hours.off"
        ptoByDate[App.serverDateFormat(date)][2] += +value
      else
        i = @components.indexOf(name.substr(20))
        stack[i + 1] += +value unless i < 0

    values = _.values(stacksByDate)
    ceils = _.values(ceilsByDate)
    bands = _.reject _.values(ptoByDate), ([date, a, b]) -> a == b

    @sprintGraph = new StackedBarGraph()
      .selector("#timesheet_#{timesheet.subject.id} > .timesheet-graph")
      .width(572)
      .height(102)
      .labels(@components)
      .colors(@colors)
      .domain(domain)
      .data(values)
      .ceils(ceils)
      .bands(bands)
      .bandColor('rgba(98, 183, 0, 0.1)')
      .bandColor('rgba(127, 158, 90, 0.0980392)')
      .bandColor('rgba(181, 208, 148, 0.14902)')
      .range([0, 10])
      .render()
