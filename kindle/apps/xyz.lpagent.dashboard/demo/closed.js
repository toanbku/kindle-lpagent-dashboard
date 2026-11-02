// Fake data for ?demo=1. Shape follows GET /lp-positions/historical.
(function () {
  var t = [['HOOD/USDG', 3, 2.41, 4.1], ['TSLA/WETH', 7, 5.08, 9.6], ['NVDA/USDG', 11, -0.92, -2.3],
           ['WETH/USDG', 16, 1.37, 2.2], ['AAPL/USDG', 22, 0.64, 1.9], ['HOOD/WETH', 27, 3.9, 7.4],
           ['AMZN/USDG', 33, -1.75, -4.1], ['TSLA/USDG', 40, 6.22, 8.8], ['META/USDG', 46, 0.38, 0.9],
           ['WETH/USDG', 52, 2.05, 3.1], ['NVDA/WETH', 61, 1.12, 2.6], ['HOOD/USDG', 70, -0.41, -1.2],
           ['COIN/USDG', 79, 4.47, 6.9], ['TSLA/USDG', 88, 2.93, 4.4], ['AAPL/WETH', 97, 0.21, 0.6],
           ['WETH/USDG', 108, 1.66, 2.5], ['MSFT/USDG', 119, -2.08, -5.2], ['HOOD/USDG', 130, 3.31, 5.7],
           ['NVDA/USDG', 142, 0.97, 2.0], ['TSLA/WETH', 155, 2.54, 3.8]];
  var rows = [];
  for (var i = 0; i < t.length; i++) rows.push({ pairName: t[i][0], closeAt: LPRAW._ago(t[i][1]), pnl: { value: t[i][2], percent: t[i][3] } });
  LPRAW.closed = { status: 'success', data: rows };
})();
