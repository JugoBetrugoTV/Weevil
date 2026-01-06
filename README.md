# Jebiga Multi-Gamemode (MGM) for MTA:SA 1.6

A comprehensive, modern Multi-Gamemode server for Multi Theft Auto: San Andreas, inspired by FFS Gaming and other classic MGM servers.

## 🎮 Features

### Gamemodes
- **DM (Deathmatch Race)** - Race with weapons enabled, eliminate opponents!
- **Race (Oldschool)** - Classic racing without weapons
- **DD (Destruction Derby)** - Last vehicle standing wins
- **Hunter** - Helicopter combat arena
- **Shooter** - FPS-style deathmatch
- **Stuntage** - Complete stunts around San Andreas
- **Trials** - Motorbike obstacle courses
- **Carball** - Football/Soccer with cars
- **Hot Pursuit** - Racers vs Police
- **Run Arena** - On-foot racing with combat
- **Training** - Practice your skills

### Core Systems
- 🔐 **Account System** - Register/Login with MySQL database
- 🏠 **Modern Lobby** - Beautiful gamemode selection with click-to-teleport
- 📊 **Scoreboard** - Real-time player statistics
- ⏱️ **TopTimes** - Track best times on maps
- 📈 **Stats** - Comprehensive player statistics per gamemode
- 💰 **Economy** - JCoins and Jebiga Points (JP) system
- 🏆 **Achievements** - Unlock rewards for accomplishments
- 🚗 **Garage** - Buy and customize vehicles
- 👤 **User Panel** - Feature-rich profile with 7 tabs
- 🛡️ **Admin Panel** - Manage players and server

### New in v2.0
- **Modern Custom UI** - Beautiful dark theme with gradients and animations
- **Clickable Lobby Cards** - Click on any gamemode to instantly teleport
- **Automatic Map Detection** - Maps are auto-categorized by prefix (e.g., [DM], [Race])
- **Enhanced User Panel** - 7 tabs: Overview, Statistics, Gamemodes, Achievements, Inventory, Friends, Settings
- **Rank System** - Unranked → Bronze → Silver → Gold → Platinum → Diamond → Master
- **Settings Panel** - Toggle sounds, notifications, HUD options

### New in v2.1 (Vultaic-Inspired Features)
- **Custom HUD** - Speedometer with animated arc, health/armor bars, FPS/ping display
- **Vehicle Neons** - Customizable underglow lights with rainbow mode (Press N)
- **Vehicle Tuning** - Full tuning system with paint, wheels, spoilers, nitro (Press F6)
- **Music Player** - Custom radio stations and volume control (Press F8)
- **Clan System** - Create clans, invite members, clan chat (Press F9)

### Map Prefix System
Maps are automatically detected and categorized based on their name prefix:

| Gamemode | Accepted Prefixes |
|----------|-------------------|
| DM | `[DM]`, `[Deathmatch]`, `DM-` |
| Race | `[Race]`, `[Oldschool]`, `Race-`, `[OS]` |
| DD | `[DD]`, `[Derby]`, `DD-`, `[Destruction]` |
| Hunter | `[Hunter]`, `[Hunt]`, `Hunter-` |
| Shooter | `[Shooter]`, `[FPS]`, `[CTF]`, `Shooter-` |
| Stuntage | `[Stunt]`, `[Stuntage]`, `Stunt-` |
| Trials | `[Trials]`, `[Trial]`, `Trials-` |
| Carball | `[Carball]`, `[CB]`, `Carball-` |
| Hot Pursuit | `[HP]`, `[HotPursuit]`, `[Pursuit]`, `HP-` |
| Run Arena | `[Run]`, `[RunArena]`, `[RA]`, `Run-` |
| Training | `[Training]`, `[Train]`, `[Practice]` |

## 📦 Installation

### Requirements
- MTA:SA Server 1.6.0 or higher
- MySQL Server 5.7+ or MariaDB 10.2+

### Setup

1. Copy the `resources` folder to your MTA server's `mods/deathmatch/` directory

2. Create a MySQL database and update the configuration in:
   ```
   resources/jebiga_core/shared/config.lua
   ```

   Update the database settings:
   ```lua
   Config.Database = {
       host = "localhost",
       port = 3306,
       database = "jebiga_mgm",
       username = "your_username",
       password = "your_password",
       options = "autoreconnect=1;charset=utf8mb4"
   }
   ```

3. Add to your `mtaserver.conf`:
   ```xml
   <resource src="jebiga_start" startup="1" protected="0"/>
   ```

4. Start the server!

## 🎯 Commands

### Player Commands
| Command | Description |
|---------|-------------|
| `/lobby` | Return to lobby |
| `/hub` | Alias for /lobby |
| `/maps <gamemode>` | List maps for a gamemode |
| `/stats [player]` | View player stats |
| `/balance` | Check your balance |
| `/pay [player] [amount]` | Send money to player |
| `/daily` | Claim daily bonus |
| `/top [money/gamemode]` | View leaderboards |
| `/pm [player] [message]` | Private message |
| `/neon` | Open neon lights menu |
| `/tuning` | Open vehicle tuning |
| `/music` | Open music player |
| `/clan` | Open clan panel |
| `/cc [message]` | Clan chat |
| `/hud` | Toggle HUD |
| `/speedo` | Toggle speedometer |
| `/vol [0-100]` | Set music volume |

### Admin Commands
| Command | Level | Description |
|---------|-------|-------------|
| `/kick [player] [reason]` | 1 | Kick a player |
| `/mute [player] [minutes]` | 1 | Mute a player |
| `/ban [player] [hours] [reason]` | 2 | Ban a player |
| `/announce [message]` | 2 | Server announcement |
| `/tp [player]` | 2 | Teleport to player |
| `/bring [player]` | 2 | Bring player to you |
| `/givemoney [player] [amount]` | 3 | Give money |
| `/givepoints [player] [amount]` | 3 | Give points |
| `/setadmin [player] [level]` | 4 | Set admin level |
| `/jebigareload` | Owner | Reload all resources |
| `/jebigastatus` | All | View server status |

### Keybinds
| Key | Function |
|-----|----------|
| **F1** | Open gamemode selection (Lobby) |
| **F3** | Open user panel |
| **F5** | Open garage |
| **F6** | Open vehicle tuning |
| **F7** | Toggle HUD |
| **F8** | Open music player |
| **F9** | Open clan panel |
| **N** | Open neon lights menu (in vehicle) |
| **TAB** | Show scoreboard |
| **ESC** | Close current panel |

## 🗂️ Resource Structure

```
resources/
├── jebiga_start/          # Startup resource
├── jebiga_core/           # Core functionality & UI library
│   ├── client/ui_lib.lua  # Custom UI components
│   ├── client/hud.lua     # Custom HUD with speedometer
│   └── shared/config.lua  # Main configuration
├── jebiga_accounts/       # Account system
├── jebiga_lobby/          # Modern lobby with teleportation
├── jebiga_scoreboard/     # Scoreboard
├── jebiga_toptimes/       # Top times
├── jebiga_userpanel/      # Enhanced user panel (7 tabs)
├── jebiga_achievements/   # Achievements
├── jebiga_garage/         # Garage system
├── jebiga_admin/          # Admin panel
├── jebiga_neons/          # Vehicle neon lights system
├── jebiga_tuning/         # Vehicle tuning/customization
├── jebiga_music/          # Music/radio player
├── jebiga_clans/          # Clan system
├── jebiga_dm/             # DM gamemode
├── jebiga_race/           # Race gamemode
├── jebiga_dd/             # DD gamemode
├── jebiga_hunter/         # Hunter gamemode
├── jebiga_shooter/        # Shooter gamemode
├── jebiga_stuntage/       # Stuntage gamemode
├── jebiga_trials/         # Trials gamemode
├── jebiga_carball/        # Carball gamemode
├── jebiga_hotpursuit/     # Hot Pursuit gamemode
├── jebiga_runarena/       # Run Arena gamemode
└── jebiga_training/       # Training gamemode
```

## 🎨 Custom Theme

The server features a modern dark theme with:
- Blue-to-purple gradients
- Smooth hover animations
- Card-based UI components
- Responsive scaling
- Custom color system

Colors can be customized in `Config.Theme` within `jebiga_core/shared/config.lua`.

## 🛠️ Configuration

All main configuration is in `jebiga_core/shared/config.lua`:

- Server settings (name, motto, website)
- Database configuration
- Lobby settings
- Map prefix detection patterns
- Gamemode settings (points, money rewards, dimensions)
- Achievement definitions
- VIP settings
- Admin levels
- Theme colors and fonts

## 📝 Database Tables

The system automatically creates these tables:
- `accounts` - Player accounts
- `player_stats` - Gamemode statistics
- `toptimes` - Map records
- `achievements` - Achievement definitions
- `player_achievements` - Unlocked achievements
- `player_vehicles` - Owned vehicles
- `friends` - Friend relationships
- `clans` - Clan information
- `clan_members` - Clan memberships
- `transaction_log` - Money transactions
- `admin_log` - Admin actions
- `maps` - Map database

## 🙏 Credits

- Inspired by [FFS Gaming](https://ffs.gg/) and [Vultaic MGM](https://github.com/rasikhq/Vultaic-MGM)
- Built for MTA:SA 1.6
- Version 2.1.0

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

**Jebiga Gaming** - The Ultimate MTA Experience
