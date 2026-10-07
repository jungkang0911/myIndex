// Documentation-only clock. Install BEFORE navigation so the original interval
// cannot keep updating a screenshot after its text has been replaced.
const instant = new Date('2026-12-31T23:59:00+08:00');
exports.freezeClock = async page => {
  await page.clock.install({ time: instant });
  await page.clock.pauseAt(instant);
};
exports.setClockText = async page => {
  await page.evaluate(() => {
    document.querySelector('#clock').textContent = '23:59';
    document.querySelector('#date').textContent = '12/31';
  });
};
