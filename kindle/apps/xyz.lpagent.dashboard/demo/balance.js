// Fake data for ?demo=1. Shape follows GET /token/balance.
LPRAW.balance = { status: 'success', data: [
  { symbol: 'ETH', balance: 0.0215, balanceInUsd: 77.9, price: 3620 },
  { symbol: 'USDG', balance: 18.4, balanceInUsd: 18.4 },
  { symbol: 'HOOD', balance: 0.05, balanceInUsd: 6.1 },
  { symbol: 'WETH', balance: 0.0012, balanceInUsd: 4.35, price: 3620 },
  { symbol: 'TSLA', balance: 0.004, balanceInUsd: 0.99 },
  { symbol: 'NVDA', balance: 0.002, balanceInUsd: 0.36 }
] };
