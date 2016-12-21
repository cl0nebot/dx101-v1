$(function() {
  // split the data set into ohlc and volume
  var chartScript = $('#chart_data'),
      quantityCurrency = chartScript.attr('quantity_currency'),
      rateCurrency = chartScript.attr('rate_currency'),
      data = JSON.parse(chartScript.html()),
      chart = $('#chart'),
      ohlc = [],
      volume = [],
      dataLength = data.length;

  for (i = 0; i < dataLength; i++) {
    ohlc.push([
              data[i][0], // the date
              data[i][1], // open
              data[i][2], // high
              data[i][3], // low
              data[i][4] // close
    ]);

    volume.push([
                data[i][0], // the date
                data[i][5] // the volume
    ])
  }

  // set the allowed units for data grouping
  var groupingUnits = [[
    'minute',                         // unit name
    [1,2,5,10,15,30]                             // allowed multiples
  ]];

  // create the chart
  chart.highcharts('StockChart', {

    chart: {
      height: 370
    },

    credits: {
      enabled: !1
    },

    rangeSelector: {
      inputEnabled: chart.width() > 480,
      selected: 1
    },

    colors: [
     '#084165', 
     '#BFD8E7', 
     '#8bbc21', 
     '#910000', 
     '#1aadce', 
     '#492970',
     '#f28f43', 
     '#77a1e5', 
     '#c42525', 
     '#a6c96a'
    ],

    title: {
      text: ''
    },

    yAxis: [{
      title: {
        text: 'OHLC'
      },
      height: 160,
      lineWidth: 2
    }, {
      title: {
        text: 'Volume'
      },
      top: 218,
      height: 60,
      offset: 0,
      lineWidth: 2
    }],

    rangeSelector: {
      inputEnabled: !1
    },

    series: [{
      type: 'candlestick',
      name: quantityCurrency + '/' + rateCurrency,
      data: ohlc,
      dataGrouping: {
        units: groupingUnits
      }
    }, {
      type: 'column',
      name: 'Volume',
      data: volume,
      yAxis: 1,
      dataGrouping: {
        units: groupingUnits
      }
    }]
  });
});
