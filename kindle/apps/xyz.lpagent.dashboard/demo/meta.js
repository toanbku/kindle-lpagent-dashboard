// Fake data for ?demo=1 (screenshots, layout work). Not a real wallet.
window.LPRAW = window.LPRAW || {};
LPRAW.meta = {
  fetchedAt: Math.round(new Date().getTime() / 1000) - 75, ok: 4, total: 4,
  chain: 'ROBINHOOD', owner: '0x000000000000000000000000000000000000dEaD',
  interval: 300, tz: -new Date().getTimezoneOffset()
};
LPRAW._ago = function (hours) { return new Date(new Date().getTime() - hours * 3600000).toISOString(); };
