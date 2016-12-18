if(typeof Houston === 'undefined') {
  var d3 = require('d3');
}

function getTickFormat(report) {
  switch (report.units) {
    case "%": return function(n) { return d3.format(report.format || ".1f")(n) + "%"; };
    case "ms": return function(n) { return d3.format(report.format || "f")(n) + "ms"; };
    default: return d3.format(report.format || ",f");
  }
};

if(typeof Houston === 'undefined') {
  module.exports = getTickFormat;
} else {
  Houston.getTickFormat = getTickFormat;
}
