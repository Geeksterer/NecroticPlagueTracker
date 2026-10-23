# Necrotic Plague Tracker v1.0 (8-Group Roster Grid Edition)

**Necrotic Plague Tracker** is a lightweight, high-performance raiding addon built specifically for **World of Warcraft: Wrath of the Lich King (3.3.5a)** on legacy clients. It tracks Necrotic Plague debuff carriers during the Icecrown Citadel (ICC) The Lich King encounter across an 8-group raid grid layout.

* **Author:** Copper
* **Version:** 1.0
* **Interface:** 30300 (WotLK 3.3.5a)

## Installation Guide

### Option 1: Downloading direct from GitHub (Green Code Button)

1. Near the top of this repository page, click the green **`< Code >`** button.
2. Select **Download ZIP** from the drop-down menu.
3. Extract the downloaded `.zip` archive on your computer.
4. Rename the extracted folder to **`NecroticPlagueTracker`** (ensure there are no subfolders like `NecroticPlagueTracker-main`).
5. Move the `NecroticPlagueTracker` folder into your World of Warcraft directory:
   `World of Warcraft\Interface\AddOns\`

### Option 2: Downloading from Releases

1. Go to the **Releases** tab on the right side of the GitHub repository page.
2. Select the desired release version (e.g., `v1.0`).
3. Under **Assets**, click on `NecroticPlagueTracker.zip` to download it.
4. Extract the folder into your `World of Warcraft\Interface\AddOns\` directory.

---

## First-Time Configuration Guide

When loading into the game for the first time:

1. **Open Configuration Panel:**
   * Click the **Necrotic Plague Tracker** icon on your Minimap, or type `/npt` in chat.
2. **Enable Test Mode:**
   * In the configuration window, check the **Enable Test Mode** box. This displays the 8-group background grid and simulates active carriers on your unit frames so you can see how the tracker looks in action.
3. **Unlock and Position:**
   * **Uncheck** the **Lock Frame Anchor** option to reveal the top title anchor bar.
   * Click and drag the title header bar (**"Necrotic Plague Tracker"**) to move the grid to your desired screen position (e.g., directly over or adjacent to your main raid frames).
4. **Lock & Save:**
   * Once positioned, **check** **Lock Frame Anchor** again to lock the anchor bar in place.
   * **Uncheck** **Enable Test Mode** to return the addon to standby mode. Click **Done** or close the panel.

---

## Features

* **8-Group Roster Grid Alignment:** Matches standard raid unit frames across an 8-column by 5-row grid layout to provide instant visual context on carrier positioning.
* **Smart Zone & Debuff Detection:** Automatically activates only within The Frozen Throne subzone or while Test Mode is enabled. Strictly filters for Disease-type Necrotic Plague debuffs (Spell IDs: 70337, 70338, 73780, 73912) to prevent false alerts from Infest or other debuffs.
* **Carrier Highlighting & Class Coloring:** Highlights the single active carrier with their respective class color, exact short name (3 characters), dynamic countdown timer, and a pulsing red warning border.
* **Audio Warning Alert:** Plays a distinct sound alert (`PVPFlagTaken.wav`) when the active carrier's Necrotic Plague duration drops to **3 seconds or less** (can be toggled in settings).
* **Click-to-Target Unit Integration:** Click any tile directly on the grid to target that player.
* **Interactive First-Time Welcome Screen:** Displays an introductory setup helper on initial load.
* **Configuration Panel & Minimap Button:** Includes a draggable minimap icon, slash commands (`/npt`), test mode preview, audio toggles, and frame anchor controls.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/npt` | Toggles the Necrotic Plague Tracker Configuration Panel |

---
