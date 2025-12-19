# Weevil - WoW Quality of Life Addon

Weevil is a comprehensive World of Warcraft addon for Retail version 11.2.7 (The War Within), inspired by Leatrix Plus and Titan Panel. The addon provides extensive quality of life improvements through modular features covering automation, chat enhancements, tooltips, minimap enhancements, interface improvements, combat features, social features, and a custom data broker panel.

## Project Overview

**Purpose**: Provide a feature-rich, modular quality of life addon for WoW Retail with a modern UI and extensive customization options.

**Target Audience**: WoW Retail players looking for comprehensive quality of life improvements.

**Key Features**:
- Modular architecture with 70+ independent features
- Custom data broker panel (Titan Panel style)
- Modern dark-themed configuration UI
- Support for English and German localization
- Profile system for settings management

## Tech Stack

### Primary Language
- **Lua** (WoW addon scripting language)

### WoW API Version
- **Interface: 110207** (The War Within - Retail 11.2.7)
- Always consult [WoW API Documentation](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) for current API usage

### Required Libraries (Ace3 Framework and Extensions)
These are **community standard libraries** that should be embedded in the addon's `Libs/` directory:
- **LibStub** - Library loader
- **CallbackHandler-1.0** - Event callbacks
- **Ace3 Suite**:
  - AceAddon-3.0 - Addon framework
  - AceDB-3.0 - Saved variables and profiles
  - AceConfig-3.0 - Configuration system
  - AceGUI-3.0 - GUI widgets
  - AceConsole-3.0 - Slash commands
  - AceEvent-3.0 - Event handling
  - AceHook-3.0 - Function hooking
  - AceTimer-3.0 - Timer management
  - AceLocale-3.0 - Localization
- **LibSharedMedia-3.0** - Fonts, textures, sounds
- **LibDataBroker-1.1** - Data broker standard
- **LibDBIcon-1.0** - Minimap button
- **LibQTip-1.0** - Enhanced tooltips

## Coding Guidelines

### Lua Best Practices
- Use `local` variables whenever possible for performance
- Follow PascalCase for module/class names, camelCase for functions and variables
- Use proper indentation (4 spaces, no tabs)
- Always localize global functions at file start (e.g., `local pairs, ipairs = pairs, ipairs`)
- Avoid `for i=1,#table` loops; prefer `for i, v in ipairs(table)` for indexed arrays
- Use event-driven architecture; avoid OnUpdate handlers unless absolutely necessary

### WoW Addon Specific
- Always use `AceAddon-3.0` for addon structure
- Register events using `AceEvent-3.0` methods
- Use `AceDB-3.0` for all saved variables and profile management
- Implement modules using `AceAddon:NewModule()`
- Hook functions using `AceHook-3.0` to avoid conflicts
- Use `AceLocale-3.0` for all user-facing strings
- Protect against protected action errors in combat
- Always check for API availability before use (some APIs change between patches)

### File Organization
```
Weevil/
├── Weevil.toc           # TOC file with Interface version and file list
├── Core.lua             # Main addon initialization
├── Config.lua           # Configuration system
├── Libs/                # Embedded libraries (with libs.xml loader)
├── Locales/             # Localization files (enUS.lua, deDE.lua)
├── Modules/             # Feature modules
│   ├── Automation/
│   ├── Chat/
│   ├── Tooltip/
│   ├── Minimap/
│   ├── Interface/
│   ├── Combat/
│   ├── Social/
│   └── QoL/
├── Panel/               # Data broker panel
└── UI/                  # Configuration UI
    ├── ConfigUI.lua
    ├── Widgets.lua
    └── Theme.lua
```

### Module Structure
Each module should follow this pattern:
```lua
local addonName, addon = ...
local moduleName = addon:NewModule("ModuleName", "AceEvent-3.0")

function moduleName:OnEnable()
    -- Module initialization
    self:RegisterEvent("EVENT_NAME")
end

function moduleName:OnDisable()
    -- Module cleanup
    self:UnregisterAllEvents()
end

function moduleName:EVENT_NAME(event, ...)
    -- Event handler
end
```

### Performance Guidelines
- Use event-driven architecture instead of OnUpdate frames
- Cache frequently accessed globals
- Minimize API calls in combat
- Use throttling/debouncing for frequent events
- Profile code using WoW's built-in `/fstack` and `/framestack` tools

## Testing and Validation

### Manual Testing
- Always test in-game on the correct WoW version (Retail 11.2.7+)
- Test with Lua errors enabled (`/console scriptErrors 1`)
- Test module enable/disable functionality
- Test in both combat and non-combat scenarios
- Test with different locales if localization changes are made
- Verify profile system works (create/delete/switch profiles)

### Common Testing Scenarios
- Reload UI (`/reload`) to test initialization
- Test slash commands (`/weevil` or `/wv`)
- Test minimap button functionality
- Verify settings persist after `/reload`
- Test with other popular addons installed (ElvUI, WeakAuras, DBM)

### TOC File Validation
- Ensure Interface version matches target WoW version
- Verify all Lua files are listed in correct load order
- Check library dependencies are loaded before addon code
- Validate SavedVariables declarations

## Security and Best Practices

### Protected Functions
- Never call protected functions during combat when not allowed
- Use `InCombatLockdown()` to check combat state before protected actions
- Handle `PLAYER_REGEN_DISABLED` and `PLAYER_REGEN_ENABLED` events properly

### Error Handling
- Use `pcall()` for operations that might fail
- Provide meaningful error messages to users
- Log errors using addon's error handler if available
- Never let errors break the entire addon

### Data Sanitization
- Validate all user input before use
- Sanitize strings before displaying in chat or UI
- Check for nil values and edge cases
- Use type checking for configuration values

### Performance
- Avoid memory leaks (properly unhook and unregister)
- Clean up frames and tables when modules are disabled
- Use weak tables for cache when appropriate

## Resources

### Documentation
- [WoW API Documentation](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [Ace3 Documentation](https://www.wowace.com/projects/ace3)
- [WoW Programming](https://github.com/Stanzilla/WoWUIBugs) - Known UI bugs and workarounds

### Tools
- [WoW AddOn Studio](https://marketplace.visualstudio.com/items?itemName=Ketho.wow-api) - VSCode extension
- [BugGrabber](https://www.curseforge.com/wow/addons/bug-grabber) - Enhanced error capture
- [BugSack](https://www.curseforge.com/wow/addons/bugsack) - Error display addon

### Community Standards
- Follow [WoWAce Style Guide](https://www.wowace.com/projects/ace3/pages/style-guide)
- Use established library versions from [WoWAce](https://www.wowace.com/) or [CurseForge](https://www.curseforge.com/wow/addons)

## Development Workflow

### Making Changes
1. Identify the specific module or file to modify
2. Make minimal, focused changes
3. Test changes in-game
4. Verify no Lua errors occur
5. Test module enable/disable
6. Verify settings persistence

### Adding New Features
1. Create module in appropriate directory
2. Follow existing module structure and naming
3. Add to TOC file in correct load order
4. Add localization strings if needed
5. Add configuration options to Config.lua
6. Add UI elements to ConfigUI.lua
7. Test thoroughly in-game

### Localization
- Always use `L["String"]` for user-facing text
- Add strings to `Locales/enUS.lua` (default/fallback)
- Add translations to `Locales/deDE.lua` if applicable
- Keep strings concise and clear

## Common Pitfalls to Avoid

- Don't use global variables without `_G` prefix
- Don't create OnUpdate scripts unless absolutely necessary
- Don't call protected functions during combat inappropriately
- Don't forget to localize global API functions at file start
- Don't hardcode string values; use localization
- Don't modify Blizzard frames without proper hooking
- Don't break compatibility with other addons
- Don't create UI elements every frame; reuse them
- Don't forget to clean up event registrations and hooks when disabling modules

## Notes for Copilot

When working on this project:
- This is a Lua-based WoW addon, not a standalone application
- Changes must be compatible with WoW Retail API version 11.2.7+
- All modules should be independently toggleable
- Maintain the modular architecture
- Follow the established file structure
- Use the Ace3 framework patterns consistently
- Test all changes in-game if possible (manual verification required)
- Keep in mind that this addon will be loaded alongside many others; avoid conflicts
- Performance is critical; event-driven code only
