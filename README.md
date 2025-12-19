# Weevil

A comprehensive World of Warcraft Retail addon that combines extensive automation features (inspired by Leatrix Plus) with a powerful information display bar (inspired by Titan Panel).

## 🎮 Features Overview

### 🤖 Automation Module (25+ Features)

**Quest Automation:**
- Auto Accept Quests - Automatically accept quests from NPCs
- Auto Turn-in Quests - Automatically complete quests
- Auto Gossip - Skip NPC dialogue automatically

**Merchant Automation:**
- Auto Repair - Automatically repair gear at vendors
- Guild Repair - Use guild bank funds for repairs
- Auto Sell Junk - Automatically sell gray items
- Auto Sell Grey - Sell all grey quality items

**Loot Automation:**
- Faster Looting - Instant loot delay (0ms)
- Enhanced Auto Loot - Improved auto loot speed
- Auto Greed Greens - Automatically greed on uncommon items
- Auto Greed Blues - Automatically greed on rare items

**Social Automation:**
- Auto Accept Resurrect - Accept resurrection requests automatically
- Auto Accept Summon - Accept warlock summons automatically
- Auto Invite - Auto invite from whispers (configurable keyword)
- Auto Decline Duels - Automatically decline duel requests
- Auto Decline Party - Automatically decline party invites

**Combat Automation:**
- Auto Release in BGs - Automatically release spirit in battlegrounds
- Auto Skinning - Automatic skinning of corpses

**UI Automation:**
- Auto Skip Cutscenes - Skip cinematics and movies automatically
- Hide Zone Text - Hide zone change announcements
- Hide Boss Emotes - Hide boss emote frame
- Hide Error Messages - Hide the red error text frame
- Auto Confirm Bind - Auto confirm bind on equip
- Auto Confirm Disenchant - Auto confirm disenchant

**Miscellaneous:**
- Fast Waypoints - Faster waypoint calculation
- Dismount in Water - Automatically dismount when entering water
- Auto Equipment Compare - Always show equipment comparisons
- Auto Accept Party Sync - Automatically accept party sync requests

### 📊 Info Bar Module (25+ Displays)

**Performance Displays:**
- FPS Display - Current frames per second (color-coded: green/yellow/red)
- Latency Display - Home and world latency in ms (color-coded)
- Memory Usage - Addon memory consumption

**Character Displays:**
- Bag Space - Free bag slots / total slots (color-coded)
- Durability - Average item durability percentage (color-coded)
- XP Progress - Experience bar with percentage (rested XP indicator)
- Reputation - Watched faction reputation progress
- Item Level - Average equipped item level
- Talent Spec - Current specialization name
- Movement Speed - Player movement speed percentage

**Currency Displays:**
- Gold - Current character gold with icon
- Realm Gold - Total gold across all characters
- Currencies - Tracked currency displays

**Location Displays:**
- Location - Current zone and subzone
- Coordinates - Player X, Y coordinates
- Zone Level - Zone level range information

**Time Displays:**
- Game Time - Server/realm time
- Local Time - Your local computer time
- 24-Hour Format - Toggle between 12h/24h format

**Social Displays:**
- Friends Online - Number of online friends (Battle.net + regular)
- Guild Online - Number of online guild members
- Mail Indicator - New mail notification

**Instance Displays:**
- Instance Difficulty - Current dungeon/raid difficulty (N/H/M)
- Saved Instances - Instance lockout information
- Quest Log - Current quest count / maximum quests

**Tracking Displays:**
- Tracking - Current tracking type
- Quest Tracking - Active quest objectives

### 🎨 Custom Beautiful UI

The addon features a completely custom, professionally designed interface:

- **Modern Gradient Design** - Sleek backgrounds with themed accent colors
- **Category Navigation** - Beautiful icon-based navigation:
  - 🔧 Automation (Green theme)
  - 📊 Info Bar (Blue theme)  
  - 🎨 UI Tweaks (Orange theme)
  - 📁 Profiles (Purple theme)
- **Scrollable Content** - Smooth scrolling panels for all options
- **Section Organization** - Logically grouped settings
- **Professional Tooltips** - Helpful descriptions on hover
- **No Generic UI** - Custom design, not basic AceConfig

### 🖼️ UI Module

- Enhanced Tooltips - Show item level and spell IDs
- Screenshot Achievements - Auto screenshot on achievement earned
- Faster Auto Loot - Instant auto looting
- Confirm Loot Roll - Require confirmation for passing on loot
- Hide Talking Head - Hide the talking head frame
- Hide Error Frame - Hide red error messages

## 📦 Installation

1. Download the latest release
2. Extract the `Weevil` folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
3. Restart World of Warcraft or reload UI with `/reload`

## 🎯 Usage

### Commands
- `/weevil` or `/wv` - Open beautiful custom options panel
- `/weevil infobar` - Toggle the info bar
- `/weevil help` - Show available commands

### Minimap Icon
- **Left-Click**: Open custom options panel
- **Right-Click**: Toggle info bar

### Configuration
All 50+ features can be configured through the stunning in-game custom UI:
- Type `/weevil` to open the options
- Navigate through categories using the icon buttons
- Toggle any feature on/off with beautiful checkboxes
- All settings save automatically per character profile

## ✨ The Info Bar

The info bar displays at the top (or bottom) of your screen with:
- **Three Sections**: Left (Performance & Character), Center (Location & Time), Right (Social & Currency)
- **Color Coding**: Performance metrics change color based on status
- **Real-time Updates**: 1-second refresh cycle
- **Fully Customizable**: Show/hide any display element
- **Professional Design**: Modern styling with borders and accents

## 🔧 Compatibility

- **WoW Version**: Retail (The War Within - 11.0.2, Interface 110002)
- **Libraries**: Uses Ace3 libraries for robust functionality
- **Performance**: Optimized for minimal memory usage and CPU impact
- **No Taint**: Clean, secure code with no taint issues

## 🌍 Localization

Currently supported languages:
- English (enUS) - Complete
- German (deDE) - Complete

## 📊 Technical Details

### Structure
```
Weevil/
├── Weevil.toc                # TOC file
├── Weevil.lua                # Main addon file
├── Modules/                  # Feature modules
│   ├── Automation.lua        # 25+ automation features
│   ├── InfoBar.lua           # 25+ info displays
│   └── UI.lua                # UI improvements
├── Config/                   # Configuration
│   ├── CustomUI.lua          # Beautiful custom interface
│   └── Options.lua           # AceConfig fallback
├── Libs/                     # Library dependencies (13 libs)
├── Locales/                  # Translations
│   ├── enUS.lua
│   └── deDE.lua
└── Media/                    # Textures and media files
```

### Features Count
- **50+ Total Features**
- **25+ Automation Features**
- **25+ InfoBar Displays**
- **6 UI Enhancements**
- **13 Included Libraries**
- **2 Language Localizations**

## 🎨 What Makes This Addon Special

1. **Not Generic** - Custom designed UI, not cookie-cutter AceConfig
2. **Comprehensive** - Combines multiple addon types into one
3. **Beautiful** - Professional styling with modern design principles
4. **Powerful** - 50+ features inspired by the best QoL addons
5. **Lightweight** - Despite the features, optimized for performance
6. **Organized** - Everything logically grouped and easy to find

## 💡 Inspired By

- **Leatrix Plus** - Automation features and quality of life improvements
- **Titan Panel** - Information display bar and data broker integration

## 📝 Changelog

### Version 1.0.0
- Initial release with 50+ features
- Full automation module (25+ features)
- Comprehensive information bar (25+ displays)
- Beautiful custom UI interface
- UI tweaks and enhancements
- Full configuration with profile support
- English and German localization
- Minimap icon integration
- Professional color-coded displays