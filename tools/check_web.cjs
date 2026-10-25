// Exercise the actual release Web export, without credentials or game test hooks.
// Run against the local server documented in docs/publishing.md.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const { chromium } = require('playwright');

async function main() {
  const output = 'build/web-smoke';
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1152, height: 864 } });
  const errors = [];
  const logs = [];
  page.on('console', message => {
    const text = `${message.type()}: ${message.text()}`;
    logs.push(text);
    if (message.type() === 'error' || /SCRIPT ERROR:|CHECKS_FAILED/.test(text)) {
      errors.push(text);
    }
  });
  page.on('pageerror', error => errors.push(error.message));
  page.on('requestfailed', request => errors.push(`${request.url()}: ${request.failure()?.errorText}`));
  try {
    const response = await page.goto('http://127.0.0.1:8000', { timeout: 30000 });
    assert(response.ok(), 'Web export must be served successfully');
    // Godot removes the loading overlay only when startGame has succeeded.
    await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 60000 });
    await page.locator('#canvas').focus();
    await page.waitForTimeout(1500);
    await page.screenshot({ path: `${output}/01-menu.png` });

    await page.keyboard.press('Enter');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: `${output}/02-solo-shop.png` });
    await page.keyboard.down('a');
    await page.waitForTimeout(400);
    await page.keyboard.up('a');
    await page.keyboard.press('r');
    await page.waitForTimeout(500);
    await page.screenshot({ path: `${output}/03-recipes.png` });
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: `${output}/04-return-menu.png` });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1500);
    await page.screenshot({ path: `${output}/05-restart-solo.png` });

    // This existing game receipt confirms both input-driven scene transitions.
    const launches = logs.filter(line => line.includes('POTIONSHOP_CLIENT_JOINED')).length;
    assert.equal(launches, 2, 'Solo must start, return to the menu, and start again');
    assert.deepEqual(errors, [], 'Browser, network, or Godot runtime errors occurred');
    console.log('PASS: Web startup and repeated solo input smoke (screenshots saved for visual review)');
  } finally {
    await fs.writeFile(`${output}/console.log`, [...logs, ...errors].join('\n'));
    await browser.close();
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
