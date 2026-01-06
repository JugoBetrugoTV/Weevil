# Weevil Multi-Gamemode (MGM) for MTA:SA 1.6

A comprehensive Multi-Gamemode server for Multi Theft Auto: San Andreas, inspired by FFS Gaming and other classic MGM servers.

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
- 📊 **Scoreboard** - Real-time player statistics
- ⏱️ **TopTimes** - Track best times on maps
- 📈 **Stats** - Comprehensive player statistics per gamemode
- 💰 **Economy** - Money and points system
- 🏆 **Achievements** - Unlock rewards for accomplishments
- 🚗 **Garage** - Buy and customize vehicles
- 👤 **User Panel** - View your profile and settings
- 🛡️ **Admin Panel** - Manage players and server

### Additional Features
- Lobby with gamemode selection GUI
- Cinematic camera in lobby
- VIP system with bonuses
- Clan system
- Friends list
- Daily bonuses
- Anti-cheat system
- Map voting system

## 📦 Installation

### Requirements
- MTA:SA Server 1.6.0 or higher
- MySQL Server 5.7+ or MariaDB 10.2+

### Setup

1. Copy the `resources` folder to your MTA server's `mods/deathmatch/` directory

2. Create a MySQL database and update the configuration in:
   ```
   resources/weevil_core/shared/config.lua
   ```

   Update the database settings:
   ```lua
   Config.Database = {
       host = "localhost",
       port = 3306,
       database = "weevil_mgm",
       username = "your_username",
       password = "your_password",
       options = "autoreconnect=1;charset=utf8mb4"
   }
   ```

3. Add to your `mtaserver.conf`:
   ```xml
   <resource src="weevil_start" startup="1" protected="0"/>
   ```

4. Start the server!

## 🎯 Commands

### Player Commands
| Command | Description |
|---------|-------------|
| `/help` | Show available commands |
| `/lobby` | Return to lobby |
| `/join [gamemode]` | Join a gamemode |
| `/leave` | Leave current gamemode |
| `/stats [player]` | View player stats |
| `/profile` | Open your profile |
| `/balance` | Check your balance |
| `/pay [player] [amount]` | Send money to player |
| `/daily` | Claim daily bonus |
| `/top [money/gamemode]` | View leaderboards |
| `/pm [player] [message]` | Private message |

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
| `/admin` | 1 | Open admin panel |

### Keybinds
| Key | Function |
|-----|----------|
| F1 | Show help |
| F2 | Open gamemode selection |
| F3 | Open profile |
| F4 | Toggle scoreboard |
| F5 | Open garage |
| F7 | Toggle HUD |
| TAB | Quick scoreboard |

## 🗂️ Resource Structure

```
resources/
├── weevil_start/          # Startup resource
├── weevil_core/           # Core functionality
├── weevil_accounts/       # Account system
├── weevil_lobby/          # Lobby system
├── weevil_scoreboard/     # Scoreboard
├── weevil_toptimes/       # Top times
├── weevil_userpanel/      # User panel
├── weevil_achievements/   # Achievements
├── weevil_garage/         # Garage system
├── weevil_admin/          # Admin panel
├── weevil_dm/             # DM gamemode
├── weevil_race/           # Race gamemode
├── weevil_dd/             # DD gamemode
├── weevil_hunter/         # Hunter gamemode
├── weevil_shooter/        # Shooter gamemode
├── weevil_stuntage/       # Stuntage gamemode
├── weevil_trials/         # Trials gamemode
├── weevil_carball/        # Carball gamemode
├── weevil_hotpursuit/     # Hot Pursuit gamemode
├── weevil_runarena/       # Run Arena gamemode
└── weevil_training/       # Training gamemode
```

## 🛠️ Configuration

All main configuration is in `weevil_core/shared/config.lua`:

- Server settings
- Database configuration
- Gamemode settings (points, money rewards, etc.)
- VIP settings
- Admin levels
- GUI theme colors

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

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

**Weevil Gaming** - Multi-Gamemode Server for MTA:SA
