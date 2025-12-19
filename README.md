# Weevil

A comprehensive World of Warcraft Retail addon that combines the best features of automation addons like Leatrix Plus with information display features like Titan Panel.

## Features

### 🤖 Automation Module
- **Auto Accept Quests**: Automatically accept quests from NPCs
- **Auto Turn-in Quests**: Automatically complete quests
- **Auto Repair**: Automatically repair gear at vendors (with guild repair option)
- **Auto Sell Junk**: Automatically sell gray items to vendors
- **Auto Accept Resurrect**: Accept resurrection requests automatically
- **Auto Skip Cutscenes**: Skip cinematics and movies automatically
- **Auto Accept Summon**: Accept warlock summons automatically
- **Auto Release in BGs**: Automatically release spirit in battlegrounds

### 📊 Info Bar Module
Displays a customizable information bar (Titan Panel style) with:
- **FPS Display**: Current frames per second
- **Latency Display**: Home and world latency (ms)
- **Gold Display**: Current gold with icon
- **Bag Space**: Free bag slots / total slots
- **Durability**: Average item durability percentage (color-coded)
- **Location**: Current zone and coordinates
- **Clock**: Server time and local time
- **Memory Usage**: Addon memory consumption

The info bar can be:
- Positioned at top or bottom of screen
- Toggled on/off with a command
- Customized with background transparency
- Each element can be shown/hidden individually

### 💬 Chat Module
- **Chat Copy**: Copy chat text with Shift+Right-Click
- **Timestamps**: Show timestamps in chat messages
- **URL Detection**: Detect and highlight URLs in chat
- **Class Colored Names**: Color player names by class in chat
- **Sticky Channels**: Remember the last chat channel used

### 🎨 UI Module
- **Hide Error Frame**: Hide the red error text
- **Faster Auto Loot**: Instant auto looting
- **Screenshot Achievements**: Automatically screenshot when earning achievements
- **Enhanced Tooltips**: Show item level and spell IDs in tooltips
- **Confirm Loot Roll**: Require confirmation for passing on loot
- **Hide Talking Head**: Hide the talking head frame

## Installation

1. Download the latest release
2. Extract the `Weevil` folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
3. Restart World of Warcraft or reload UI with `/reload`

## Usage

### Commands
- `/weevil` or `/wv` - Open options panel
- `/weevil infobar` - Toggle the info bar
- `/weevil help` - Show available commands

### Minimap Icon
- **Left-Click**: Open options panel
- **Right-Click**: Toggle info bar

### Configuration
All features can be configured through the in-game options panel:
- Type `/weevil` to open the options
- Or access via ESC > Interface > AddOns > Weevil

## Compatibility

- **WoW Version**: Retail (The War Within - 11.0.2, Interface 110002)
- **Libraries**: Uses Ace3 libraries for robust functionality
- **Performance**: Optimized for minimal memory usage and CPU impact

## Localization

Currently supported languages:
- English (enUS) - Default
- German (deDE)

## Technical Details

### Structure
```
Weevil/
├── Weevil.toc          # TOC file
├── Weevil.lua          # Main addon file
├── Modules/            # Feature modules
│   ├── Automation.lua
│   ├── InfoBar.lua
│   ├── Chat.lua
│   └── UI.lua
├── Config/             # Configuration
│   └── Options.lua
├── Libs/               # Library dependencies
├── Locales/            # Translations
│   ├── enUS.lua
│   └── deDE.lua
└── Media/              # Textures and media files
```

### Libraries Used
- LibStub
- CallbackHandler-1.0
- AceAddon-3.0
- AceDB-3.0
- AceDBOptions-3.0
- AceEvent-3.0
- AceConsole-3.0
- AceGUI-3.0
- AceConfig-3.0
- AceLocale-3.0
- LibDataBroker-1.1
- LibDBIcon-1.0
- LibQTip-1.0

## Support

If you encounter any issues or have feature requests, please open an issue on the GitHub repository.

## License

MIT License - See LICENSE file for details

## Credits

**Author**: JugoBetrugoTV

Inspired by:
- Leatrix Plus (automation features)
- Titan Panel (information display)

## Changelog

### Version 1.0.0
- Initial release
- Full automation module with quest handling, repairs, and more
- Information bar with FPS, latency, gold, bags, durability, location, time, and memory
- Chat enhancements including copy, timestamps, URL detection, and class colors
- UI tweaks including tooltips, auto-loot, screenshots, and talking head hiding
- Full configuration panel with profile support
- Minimap icon with LibDBIcon
- English and German localization