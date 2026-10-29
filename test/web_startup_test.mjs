import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const startupSource = readFileSync(new URL('../web/startup.js', import.meta.url), 'utf8');
const bootstrapSource = readFileSync(new URL('../web/flutter_bootstrap.js', import.meta.url), 'utf8')
  .replace(/\{\{flutter_js\}\}|\{\{flutter_build_config\}\}/g, '');

function startupHarness() {
  const elements = new Map();
  for (const id of ['app-startup', 'startup-message', 'startup-retry', 'flutter-bootstrap']) {
    elements.set(id, {
      hidden: id === 'startup-retry',
      textContent: '',
      classes: new Set(),
      listeners: new Map(),
      addEventListener(event, callback) { this.listeners.set(event, callback); },
      classList: { add(value) { elements.get(id).classes.add(value); } },
    });
  }
  let slowStart;
  let timerCleared = false;
  let reloads = 0;
  const listeners = new Map();
  const window = {
    location: { reload() { reloads++; } },
    addEventListener(event, callback) { listeners.set(event, callback); },
  };
  const context = {
    window,
    document: { getElementById(id) { return elements.get(id); } },
    setTimeout(callback) { slowStart = callback; return 1; },
    clearTimeout() { timerCleared = true; },
  };
  vm.runInNewContext(startupSource, context);
  return {
    window,
    elements,
    listeners,
    slowStart: () => slowStart(),
    timerCleared: () => timerCleared,
    reloads: () => reloads,
  };
}

test('a delayed startup offers reload while leaving startup active', () => {
  const h = startupHarness();
  h.slowStart();
  assert.equal(h.elements.get('app-startup').hidden, false);
  assert.equal(h.elements.get('startup-retry').hidden, false);
  assert.match(h.elements.get('startup-message').textContent, /longer than usual/);
  h.elements.get('startup-retry').listeners.get('click')();
  assert.equal(h.reloads(), 1);
});

test('a missing bootstrap file presents a recoverable failure', () => {
  const h = startupHarness();
  h.elements.get('flutter-bootstrap').listeners.get('error')();
  assert.equal(h.elements.get('startup-retry').hidden, false);
  assert.equal(h.elements.get('app-startup').classes.has('startup-error'), true);
  assert.match(h.elements.get('startup-message').textContent, /could not start/);
  assert.equal(h.timerCleared(), true);
});

test('a late first frame dismisses the slow-start recovery screen', () => {
  const h = startupHarness();
  h.slowStart();
  h.listeners.get('flutter-first-frame')();
  assert.equal(h.elements.get('app-startup').hidden, true);
  assert.equal(h.timerCleared(), true);
});

test('errors or timers after startup cannot cover the running app', () => {
  const h = startupHarness();
  h.window.MovieTrackerStartup.ready();
  h.window.MovieTrackerStartup.fail();
  h.slowStart();
  assert.equal(h.elements.get('app-startup').hidden, true);
  assert.equal(h.elements.get('startup-retry').hidden, true);
});

test('a startup failure is not overwritten by later progress messages', () => {
  const h = startupHarness();
  h.window.MovieTrackerStartup.fail();
  h.window.MovieTrackerStartup.setStage('Opening your library');
  assert.match(h.elements.get('startup-message').textContent, /could not start/);
});

async function runBootstrap(failure) {
  const calls = [];
  const window = { MovieTrackerStartup: {
    setStage(message) { calls.push(['stage', message]); },
    ready() { calls.push(['ready']); },
    fail() { calls.push(['failure']); },
  } };
  if (failure === 'missing-startup') delete window.MovieTrackerStartup;
  await vm.runInNewContext(bootstrapSource, {
    window,
    document: { getElementById() { return { hidden: false }; } },
    console: { error() {} },
    _flutter: { loader: {
      async load({ onEntrypointLoaded }) {
        if (failure === 'load') throw Error('Entrypoint failed');
        await onEntrypointLoaded({
          async initializeEngine() {
            if (failure === 'engine') throw Error('Engine failed');
            return { async runApp() {
              if (failure === 'app') throw Error('App failed');
              calls.push(['run']);
            } };
          },
        });
      },
    } },
  });
  return calls;
}

test('Flutter initialization runs the app before marking startup ready', async () => {
  const calls = await runBootstrap();
  assert.deepEqual(calls.map(([kind]) => kind), ['stage', 'stage', 'run', 'ready']);
});

test('the app still starts if the optional loading-screen script is unavailable', async () => {
  const calls = await runBootstrap('missing-startup');
  assert.deepEqual(calls.map(([kind]) => kind), ['run']);
});

for (const stage of ['load', 'engine', 'app']) {
  test(`a Flutter ${stage} failure keeps recovery available`, async () => {
    const calls = await runBootstrap(stage);
    assert.equal(calls.filter(([kind]) => kind === 'failure').length, 1);
    assert.equal(calls.some(([kind]) => kind === 'ready'), false);
  });
}

test('startup and bootstrap scripts load in deterministic order', () => {
  const html = readFileSync(new URL('../web/index.html', import.meta.url), 'utf8');
  assert.ok(html.indexOf('src="startup.js" defer') < html.indexOf('src="flutter_bootstrap.js" defer'));
  assert.match(html, /id="flutter-bootstrap" src="flutter_bootstrap.js" defer/);
});
