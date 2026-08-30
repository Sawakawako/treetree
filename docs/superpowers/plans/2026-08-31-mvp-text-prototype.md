# 世界树 MVP 文字原型 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭起《世界树》最小可玩文字原型：玩家扮演一棵树，点击舒展叶片收集日光，经光合转化为树液，购买斐波那契成本的升级（叶序螺旋/分枝序）实现自动采集，树液累积为树高（生长），并带 localStorage 自动存档。

**Architecture:** 纯前端 ES modules 分层：`state.js`（游戏状态）、`costs.js`（斐波那契成本）、`actions.js`（玩家动作）、`loop.js`（每 tick 资源计算）、`format.js`（数字格式化）、`render.js`（DOM 渲染）、`main.js`（入口：定时器/事件/存档）。所有计算逻辑为纯函数，可在 Node `node:test` 下直接测试；浏览器层仅做渲染与事件转发。

**Tech Stack:** 原生 HTML/CSS/JS（ES modules，零依赖）；Node ≥ 18 内置 `node:test` 跑测试；`server.mjs` 用 Node 内置 `http` 做静态文件服务器。

**Spec:** `docs/superpowers/specs/2026-08-31-world-tree-design.md`（本计划实现其 §4 双轨资源中的具象轨 MVP 部分 + §9 斐波那契升级组中的叶序螺旋/分枝序）

## Global Constraints

- 零第三方依赖：不得引入任何 npm 包（Node 内置模块除外）。
- 全部代码文件使用 ES modules（`export`/`import`），`package.json` 设 `"type": "module"`。
- 所有计算逻辑放 `src/` 纯函数模块，DOM 操作只允许出现在 `src/render.js` 与 `src/main.js`。
- 每个 `src/` 模块必须有对应 `test/` 测试文件，`npm test` 全绿才算任务完成。
- 升级成本按斐波那契数列：`fib(1)=1, fib(2)=1, fib(3)=2, ..., fib(34)=5702887`（F₁=F₂=1）。
- 数值规则（MVP 定稿，不得自行调整）：
  - 点击「舒展叶片」：`daylight += 1 × (1 + 0.25 × leafLevel)`
  - 每 tick 自动采集：`daylight += branchLevel × (1 + 0.25 × leafLevel)`
  - 每 tick 光合：`sap += daylight × 0.1`（日光不因转化而消耗）
  - 每 tick 生长：`growth += sap × 0.01`
  - 叶序螺旋（level 从 0 计，升到 level+1 的花费）：`500 × fib(level + 1)`
  - 分枝序：`1200 × fib(level + 1)`
- 开局状态：`daylight=0, sap=0, growth=0, leafLevel=0, branchLevel=0, tick=0, hope=1`（`hope` 为叙事元素，MVP 不消费，只显示）。
- 存档：localStorage 键 `world-tree-save`，每 60 tick 自动保存一次，页面加载时读取。
- 命名与文案：游戏内文案简体中文；界面元素 id 用 camelCase。

---

### Task 1: 项目脚手架与静态服务器

**Files:**
- Create: `package.json`
- Create: `server.mjs`
- Create: `index.html`
- Create: `style.css`

**Interfaces:**
- Consumes: 无（第一个任务）
- Produces: `npm test` 运行 `node --test test/`；`npm run serve` 启动静态服务器（端口 8000）；`index.html` 引入 `<script type="module" src="src/main.js">`

- [ ] **Step 1: 创建 package.json**

```json
{
  "name": "world-tree",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test test/",
    "serve": "node server.mjs"
  }
}
```

- [ ] **Step 2: 创建 server.mjs（静态文件服务器）**

```js
import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const ROOT = new URL('.', import.meta.url).pathname;
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json' };

const server = http.createServer(async (req, res) => {
  try {
    const urlPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const filePath = normalize(join(ROOT, urlPath === '/' ? 'index.html' : urlPath));
    if (!filePath.startsWith(ROOT)) { res.writeHead(403); res.end('Forbidden'); return; }
    const body = await readFile(filePath);
    res.writeHead(200, { 'Content-Type': MIME[extname(filePath)] ?? 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404); res.end('Not Found');
  }
});

server.listen(8000, () => console.log('世界树原型: http://localhost:8000'));
```

- [ ] **Step 3: 创建 index.html（骨架）**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>世界树</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div id="game">
    <h1>世界树</h1>
    <p id="hope-line" class="hope">一点希望，在废墟中静静燃烧。</p>
    <button id="gather-btn">舒展叶片</button>
    <div id="resources">
      <p>日光：<span id="daylight-display">0</span></p>
      <p>树液：<span id="sap-display">0</span></p>
      <p>树高：<span id="growth-display">0</span></p>
    </div>
    <div id="upgrades">
      <button id="leaf-upgrade">叶序螺旋（日光采集 +25%/级）—— 价格：<span id="leaf-cost">500</span></button>
      <button id="branch-upgrade">分枝序（自动采集 +1/级）—— 价格：<span id="branch-cost">1200</span></button>
    </div>
    <p id="log-line"></p>
  </div>
  <script type="module" src="src/main.js"></script>
</body>
</html>
```

- [ ] **Step 4: 创建 style.css（极简）**

```css
body { font-family: "Microsoft YaHei", sans-serif; background: #1a1512; color: #d8cfc0; max-width: 40rem; margin: 2rem auto; padding: 0 1rem; }
button { display: block; margin: 0.5rem 0; padding: 0.6rem 1rem; background: #3a2f24; color: #e8dcc8; border: 1px solid #6b5638; cursor: pointer; }
button:hover { background: #4d3f2e; }
.hope { color: #b89a5a; font-style: italic; }
#resources p { margin: 0.25rem 0; }
```

- [ ] **Step 5: 验证服务器可用**

Run: `npm run serve`（后台启动），浏览器打开 `http://localhost:8000`
Expected: 页面显示"世界树"标题与各元素，无控制台报错（src/main.js 尚不存在会有 404，属预期，Task 7 接入后消除）

- [ ] **Step 6: Commit**

```bash
git add package.json server.mjs index.html style.css
git commit -m "feat: 世界树 MVP 脚手架（静态服务器 + 页面骨架）"
```

---

### Task 2: 游戏状态模块 state.js

**Files:**
- Create: `src/state.js`
- Test: `test/state.test.js`

**Interfaces:**
- Produces: `createInitialState()` → `{ daylight, sap, growth, leafLevel, branchLevel, tick, hope }`（全为 number）；`serializeState(state)` → string；`deserializeState(json)` → state 对象（字段缺失时回退初始值）

- [ ] **Step 1: 写失败测试**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createInitialState, serializeState, deserializeState } from '../src/state.js';

test('createInitialState 返回规范初始值', () => {
  const s = createInitialState();
  assert.deepEqual(s, { daylight: 0, sap: 0, growth: 0, leafLevel: 0, branchLevel: 0, tick: 0, hope: 1 });
});

test('serializeState 与 deserializeState 往返一致', () => {
  const s = createInitialState();
  s.daylight = 42; s.leafLevel = 3;
  const back = deserializeState(serializeState(s));
  assert.equal(back.daylight, 42);
  assert.equal(back.leafLevel, 3);
});

test('deserializeState 对缺失字段回退初始值', () => {
  const back = deserializeState('{"daylight":7}');
  assert.equal(back.daylight, 7);
  assert.equal(back.sap, 0);
  assert.equal(back.hope, 1);
});
```

- [ ] **Step 2: 运行确认失败**

Run: `node --test test/state.test.js`
Expected: FAIL，报 `Cannot find module '../src/state.js'`

- [ ] **Step 3: 实现 src/state.js**

```js
export function createInitialState() {
  return { daylight: 0, sap: 0, growth: 0, leafLevel: 0, branchLevel: 0, tick: 0, hope: 1 };
}

export function serializeState(state) {
  return JSON.stringify(state);
}

export function deserializeState(json) {
  const parsed = JSON.parse(json);
  const base = createInitialState();
  return { ...base, ...parsed };
}
```

- [ ] **Step 4: 运行确认通过**

Run: `node --test test/state.test.js`
Expected: PASS（3 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add src/state.js test/state.test.js
git commit -m "feat: 游戏状态模块（初始值/序列化）"
```

---

### Task 3: 斐波那契成本模块 costs.js

**Files:**
- Create: `src/costs.js`
- Test: `test/costs.test.js`

**Interfaces:**
- Consumes: 无（独立数学模块）
- Produces: `fib(n)` → number（F₁=F₂=1，`fib(1)=1, fib(2)=1, fib(34)=5702887`）；`leafCost(level)` → number（升到 level+1 级花费）；`branchCost(level)` → number

- [ ] **Step 1: 写失败测试**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fib, leafCost, branchCost } from '../src/costs.js';

test('fib 前几项', () => {
  assert.equal(fib(1), 1);
  assert.equal(fib(2), 1);
  assert.equal(fib(3), 2);
  assert.equal(fib(4), 3);
  assert.equal(fib(5), 5);
  assert.equal(fib(6), 8);
});

test('fib(34) 等于 5702887（伦纳德之律彩蛋数字）', () => {
  assert.equal(fib(34), 5702887);
});

test('叶序螺旋成本：500×F(n)', () => {
  assert.equal(leafCost(0), 500);      // 500×fib(1)
  assert.equal(leafCost(1), 500);      // 500×fib(2)
  assert.equal(leafCost(2), 1000);     // 500×fib(3)
  assert.equal(leafCost(3), 1500);     // 500×fib(4)
});

test('分枝序成本：1200×F(n)', () => {
  assert.equal(branchCost(0), 1200);
  assert.equal(branchCost(1), 1200);
  assert.equal(branchCost(2), 2400);
});
```

- [ ] **Step 2: 运行确认失败**

Run: `node --test test/costs.test.js`
Expected: FAIL，报 `Cannot find module '../src/costs.js'`

- [ ] **Step 3: 实现 src/costs.js**

```js
export function fib(n) {
  if (n <= 0) return 0;
  if (n <= 2) return 1;
  let a = 1, b = 1;
  for (let i = 3; i <= n; i++) { const t = a + b; a = b; b = t; }
  return b;
}

export function leafCost(level) {
  return 500 * fib(level + 1);
}

export function branchCost(level) {
  return 1200 * fib(level + 1);
}
```

- [ ] **Step 4: 运行确认通过**

Run: `node --test test/costs.test.js`
Expected: PASS（4 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add src/costs.js test/costs.test.js
git commit -m "feat: 斐波那契成本模块（fib/叶序螺旋/分枝序）"
```

---

### Task 4: 数字格式化模块 format.js

**Files:**
- Create: `src/format.js`
- Test: `test/format.test.js`

**Interfaces:**
- Produces: `formatNumber(n)` → string（千分位；≥1000 用 K/M/B/T 后缀，保留 2 位小数，尾零省略）；`formatCost(n)` → string（整数千分位，无小数）

- [ ] **Step 1: 写失败测试**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatNumber, formatCost } from '../src/format.js';

test('formatNumber 千分位与小数', () => {
  assert.equal(formatNumber(0), '0');
  assert.equal(formatNumber(12.5), '12.5');
  assert.equal(formatNumber(999), '999');
  assert.equal(formatNumber(1234.5), '1.23K');
  assert.equal(formatNumber(1234567), '1.23M');
  assert.equal(formatNumber(1234567890), '1.23B');
});

test('formatCost 整数千分位', () => {
  assert.equal(formatCost(500), '500');
  assert.equal(formatCost(5000), '5,000');
  assert.equal(formatCost(5702887), '5,702,887');
});
```

- [ ] **Step 2: 运行确认失败**

Run: `node --test test/format.test.js`
Expected: FAIL，报 `Cannot find module '../src/format.js'`

- [ ] **Step 3: 实现 src/format.js**

```js
const SUFFIX = ['', 'K', 'M', 'B', 'T'];

export function formatNumber(n) {
  if (!Number.isFinite(n)) return '0';
  if (Math.abs(n) < 1000) {
    const v = Math.floor(n * 100) / 100;
    return String(v);
  }
  const tier = Math.min(Math.floor(Math.log10(Math.abs(n)) / 3), SUFFIX.length - 1);
  const scaled = n / Math.pow(10, tier * 3);
  return `${scaled.toFixed(2).replace(/\.?0+$/, '')}${SUFFIX[tier]}`;
}

export function formatCost(n) {
  return Math.floor(n).toLocaleString('en-US');
}
```

- [ ] **Step 4: 运行确认通过**

Run: `node --test test/format.test.js`
Expected: PASS（2 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add src/format.js test/format.test.js
git commit -m "feat: 数字格式化模块（大数后缀/千分位）"
```

---

### Task 5: 玩家动作模块 actions.js

**Files:**
- Create: `src/actions.js`
- Test: `test/actions.test.js`

**Interfaces:**
- Consumes: `createInitialState()`（state.js）；`leafCost(level)`、`branchCost(level)`（costs.js）
- Produces: `gatherDaylight(state)` → void（原地改 state，日光 += 1×(1+0.25×leafLevel)）；`buyLeaf(state)` → boolean（够树液则扣款升 1 级返回 true，否则 false）；`buyBranch(state)` → boolean

- [ ] **Step 1: 写失败测试**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createInitialState } from '../src/state.js';
import { gatherDaylight, buyLeaf, buyBranch } from '../src/actions.js';

test('gatherDaylight 基础采集 +1', () => {
  const s = createInitialState();
  gatherDaylight(s);
  assert.equal(s.daylight, 1);
});

test('gatherDaylight 受叶序螺旋加成（+25%/级）', () => {
  const s = createInitialState();
  s.leafLevel = 2; // 1 + 0.25*2 = 1.5
  gatherDaylight(s);
  assert.equal(s.daylight, 1.5);
});

test('buyLeaf 够树液则升级并扣款', () => {
  const s = createInitialState();
  s.sap = 500;
  assert.equal(buyLeaf(s), true);
  assert.equal(s.leafLevel, 1);
  assert.equal(s.sap, 0);
});

test('buyLeaf 不够则返回 false 且不扣款', () => {
  const s = createInitialState();
  s.sap = 499;
  assert.equal(buyLeaf(s), false);
  assert.equal(s.leafLevel, 0);
  assert.equal(s.sap, 499);
});

test('buyBranch 类似逻辑，价格为 1200×F(n)', () => {
  const s = createInitialState();
  s.sap = 1200;
  assert.equal(buyBranch(s), true);
  assert.equal(s.branchLevel, 1);
  assert.equal(s.sap, 0);
});
```

- [ ] **Step 2: 运行确认失败**

Run: `node --test test/actions.test.js`
Expected: FAIL，报 `Cannot find module '../src/actions.js'`

- [ ] **Step 3: 实现 src/actions.js**

```js
import { leafCost, branchCost } from './costs.js';

export function gatherDaylight(state) {
  state.daylight += 1 * (1 + 0.25 * state.leafLevel);
}

export function buyLeaf(state) {
  const cost = leafCost(state.leafLevel);
  if (state.sap < cost) return false;
  state.sap -= cost;
  state.leafLevel += 1;
  return true;
}

export function buyBranch(state) {
  const cost = branchCost(state.branchLevel);
  if (state.sap < cost) return false;
  state.sap -= cost;
  state.branchLevel += 1;
  return true;
}
```

- [ ] **Step 4: 运行确认通过**

Run: `node --test test/actions.test.js`
Expected: PASS（5 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add src/actions.js test/actions.test.js
git commit -m "feat: 玩家动作模块（舒展叶片/购买升级）"
```

---

### Task 6: 游戏循环模块 loop.js

**Files:**
- Create: `src/loop.js`
- Test: `test/loop.test.js`

**Interfaces:**
- Consumes: `createInitialState()`（state.js）
- Produces: `tick(state)` → void（原地改：tick+1；自动采集 `daylight += branchLevel×(1+0.25×leafLevel)`；光合 `sap += daylight×0.1`；生长 `growth += sap×0.01`）

- [ ] **Step 1: 写失败测试**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createInitialState } from '../src/state.js';
import { tick } from '../src/loop.js';

test('tick 递增计时并光合', () => {
  const s = createInitialState();
  s.daylight = 100;
  tick(s);
  assert.equal(s.tick, 1);
  assert.equal(s.sap, 10);      // 100 × 0.1
  assert.equal(s.daylight, 100); // 无分支时日光不减
});

test('tick 自动采集：branchLevel 贡献日光', () => {
  const s = createInitialState();
  s.branchLevel = 3;
  s.daylight = 10;
  tick(s);
  assert.equal(s.daylight, 13);  // 10 + 3×1
});

test('tick 自动采集受叶序螺旋加成', () => {
  const s = createInitialState();
  s.branchLevel = 2;
  s.leafLevel = 2;               // 2 × 1.5 = 3
  s.daylight = 0;
  tick(s);
  assert.equal(s.daylight, 3);
});

test('tick 生长：sap × 0.01', () => {
  const s = createInitialState();
  s.sap = 200;
  tick(s);
  assert.equal(s.growth, 2);
});
```

- [ ] **Step 2: 运行确认失败**

Run: `node --test test/loop.test.js`
Expected: FAIL，报 `Cannot find module '../src/loop.js'`

- [ ] **Step 3: 实现 src/loop.js**

```js
export function tick(state) {
  state.tick += 1;
  const eff = 1 + 0.25 * state.leafLevel;
  state.daylight += state.branchLevel * eff;
  state.sap += state.daylight * 0.1;
  state.growth += state.sap * 0.01;
}
```

- [ ] **Step 4: 运行确认通过**

Run: `node --test test/loop.test.js`
Expected: PASS（4 个用例全绿）

- [ ] **Step 5: Commit**

```bash
git add src/loop.js test/loop.test.js
git commit -m "feat: 游戏循环模块（自动采集/光合/生长）"
```

---

### Task 7: 渲染与入口（render.js + main.js）

**Files:**
- Create: `src/render.js`
- Create: `src/main.js`
- Modify: `index.html`（无需改，id 已在 Task 1 定义好）

**Interfaces:**
- Consumes: `createInitialState/serializeState/deserializeState`（state.js）；`formatNumber/formatCost`（format.js）；`tick`（loop.js）；`gatherDaylight/buyLeaf/buyBranch`（actions.js）；`leafCost/branchCost`（costs.js）
- Produces: `render(state, els)` → void（刷新全部 DOM 文本；升级按钮 disabled 状态随树液是否足够；购买成功写入 `#log-line`）；`main.js` 挂载：1 秒 1 tick 定时器、事件绑定、每 60 tick 自动存档、加载时读档

- [ ] **Step 1: 写失败测试（render 为纯 DOM 操作无法在 node:test 断言，此任务测试聚焦 main 的存档节流纯函数）**

先在 `src/main.js` 导出纯函数 `shouldAutoSave(state)`（`state.tick % 60 === 0 && state.tick > 0`），测试它：

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createInitialState } from '../src/state.js';
import { shouldAutoSave } from '../src/main.js';

test('shouldAutoSave：每 60 tick 触发', () => {
  const s = createInitialState();
  s.tick = 60;
  assert.equal(shouldAutoSave(s), true);
  s.tick = 61;
  assert.equal(shouldAutoSave(s), false);
});
```

Run: `node --test test/main.test.js`
Expected: FAIL，报 `Cannot find module '../src/main.js'`

- [ ] **Step 2: 实现 src/render.js**

```js
import { formatNumber, formatCost } from './format.js';
import { leafCost, branchCost } from './costs.js';

export function render(state, els) {
  els.daylight.textContent = formatNumber(state.daylight);
  els.sap.textContent = formatNumber(state.sap);
  els.growth.textContent = formatNumber(state.growth);
  els.leafCost.textContent = formatCost(leafCost(state.leafLevel));
  els.branchCost.textContent = formatCost(branchCost(state.branchLevel));
  els.leafUpgrade.disabled = state.sap < leafCost(state.leafLevel);
  els.branchUpgrade.disabled = state.sap < branchCost(state.branchLevel);
}
```

- [ ] **Step 3: 实现 src/main.js**

```js
import { createInitialState, serializeState, deserializeState } from './state.js';
import { tick } from './loop.js';
import { gatherDaylight, buyLeaf, buyBranch } from './actions.js';
import { render } from './render.js';

const SAVE_KEY = 'world-tree-save';

export function shouldAutoSave(state) {
  return state.tick > 0 && state.tick % 60 === 0;
}

const els = {
  daylight: document.getElementById('daylight-display'),
  sap: document.getElementById('sap-display'),
  growth: document.getElementById('growth-display'),
  leafCost: document.getElementById('leaf-cost'),
  branchCost: document.getElementById('branch-cost'),
  leafUpgrade: document.getElementById('leaf-upgrade'),
  branchUpgrade: document.getElementById('branch-upgrade'),
  log: document.getElementById('log-line'),
};

function loadState() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    return raw ? deserializeState(raw) : createInitialState();
  } catch {
    return createInitialState();
  }
}

let state = loadState();

document.getElementById('gather-btn').addEventListener('click', () => {
  gatherDaylight(state);
  render(state, els);
});

els.leafUpgrade.addEventListener('click', () => {
  if (buyLeaf(state)) els.log.textContent = `叶序螺旋升至 ${state.leafLevel} 级。`;
  render(state, els);
});

els.branchUpgrade.addEventListener('click', () => {
  if (buyBranch(state)) els.log.textContent = `分枝序升至 ${state.branchLevel} 级。`;
  render(state, els);
});

setInterval(() => {
  tick(state);
  if (shouldAutoSave(state)) {
    localStorage.setItem(SAVE_KEY, serializeState(state));
    els.log.textContent = '树记下了自己。';
  }
  render(state, els);
}, 1000);

render(state, els);
```

- [ ] **Step 4: 运行确认测试通过**

Run: `node --test test/main.test.js`
Expected: PASS（shouldAutoSave 用例全绿）
注：main.js 顶层引用 `document`/`localStorage`，node:test 下 import 会报错——若出现 `document is not defined`，将 `shouldAutoSave` 相关逻辑保持在纯函数层，且确保 main.js 的 DOM 代码在模块顶层之外不执行（本实现中 DOM 访问在顶层，Node 下 import 即报错）。解决办法：把 `shouldAutoSave` 移到 `src/loop.js` 并同步修改 Task 6 的 `loop.test.js` 添加对应用例；`main.js` 从 loop.js 导入它。采用此方案（见下）。

- [ ] **Step 4b: 把 shouldAutoSave 放入 loop.js（避免 Node 下 import main.js 触发 DOM）**

修改 `src/loop.js`，追加：

```js
export function shouldAutoSave(state) {
  return state.tick > 0 && state.tick % 60 === 0;
}
```

修改 `test/loop.test.js` 追加：

```js
test('shouldAutoSave：每 60 tick 触发', () => {
  const s = createInitialState();
  s.tick = 60;
  assert.equal(shouldAutoSave(s), true);
  s.tick = 61;
  assert.equal(shouldAutoSave(s), false);
});
```

（import 行改为 `import { tick, shouldAutoSave } from '../src/loop.js';`）

同步修改 `src/main.js`：删除本地 `shouldAutoSave` 定义，改 `import { tick, shouldAutoSave } from './loop.js';`，删掉 `test/main.test.js`（不再需要）。

- [ ] **Step 5: 运行确认全部测试通过**

Run: `npm test`
Expected: PASS（state/costs/format/actions/loop 全部用例，含 shouldAutoSave）

- [ ] **Step 6: 浏览器集成验证**

Run: `npm run serve`，浏览器打开 `http://localhost:8000`
Expected:
- 点击「舒展叶片」日光 +1
- 树液随日光累积（光合）
- 攒够 500 树液后可买「叶序螺旋」，价格跳为 500（F₂），再跳 1000（F₃）
- 攒够 1200 树液后可买「分枝序」，日光开始每 tick 自动 +1
- 60 秒后日志出现"树记下了自己"；刷新页面数值保留

- [ ] **Step 7: Commit**

```bash
git add src/render.js src/main.js src/loop.js test/loop.test.js
git commit -m "feat: 渲染与入口（DOM 刷新/定时器/自动存档）"
```

---

### Task 8: 集成收尾与手测清单

**Files:**
- Modify: 无（纯验证）

**Interfaces:**
- Consumes: 全部前序任务产物

- [ ] **Step 1: 全量测试**

Run: `npm test`
Expected: 全部 PASS

- [ ] **Step 2: 手动玩法验证（对照 Global Constraints 数值规则）**

在浏览器依次验证：
- [ ] 开局显示"一点希望，在废墟中静静燃烧"（hope 叙事元素）
- [ ] 点击 5 次「舒展叶片」→ 日光 = 5
- [ ] 等待树液 ≥ 500 → 购买「叶序螺旋」→ 点击采集变为 +1.25
- [ ] 购买第 2 级叶序螺旋（500）→ 采集 +1.5
- [ ] 购买「分枝序」→ 每 tick 日光自动 +1
- [ ] 刷新页面后数值保留（自动存档生效）

- [ ] **Step 3: 最终提交**

```bash
git add -A
git commit -m "chore: MVP 验证通过"
```

---

## Self-Review 记录

- **Spec 覆盖**：§4 具象轨（日光/树液/生长）✓（loop/actions）；§9 斐波那契升级组前两项 ✓（costs/actions）；开局一点希望 ✓（state.hope + index.html 文案）；存档 ✓（main）。四族/梦境/明选/终局属后续里程碑，不在本计划范围，已留 spec §12 里程碑 2-4。
- **占位符扫描**：无 TBD/TODO；所有步骤含具体代码与命令。
- **类型一致性**：`createInitialState`/`tick`/`buyLeaf`/`fib`/`formatNumber` 等签名在测试与实现间一致；`shouldAutoSave` 经 Step 4b 迁入 loop.js 后，main.js 与 loop.test.js 引用一致；`leafCost/branchCost` 均以 level（从 0 计）入参。
