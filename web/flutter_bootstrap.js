{{flutter_js}}
{{flutter_build_config}}

// Use Flutter's supported initialization hooks; credentials and saved data are
// never involved in startup recovery.
(async function () {
  const startup = window.MovieTrackerStartup;
  try {
    await _flutter.loader.load({
      onEntrypointLoaded: async function (engineInitializer) {
        try {
          startup?.setStage('Preparing Movie Tracker…');
          const appRunner = await engineInitializer.initializeEngine();
          startup?.setStage('Opening your library…');
          await appRunner.runApp();
          if (startup) {
            startup.ready();
          } else {
            document.getElementById('app-startup').hidden = true;
          }
        } catch (error) {
          startup?.fail();
          console.error('Movie Tracker initialization failed.', error);
        }
      },
    });
  } catch (error) {
    startup?.fail();
    console.error('Movie Tracker could not load.', error);
  }
}());
