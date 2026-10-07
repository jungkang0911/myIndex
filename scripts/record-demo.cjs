const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { freezeClock, setClockText } = require('./demo-clock.cjs');
(async () => {
 const root = path.resolve(__dirname, '..');
 const frames = process.argv[3];
 fs.mkdirSync(frames, {recursive:true});
 const browser = await chromium.launch({headless:true});
 for (const kind of ['drag','import']) {
  const page = await browser.newPage({viewport:{width:1152,height:650}, deviceScaleFactor:1});
  await freezeClock(page);
  await page.goto(pathToFileURL(path.resolve(process.argv[2])).href);
  await setClockText(page);
  await page.evaluate(() => {
   const pointer=document.createElement('div');pointer.id='demo-pointer';pointer.style.cssText='position:fixed;width:18px;height:18px;border:3px solid #2563eb;background:#bfdbfe;border-radius:50%;z-index:9999;pointer-events:none;left:10px;top:10px;';document.body.append(pointer);
   document.addEventListener('mousemove',e=>{pointer.style.left=e.clientX+'px';pointer.style.top=e.clientY+'px';});
  });
  let n=0;
  async function shot(label) {
   await page.evaluate(label=>{let banner=document.querySelector('#demo-label');if(!banner){banner=document.createElement('div');banner.id='demo-label';banner.style.cssText='position:fixed;bottom:16px;left:50%;transform:translateX(-50%);background:#1e3a8a;color:white;padding:10px 22px;border-radius:10px;z-index:9998;font:18px system-ui';document.body.append(banner);}banner.textContent=label;},label);
   await page.screenshot({path:path.join(frames,`${kind}-${String(n++).padStart(3,'0')}.png`)});
  }
  if(kind==='drag') {
   await page.locator('#btnEdit').click();
   const source=page.locator('[data-lid="github"]');const dest=page.locator('[data-lid="wiki"]');
   const a=await source.boundingBox(),b=await dest.boundingBox();
   await shot('編輯模式：把 GitHub 拖到閱讀清單');
   await page.mouse.move(a.x+12,a.y+a.height/2);await page.mouse.down();
   for(let i=1;i<=60;i++) {
    const t=i/60, eased=t*t*(3-2*t);
    const x=a.x+12+(b.x+80-a.x-12)*eased;
    const y=a.y+a.height/2+(b.y+b.height-3-a.y-a.height/2)*eased;
    await page.mouse.move(x,y);
    // Native HTML drag events suppress mousemove; keep the demo cursor in sync.
    await page.evaluate(({x,y})=>{const p=document.querySelector('#demo-pointer');p.style.left=x+'px';p.style.top=y+'px';},{x,y});
    await page.screenshot({path:path.join(frames,`drag-${String(n++).padStart(3,'0')}.png`)});
   }
   await page.mouse.up();
   if(await page.locator('[data-lid="github"]').getAttribute('data-wid')!=='reading')throw Error('Real drag failed');
   await page.locator('#btnDone').click();for(let i=0;i<8;i++)await shot('完成：GitHub 已移到閱讀清單');
  } else {
   await shot('匯入 JSON 片段：保留現有內容、加入新連結');
   await page.locator('#btnMenu').click();await shot('開啟匯入／匯出選單');
   for(let i=0;i<5;i++)await shot('選擇「匯入設定 (JSON)」');
   await page.locator('[data-mbtn="imp"]').click();
   page.on('dialog',d=>d.accept());
   await page.locator('#fileInput').setInputFiles({name:'add-links.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify({page:'首頁',widgets:[{title:'閱讀清單',links:[{name:'Node.js 文件',url:'https://nodejs.org/docs',icon:'📗'}]}]}))});
   await page.getByText('Node.js 文件',{exact:true}).waitFor();
   for(let i=0;i<12;i++)await shot('完成：Node.js 文件已加入閱讀清單');
  }
  await page.close();
 }
 await browser.close();console.log('Recorded real drag and import interactions.');
})().catch(e=>{console.error(e);process.exit(1)});
