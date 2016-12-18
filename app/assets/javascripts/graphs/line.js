if(typeof Houston === 'undefined') {
  var d3 = require('d3');
}

function graphLine(options) {
  var _width = options.width || 960,
      _height = options.height || 260,
      _margin = {
        top: 10,
        right: 10,
        bottom: 25,
        left: 50 },
      _dateFormat = "%-m/%-d",
      _data = options.data,
      _selector = options.selector,
      _min = options.min,
      _max = options.max,
      _tickFormat = options.tickFormat,
      _timeFrame = options.timeFrame,
      graphWidth = _width - _margin.left - _margin.right,
      graphHeight = _height - _margin.top - _margin.bottom,
      formatDate = d3.time.format('%A'),
      x = d3.time.scale().range([0, graphWidth]),
      y = d3.scale.linear().range([graphHeight, 0]);

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient('bottom')
    .ticks(6)
    .tickFormat(d3.time.format(_dateFormat));

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient('left')
    .tickSize(graphWidth)
    .ticks(3);

  if (_tickFormat) {
    yAxis = yAxis.tickFormat(_tickFormat);
  }

  line = d3.svg.area().interpolate('monotone').x(function(d) {
    return x(d.date);
  }).y(function(d) {
    return y(d.y);
  });

  data = _data.map(function(d) {
    return {
      date: new Date(d.timestamp),
      y: d.value === null ? null : +d.value
    };
  });

  if (_timeFrame) {
    x.domain(_timeFrame);
  } else {
    x.domain(d3.extent(data, function(d) {
      return d.date;
    }));
  }

  var extent = d3.extent(data, function(d) { return d.y; }),
      min = d3.min([extent[0], _min]),
      max = d3.max([extent[1], _max]);
  y.domain([min, max]);

  var svg = d3.select(_selector)
    .append('svg')
      .attr('width', _width)
      .attr('height', _height)
    .append('g')
      .attr('transform', "translate(" + _margin.left + "," + _margin.top + ")");

  svg.append('g')
    .attr('class', 'x axis')
    .attr('transform', "translate(0," + graphHeight + ")")
    .call(xAxis);

  svg.append('g')
    .attr('class', 'y axis')
    .attr('transform', "translate(" + graphWidth + ",0)")
    .call(yAxis);

  svg.append('path')
    .attr('class', 'line')
    .attr('d', line(data))
    .style('fill', 'none')
    .style('stroke', '#333')
    .style('stroke-width', '2px');

  return _selector;
};

if(typeof Houston === 'undefined') {
  module.exports = graphLine;
} else {
  Houston.graphLine = graphLine;
}
