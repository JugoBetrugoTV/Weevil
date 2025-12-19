# Weevil Feature List

## Complete Implementation - 50+ Features

### 1. Automation Module (25+ Features)

**Quest Automation:**
✅ Auto Accept Quests - Automatically accept quests from NPCs
✅ Auto Turn-in Quests - Automatically complete quests (with reward selection)
✅ Auto Gossip - Skip NPC dialogue and select options automatically

**Merchant Automation:**
✅ Auto Repair - Repair gear automatically at vendors
✅ Use Guild Repair - Option to use guild bank funds for repairs
✅ Auto Sell Junk - Automatically sell gray quality items
✅ Auto Sell Grey - Sell all grey items to vendors

**Loot Automation:**
✅ Faster Looting - Instant loot delay (0ms)
✅ Enhanced Auto Loot - Improved auto loot speed
✅ Auto Greed Greens - Automatically greed on uncommon (green) items
✅ Auto Greed Blues - Automatically greed on rare (blue) items

**Social Automation:**
✅ Auto Accept Resurrect - Accept res requests automatically
✅ Auto Accept Summon - Accept warlock summons automatically
✅ Auto Invite - Auto invite from whispers with keyword
✅ Auto Decline Duels - Automatically decline duel requests
✅ Auto Decline Party - Automatically decline party invites

**Combat Automation:**
✅ Auto Release in BGs - Auto release spirit in battlegrounds
✅ Auto Skinning - Automatic skinning of corpses

**UI Automation:**
✅ Auto Skip Cutscenes - Skip cinematics and movies
✅ Hide Zone Text - Hide zone change announcements
✅ Hide Boss Emotes - Hide boss emote frame
✅ Hide Error Messages - Hide red error text frame
✅ Auto Confirm Bind - Auto confirm bind on equip
✅ Auto Confirm Disenchant - Auto confirm disenchant

**Miscellaneous:**
✅ Fast Waypoints - Faster waypoint calculation
✅ Auto Accept Party Sync - Automatically accept party sync
✅ Dismount in Water - Automatically dismount when entering water
✅ Auto Equipment Compare - Always show equipment comparisons

### 2. Info Bar Module (25+ Displays)

**Performance Displays:**
✅ FPS Display - Current frames per second (color-coded: green >60, yellow >30, red <30)
✅ Latency Display - Home and world latency in ms (color-coded)
✅ Memory Usage - Addon memory consumption in MB

**Character Displays:**
✅ Bag Space - Free slots / total slots (color-coded by percentage)
✅ Durability - Average item durability % (color-coded: green >50%, yellow >25%, red <25%)
✅ XP Progress - Experience bar with percentage and rested XP indicator
✅ Reputation - Watched faction reputation progress with standing
✅ Item Level - Average equipped item level (calculated across all slots)
✅ Talent Spec - Current specialization name
✅ Movement Speed - Player movement speed percentage

**Currency Displays:**
✅ Gold - Current character gold with icon texture
✅ Realm Gold - Total gold across all characters on realm
✅ Currencies - First tracked currency with name and quantity

**Location Displays:**
✅ Location - Current zone and subzone names
✅ Coordinates - Player X, Y coordinates (when available)
✅ Zone Level - Zone level range information

**Time Displays:**
✅ Game Time - Server/realm time (HH:MM format)
✅ Local Time - Your local computer time
✅ 24-Hour Format - Toggle between 12h/24h format
✅ Dual Time Display - Show both server and local time

**Social Displays:**
✅ Friends Online - Number of online friends (Battle.net + regular friends combined)
✅ Guild Online - Number of online guild members / total members
✅ Mail Indicator - "NEW!" indicator when you have new mail

**Instance Displays:**
✅ Instance Difficulty - Current dungeon/raid difficulty (N/H/M indicator)
✅ Saved Instances - Instance lockout information display
✅ Quest Log - Current quest count / maximum quests (color-coded when near limit)

**Tracking Displays:**
✅ Tracking - Current tracking type
✅ Quest Tracking - Active quest objectives

**Bar Customization:**
✅ Position Toggle - Top or bottom of screen
✅ Bar Height - Adjustable (default 24px)
✅ Font Size - Customizable (default 12pt)
✅ Background Color - RGBA customizable
✅ Border Color - Customizable accent borders
✅ Three-Section Layout - Left (performance/character), Center (location/time), Right (social/currency)

### 3. Custom UI System

✅ Beautiful modern gradient design with themed colors
✅ Category navigation with icons and accent bars
✅ Automation category (green theme with gear icon)
✅ Info Bar category (blue theme with note icon)
✅ UI Tweaks category (orange theme with gear icon)
✅ Profiles category (purple theme with book icon)
✅ Scrollable content panels for long option lists
✅ Section-based organization within categories
✅ Professional tooltips on all options
✅ Custom styled checkboxes and buttons
✅ Gradient title bar with version display
✅ Professional close button with textures
✅ Content background with border accents
✅ Smooth category switching
✅ No generic AceConfig interface

### 4. UI Module (6 Features)

✅ Hide Error Frame - Hide red error text
✅ Faster Auto Loot - Instant auto looting (0 delay)
✅ Screenshot Achievements - Auto screenshot on achievement earned
✅ Enhanced Tooltips - Show item level and IDs in tooltips
✅ Confirm Loot Roll - Require confirmation for passing on loot
✅ Hide Talking Head - Hide the talking head frame

### 5. Core Functionality

✅ AceAddon-3.0 framework initialization
✅ AceDB-3.0 saved variables management (WeevilDB)
✅ Slash command registration (/weevil, /wv)
✅ LibDataBroker launcher integration
✅ Minimap icon with LibDBIcon
✅ Proper module loading and initialization
✅ Error-free startup and shutdown
✅ Database namespace system for module settings
✅ Profile management support

### 6. Localization

✅ English (enUS) - Complete translation (default)
✅ German (deDE) - Complete translation
✅ AceLocale-3.0 integration
✅ All UI strings localized
✅ Expandable to additional languages

### 7. Libraries (13 Total)

✅ LibStub - Library loader
✅ CallbackHandler-1.0 - Event callback system
✅ AceAddon-3.0 - Addon framework
✅ AceDB-3.0 - Database management
✅ AceDBOptions-3.0 - Profile options
✅ AceEvent-3.0 - Event handling
✅ AceConsole-3.0 - Slash commands
✅ AceGUI-3.0 - GUI framework
✅ AceConfig-3.0 - Configuration system (4 components)
✅ AceLocale-3.0 - Localization
✅ LibDataBroker-1.1 - Data broker protocol
✅ LibDBIcon-1.0 - Minimap icon
✅ LibQTip-1.0 - Tooltip library

### 8. Documentation

✅ Comprehensive README.md with all features
✅ Complete FEATURES.md listing
✅ .gitignore for WoW development
✅ Installation instructions
✅ Usage guide with screenshots
✅ MIT LICENSE file

## Technical Specifications

- **WoW Version**: Retail 11.0.2 (The War Within)
- **Interface**: 110002
- **Saved Variables**: WeevilDB
- **Total Lines of Code**: ~2,000+ lines
- **Total Features**: 50+ individual features
- **Automation Features**: 25+
- **InfoBar Displays**: 25+
- **UI Enhancements**: 6
- **Supported Languages**: 2 (English, German)
- **Modules**: 3 feature modules
- **Libraries**: 13 external libraries

## Quality Assurance

✅ All features are toggleable
✅ Settings persist between sessions
✅ Clean code with comments
✅ Proper event handling
✅ Error-safe implementations
✅ Memory-efficient design
✅ No taint issues
✅ Follows WoW addon best practices
✅ Color-coded performance indicators
✅ Professional UI design
✅ Database initialization properly ordered
✅ Module namespaces correctly implemented

## User Experience

✅ Easy installation
✅ Beautiful custom UI (not generic)
✅ Intuitive configuration
✅ Helpful slash commands
✅ Minimap icon integration
✅ Visual feedback with colors
✅ Comprehensive tooltips
✅ Organized settings panels
✅ Profile support for multiple characters
✅ Three-section info bar layout
✅ Category-based navigation
✅ Scrollable content areas
✅ Professional styling throughout

## What Makes This Special

✅ **Custom UI** - Not generic AceConfig, professionally designed
✅ **Comprehensive** - 50+ features in one addon
✅ **Organized** - Logical grouping and navigation
✅ **Beautiful** - Modern gradient design with themed colors
✅ **Powerful** - Combines best of Leatrix Plus + Titan Panel
✅ **Lightweight** - Optimized despite extensive features
✅ **Color-Coded** - Visual feedback on all metrics
✅ **Three-Section Bar** - Professional layout
✅ **Fully Toggleable** - Every feature can be enabled/disabled
✅ **Profile System** - Different configs per character
