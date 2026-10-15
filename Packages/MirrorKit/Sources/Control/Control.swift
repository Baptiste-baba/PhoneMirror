// Control module — intentionally empty for v0.1.
//
// Starting with v0.2, this module will drive WebDriverAgent running on the
// iPhone through its HTTP API, over a USB tunnel (port 8100), to turn Mac
// input into iPhone gestures: click → tap, drag → swipe, scroll → scroll,
// keyboard → text input, and shortcuts for Home, App Switcher and Lock.
//
// It must not depend on the Video module: the app wires the two together.
