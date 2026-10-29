(function () {
  'use strict';

  const screen = document.getElementById('app-startup');
  const message = document.getElementById('startup-message');
  const retry = document.getElementById('startup-retry');
  let complete = false;
  let failed = false;

  function setStage(text) {
    if (!complete && !failed) message.textContent = text;
  }

  function showFailure() {
    if (complete) return;
    failed = true;
    clearTimeout(slowStartTimer);
    screen.classList.add('startup-error');
    message.textContent = 'Movie Tracker could not start. Check your connection and reload to try again.';
    retry.hidden = false;
  }

  const slowStartTimer = setTimeout(function () {
    if (complete || failed) return;
    message.textContent = 'Loading is taking longer than usual. You can keep waiting or reload to try again.';
    retry.hidden = false;
  }, 30000);

  retry.addEventListener('click', function () {
    window.location.reload();
  });

  window.MovieTrackerStartup = {
    setStage: setStage,
    fail: showFailure,
    ready: function () {
      if (complete) return;
      complete = true;
      clearTimeout(slowStartTimer);
      screen.hidden = true;
    },
  };

  window.addEventListener('flutter-first-frame', function () {
    window.MovieTrackerStartup.ready();
  }, { once: true });

  // A missing bootstrap file cannot reach the Flutter initialization hooks.
  document.getElementById('flutter-bootstrap').addEventListener('error', showFailure);
}());
