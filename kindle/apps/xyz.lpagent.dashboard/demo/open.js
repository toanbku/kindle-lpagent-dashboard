// Fake data for ?demo=1. Shape follows GET /lp-positions/opening.
LPRAW.open = { status: 'success', data: [
  { pairName: 'TSLA/USDG', protocol: 'uniswap_v4', createdAt: LPRAW._ago(38), currentValue: 84.2, valueNative: 0.023260,
    pnl: { value: 9.85, percent: 13.2, valueNative: 0.002721 }, unCollectedFee: 1.42, unCollectedFeeNative: 0.000392, collectedFee: 6.1, inRange: true, priceRange: [238.1, 262.4, 247.9] },
  { pairName: 'WETH/USDG', protocol: 'uniswap_v4', createdAt: LPRAW._ago(5), currentValue: 61.1, valueNative: 0.016878,
    pnl: { value: 1.04, percent: 1.7, valueNative: 0.000287 }, unCollectedFee: 0.51, unCollectedFeeNative: 0.000141, collectedFee: 0.22, inRange: true, priceRange: [3520, 3690, 3611] },
  { pairName: 'HOOD/WETH', protocol: 'uniswap_v3', createdAt: LPRAW._ago(9), currentValue: 52.75, valueNative: 0.014572,
    pnl: { value: 3.12, percent: 6.3, valueNative: 0.000862 }, unCollectedFee: 0.88, unCollectedFeeNative: 0.000243, collectedFee: 1.95, inRange: true, priceRange: [0.0298, 0.0331, 0.0322] },
  { pairName: 'NVDA/USDG', protocol: 'uniswap_v4', createdAt: LPRAW._ago(58), currentValue: 38.4, valueNative: 0.010608,
    pnl: { value: -1.26, percent: -3.2, valueNative: -0.000348 }, unCollectedFee: 0.35, unCollectedFeeNative: 0.000097, collectedFee: 2.4, inRange: false, priceRange: [176.5, 184.2, 186.9] }
] };
