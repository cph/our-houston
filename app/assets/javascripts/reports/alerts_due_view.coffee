class @AlertsDueView extends Backbone.View

  initialize: (options)->
    @options = options
    @_data = options.data
    @width = options.width || 940
    @height = options.height || @width * 0.25

    @graph = new Houston.StackedAreaGraph()
      .selector(@el)
      .width(@width)
      .height(@height)
      .labels(["late", "on time"])
      .colors(['#e24e32', '#5db64c'])
      .domain(options.domain)

    @graph.data(for datum in @_data
      [datum.date, datum.closedLate, datum.closedOnTime])

  render: ->
    @graph.render()
    @

  domain: ->
    @graph.y.domain()

  toggleShowPercent: (toggle)->
    if toggle
      @graph.data(for datum in @_data
        if datum.due > 0
          [datum.date, (datum.closedLate / datum.due), (datum.closedOnTime / datum.due)]
        else
          [datum.date, 0, 0])
      @graph.domain([0, 1])
    else
      @graph.data(for datum in @_data
        [datum.date, datum.closedLate, datum.closedOnTime])
      @graph.domain(@options.domain)

    @graph.render()
