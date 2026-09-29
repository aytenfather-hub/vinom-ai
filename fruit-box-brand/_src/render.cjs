// Usage: node render.cjs <jobs.json>   jobs: [{src, out, w, h, scale, pdf?}]
const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const path = require('path'); const fs = require('fs');
(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  for (const j of jobs) {
    const ctx = await browser.newContext({ viewport: { width: j.w, height: j.h }, deviceScaleFactor: j.scale || 2 });
    const page = await ctx.newPage();
    await page.goto('file://' + path.resolve(j.src), { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(250);
    if (j.pdf) {
      await page.pdf({ path: j.out, width: j.pdfW || '297mm', height: j.pdfH || '210mm', printBackground: true, preferCSSPageSize: true });
    } else {
      await page.screenshot(j.full ? { path: j.out, fullPage: true } : { path: j.out, omitBackground: !!j.transparent, clip: { x: 0, y: 0, width: j.w, height: j.h } });
    }
    console.log('ok', j.out); await ctx.close();
  }
  await browser.close();
})();
