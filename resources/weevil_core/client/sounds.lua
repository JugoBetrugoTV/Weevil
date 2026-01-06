--[[
    Weevil Multi-Gamemode - Sound System
    Client-side sound effects and music
]]

local sounds = {}
local musicVolume = 0.5
local sfxVolume = 0.7
local currentMusic = nil

-- Sound definitions (using MTA built-in sounds or custom)
local soundEffects = {
    countdown = { frequency = 800, duration = 200 },
    start = { frequency = 1200, duration = 500 },
    finish = { frequency = 1000, duration = 300 },
    win = { frequency = 1500, duration = 800 },
    lose = { frequency = 400, duration = 600 },
    kill = { frequency = 600, duration = 150 },
    death = { frequency = 300, duration = 400 },
    pickup = { frequency = 900, duration = 100 },
    checkpoint = { frequency = 700, duration = 200 },
    pm = { frequency = 1100, duration = 150 },
    notification = { frequency = 800, duration = 100 },
    click = { frequency = 500, duration = 50 },
    error = { frequency = 200, duration = 300 }
}

-- Play sound effect
function playSound(soundName)
    if not Config.Sounds.enabled then return end

    local soundData = soundEffects[soundName]
    if not soundData then return end

    -- Using playSoundFrontEnd for built-in sounds
    -- Or generate simple tones using playSound3D with generated audio

    -- For now, use the notification sound from GTA
    local soundId = getSoundIdForEffect(soundName)
    if soundId then
        playSoundFrontEnd(soundId)
    end
end

-- Map sound names to GTA sound IDs
function getSoundIdForEffect(soundName)
    local soundMap = {
        countdown = 5,    -- Beep
        start = 44,       -- Race start
        finish = 45,      -- Mission complete
        win = 46,         -- Success
        lose = 47,        -- Fail
        kill = 48,        -- Hit
        death = 49,       -- Death
        pickup = 50,      -- Pickup
        checkpoint = 51,  -- Checkpoint
        pm = 52,          -- Message
        notification = 53,-- Notification
        click = 54,       -- Click
        error = 55        -- Error
    }

    return soundMap[soundName]
end

-- Play custom sound from URL or file
function playCustomSound(url, volume, loop)
    volume = volume or sfxVolume

    local sound = playSound(url, loop or false)
    if sound then
        setSoundVolume(sound, volume)
        return sound
    end

    return nil
end

-- Play 3D sound at position
function playSound3DAtPosition(soundPath, x, y, z, volume, maxDistance)
    volume = volume or sfxVolume
    maxDistance = maxDistance or 50

    local sound = playSound3D(soundPath, x, y, z)
    if sound then
        setSoundVolume(sound, volume)
        setSoundMaxDistance(sound, maxDistance)
        return sound
    end

    return nil
end

-- Play background music
function playMusic(url, volume)
    volume = volume or musicVolume

    -- Stop current music
    stopMusic()

    currentMusic = playSound(url, true)
    if currentMusic then
        setSoundVolume(currentMusic, volume)
    end

    return currentMusic
end

-- Stop background music
function stopMusic()
    if currentMusic and isElement(currentMusic) then
        destroyElement(currentMusic)
        currentMusic = nil
    end
end

-- Set music volume
function setMusicVolume(volume)
    musicVolume = math.max(0, math.min(1, volume))
    if currentMusic and isElement(currentMusic) then
        setSoundVolume(currentMusic, musicVolume)
    end
end

-- Set SFX volume
function setSFXVolume(volume)
    sfxVolume = math.max(0, math.min(1, volume))
end

-- Get volumes
function getMusicVolume()
    return musicVolume
end

function getSFXVolume()
    return sfxVolume
end

-- Handle sound events from server
addEvent("weevil:playSound", true)
addEventHandler("weevil:playSound", root, function(soundName)
    playSound(soundName)
end)

addEvent("weevil:playMusic", true)
addEventHandler("weevil:playMusic", root, function(url, volume)
    playMusic(url, volume)
end)

addEvent("weevil:stopMusic", true)
addEventHandler("weevil:stopMusic", root, function()
    stopMusic()
end)

-- Play sounds for game events
addEventHandler("onClientPlayerWasted", localPlayer, function()
    playSound("death")
end)

-- Cleanup on resource stop
addEventHandler("onClientResourceStop", resourceRoot, function()
    stopMusic()
end)

-- Export functions
function exports.weevil_core:playSound(soundName)
    playSound(soundName)
end

function exports.weevil_core:playCustomSound(url, volume, loop)
    return playCustomSound(url, volume, loop)
end

function exports.weevil_core:playMusic(url, volume)
    return playMusic(url, volume)
end

function exports.weevil_core:stopMusic()
    stopMusic()
end

function exports.weevil_core:setMusicVolume(volume)
    setMusicVolume(volume)
end

function exports.weevil_core:setSFXVolume(volume)
    setSFXVolume(volume)
end
