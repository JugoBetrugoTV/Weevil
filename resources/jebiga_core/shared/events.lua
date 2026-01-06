--[[
    Jebiga Multi-Gamemode - Event Definitions
    Central event name definitions for consistency
]]

Events = {}

-- Account Events
Events.Account = {
    -- Server -> Client
    LOGIN_SUCCESS = "weevil:account:loginSuccess",
    LOGIN_FAILED = "weevil:account:loginFailed",
    REGISTER_SUCCESS = "weevil:account:registerSuccess",
    REGISTER_FAILED = "weevil:account:registerFailed",
    LOGOUT = "weevil:account:logout",
    DATA_UPDATE = "weevil:account:dataUpdate",

    -- Client -> Server
    REQUEST_LOGIN = "weevil:account:requestLogin",
    REQUEST_REGISTER = "weevil:account:requestRegister",
    REQUEST_LOGOUT = "weevil:account:requestLogout"
}

-- Lobby Events
Events.Lobby = {
    -- Server -> Client
    PLAYER_JOIN = "weevil:lobby:playerJoin",
    PLAYER_LEAVE = "weevil:lobby:playerLeave",
    UPDATE_PLAYER_LIST = "weevil:lobby:updatePlayerList",
    UPDATE_GAMEMODE_STATUS = "weevil:lobby:updateGamemodeStatus",

    -- Client -> Server
    REQUEST_JOIN_GAMEMODE = "weevil:lobby:requestJoinGamemode",
    REQUEST_LEAVE_GAMEMODE = "weevil:lobby:requestLeaveGamemode"
}

-- Arena Events
Events.Arena = {
    -- Server -> Client
    ROUND_START = "weevil:arena:roundStart",
    ROUND_END = "weevil:arena:roundEnd",
    COUNTDOWN = "weevil:arena:countdown",
    PLAYER_SPAWN = "weevil:arena:playerSpawn",
    PLAYER_DEATH = "weevil:arena:playerDeath",
    PLAYER_FINISH = "weevil:arena:playerFinish",
    MAP_CHANGE = "weevil:arena:mapChange",
    MAP_VOTE_START = "weevil:arena:mapVoteStart",
    MAP_VOTE_END = "weevil:arena:mapVoteEnd",
    UPDATE_RANKINGS = "weevil:arena:updateRankings",

    -- Client -> Server
    VOTE_MAP = "weevil:arena:voteMap",
    REQUEST_SPECTATE = "weevil:arena:requestSpectate"
}

-- Scoreboard Events
Events.Scoreboard = {
    -- Server -> Client
    UPDATE = "weevil:scoreboard:update",
    TOGGLE = "weevil:scoreboard:toggle"
}

-- TopTimes Events
Events.TopTimes = {
    -- Server -> Client
    NEW_TOPTIME = "weevil:toptimes:newToptime",
    UPDATE_LIST = "weevil:toptimes:updateList",

    -- Client -> Server
    REQUEST_TOPTIMES = "weevil:toptimes:requestToptimes"
}

-- Stats Events
Events.Stats = {
    -- Server -> Client
    UPDATE = "weevil:stats:update",
    SHOW_PROFILE = "weevil:stats:showProfile",

    -- Client -> Server
    REQUEST_STATS = "weevil:stats:requestStats",
    REQUEST_PROFILE = "weevil:stats:requestProfile"
}

-- Points & Money Events
Events.Currency = {
    -- Server -> Client
    UPDATE_POINTS = "weevil:currency:updatePoints",
    UPDATE_MONEY = "weevil:currency:updateMoney",
    REWARD_RECEIVED = "weevil:currency:rewardReceived"
}

-- Achievement Events
Events.Achievements = {
    -- Server -> Client
    UNLOCKED = "weevil:achievements:unlocked",
    UPDATE_LIST = "weevil:achievements:updateList",
    SHOW_PANEL = "weevil:achievements:showPanel",

    -- Client -> Server
    REQUEST_LIST = "weevil:achievements:requestList"
}

-- UserPanel Events
Events.UserPanel = {
    -- Server -> Client
    OPEN = "weevil:userpanel:open",
    UPDATE = "weevil:userpanel:update",

    -- Client -> Server
    REQUEST_OPEN = "weevil:userpanel:requestOpen",
    UPDATE_SETTINGS = "weevil:userpanel:updateSettings"
}

-- Garage Events
Events.Garage = {
    -- Server -> Client
    OPEN = "weevil:garage:open",
    UPDATE_VEHICLES = "weevil:garage:updateVehicles",
    VEHICLE_PURCHASED = "weevil:garage:vehiclePurchased",

    -- Client -> Server
    REQUEST_OPEN = "weevil:garage:requestOpen",
    PURCHASE_VEHICLE = "weevil:garage:purchaseVehicle",
    SELECT_VEHICLE = "weevil:garage:selectVehicle",
    CUSTOMIZE_VEHICLE = "weevil:garage:customizeVehicle"
}

-- Admin Events
Events.Admin = {
    -- Server -> Client
    PANEL_OPEN = "weevil:admin:panelOpen",
    PLAYER_LIST = "weevil:admin:playerList",
    LOG_UPDATE = "weevil:admin:logUpdate",

    -- Client -> Server
    REQUEST_PANEL = "weevil:admin:requestPanel",
    KICK_PLAYER = "weevil:admin:kickPlayer",
    BAN_PLAYER = "weevil:admin:banPlayer",
    MUTE_PLAYER = "weevil:admin:mutePlayer",
    SET_ADMIN = "weevil:admin:setAdmin"
}

-- Chat Events
Events.Chat = {
    -- Server -> Client
    MESSAGE = "weevil:chat:message",
    SYSTEM_MESSAGE = "weevil:chat:systemMessage",

    -- Client -> Server
    SEND_MESSAGE = "weevil:chat:sendMessage"
}

-- Notification Events
Events.Notification = {
    -- Server -> Client
    SHOW = "weevil:notification:show",
    SHOW_INFO = "weevil:notification:showInfo",
    SHOW_SUCCESS = "weevil:notification:showSuccess",
    SHOW_WARNING = "weevil:notification:showWarning",
    SHOW_ERROR = "weevil:notification:showError"
}

-- Gamemode-specific Events
Events.DM = {
    KILL = "weevil:dm:kill",
    DEATH = "weevil:dm:death",
    WEAPON_PICKUP = "weevil:dm:weaponPickup"
}

Events.Race = {
    CHECKPOINT = "weevil:race:checkpoint",
    FINISH = "weevil:race:finish",
    DNF = "weevil:race:dnf"
}

Events.DD = {
    ELIMINATION = "weevil:dd:elimination",
    LAST_STANDING = "weevil:dd:lastStanding"
}

Events.Hunter = {
    KILL = "weevil:hunter:kill",
    SPAWN = "weevil:hunter:spawn"
}

Events.Shooter = {
    KILL = "weevil:shooter:kill",
    HEADSHOT = "weevil:shooter:headshot"
}

Events.Stuntage = {
    STUNT_COMPLETE = "weevil:stuntage:stuntComplete",
    STUNT_FAILED = "weevil:stuntage:stuntFailed"
}

Events.Trials = {
    CHECKPOINT = "weevil:trials:checkpoint",
    FINISH = "weevil:trials:finish",
    FALL = "weevil:trials:fall"
}

Events.Carball = {
    GOAL = "weevil:carball:goal",
    TOUCH = "weevil:carball:touch"
}

Events.HotPursuit = {
    CAUGHT = "weevil:hotpursuit:caught",
    ESCAPED = "weevil:hotpursuit:escaped",
    ROLE_ASSIGN = "weevil:hotpursuit:roleAssign"
}

Events.RunArena = {
    KILL = "weevil:runarena:kill",
    CHECKPOINT = "weevil:runarena:checkpoint"
}

return Events
