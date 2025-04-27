# Parallel Intervals Checker for MuseScore Studio 4

**Parallel Intervals Checker** is a MuseScore plugin that identifies and highlights parallel intervals such as **parallel fifths**, **octaves**, and **hidden parallels** within your music score. This tool is specifically designed to help composers and arrangers avoid the use of parallel intervals, which are often considered undesirable in traditional counterpoint. It marks consecutive **fifths**, **octaves**, and **hidden parallels** for easy visualization and correction.

---

## Features

- **Detect Parallel Fifths**  
  Identifies consecutive fifth intervals that are parallel between voices.

- **Detect Parallel Octaves**  
  Detects consecutive octaves that occur in parallel between voices.

- **Detect Hidden Parallels**  
  Identifies hidden parallels (either fifths or octaves) that occur between two notes in ascending order.

- **Coloring & Marking**  
  Automatically colors the notes and adds **staff text** annotations to mark the parallel intervals for easy identification and correction.

- **Customization**  
  The plugin allows users to choose:
  - Which intervals to detect (parallel fifths, octaves, or hidden intervals).
  - Whether to use **only coloring** or **coloring with text markings**.
  - Custom color settings for each interval type (fifths, octaves, hidden intervals).
  - **Dry run mode** (no markings are applied, just a check).
  - **Cleanup before run** to remove old markings from previous runs.

- **Compatibility**  
  Fully compatible with MuseScore Studio 4, with support for its latest versions.

---

## Installation

To install the **Parallel Intervals Checker** plugin:

1. Clone this repo: `git clone https://github.com/christianhofmanncodes/musescore-plugins.git .`
1. Open **MuseScore Studio**.
1. Identify your Plugins folder via `Settings > Folders > Plugins`.
1. Move the **whole** folder with its content to the **Plugins folder**
1. Open MuseScore Studio 4 and activate the plugin on the `Home` page under the tab `Plugins`

Once activated, the plugin will appear in the `Plugins` menu.

---

## Usage

1. **Open your score** in MuseScore.
2. Navigate to `Plugins > Composition and Arranging Tools > Parallel Intervals Checker`.
3. A settings dialog will appear where you can configure your preferences:
   - **Detection Settings**: Select which types of parallels you want to check for (fifths, octaves, hidden intervals).
   - **Marking Options**: Choose between coloring only the notes or also adding text markings. You can also enable **dry run mode** to see the results without making any permanent changes to your score.
   - **Color Settings**: Pick custom colors for each type of interval detection (parallel fifths, parallel octaves, hidden parallels).
   - **Reset to Defaults**: Option to reset colors to the default settings.

4. After configuring your preferences, click **OK** to run the plugin.

The plugin will then analyze the score and highlight any detected parallel intervals, either by coloring the notes or adding text annotations.

You can rerun the plugin any time. It will get rid of the annotations or colorings it made before.

---

## Available Settings

- **Detection Options**:
  - **Parallel Fifths**: Detects parallel fifth intervals.
  - **Parallel Octaves**: Detects parallel octaves.
  - **Hidden Fifths**: Detects hidden fifth intervals (ascending).
  - **Hidden Octaves**: Detects hidden octaves (ascending).

- **Marking Options**:
  - **Only color notes (no staff text)**: Colors the notes without adding text markings.
  - **Dry run (no markings)**: Performs a check without making any markings to the score.

- **Color Customization**:
  - **Fifths Color**: Customize the color used to mark parallel fifths.
  - **Octaves Color**: Customize the color used to mark parallel octaves.
  - **Hidden Parallels Color**: Customize the color used for hidden fifths and octaves.

---

## Functions

- **startCheck()**: The core function that begins the check for parallel intervals in the score.
- **initializeParallelCheckData()**: Initializes tracking data for checking intervals.
- **handleSegment()**: Handles each segment of the score to detect intervals.
- **checkFifths()**: Checks for parallel fifths or hidden fifths and marks them.
- **checkOctaves()**: Checks for parallel octaves or hidden octaves and marks them.
- **markColor()**: Applies color to the notes to highlight detected parallels.
- **markText()**: Adds staff text annotations to the score for detected parallels.

---

## Known Issues

- **Multiple Notes per Voice**: The plugin currently only uses the top note of a chord when detecting intervals, and multiple notes in a chord may be skipped.

---

## Contributing

If you have suggestions, improvements, or bug fixes for the plugin, feel free to open an issue or submit a pull request.

---

## License

This plugin is licensed under the [GNU GENERAL PUBLIC LICENSE](../LICENSE).

---

## Acknowledgments

This plugin was created for MuseScore Studio 4 and is designed to help musicians and arrangers avoid parallel intervals in their compositions. Special thanks to the MuseScore community for providing the necessary tools and API for plugin development.

[Inspired by the checkParallels plugin by heuchi](https://github.com/heuchi/checkParallels)
