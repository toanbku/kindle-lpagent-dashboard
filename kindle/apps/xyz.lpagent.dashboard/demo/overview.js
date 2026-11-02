// Fake data for ?demo=1. Shape follows GET /lp-positions/overview (one row per protocol).
LPRAW.overview = { status: 'success', data: [
  { protocol: 'uniswap_v4', updated_at: LPRAW._ago(0.4),
    total_pnl: { '7D': 18.2, '1M': 44.9, 'ALL': 101.3 }, total_fee: { '7D': 22.6, '1M': 63.1 },
    closed_lp: { '1M': 23 }, win_rate: { '1M': 0.74 } },
  { protocol: 'uniswap_v3', updated_at: LPRAW._ago(0.4),
    total_pnl: { '7D': 6.4, '1M': 16.4, 'ALL': 41.5 }, total_fee: { '7D': 8.6, '1M': 25.3 },
    closed_lp: { '1M': 9 }, win_rate: { '1M': 0.67 } }
] };
