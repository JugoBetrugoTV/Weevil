--[[
    Jebiga Multi-Gamemode - Login GUI
    Client-side login/register interface
]]

local screenW, screenH = guiGetScreenSize()
local isGUIVisible = false
local currentTab = "login" -- login, register
local inputFields = {}
local errorMessage = ""
local successMessage = ""

-- GUI dimensions
local panelW = 400
local panelH = 450
local panelX = (screenW - panelW) / 2
local panelY = (screenH - panelH) / 2

-- Animation
local fadeAlpha = 0
local targetAlpha = 0
local animationSpeed = 0.1

-- Create GUI elements
function createLoginGUI()
    -- Background blur/dim will be rendered

    -- Main panel (rendered with dxDraw)
    inputFields = {
        login = {
            username = { text = "", focused = false, y = 150 },
            password = { text = "", focused = false, y = 210, isPassword = true }
        },
        register = {
            username = { text = "", focused = false, y = 150 },
            password = { text = "", focused = false, y = 210, isPassword = true },
            confirmPassword = { text = "", focused = false, y = 270, isPassword = true },
            email = { text = "", focused = false, y = 330 }
        }
    }
end

-- Show login GUI
function showLoginGUI()
    if isGUIVisible then return end

    isGUIVisible = true
    targetAlpha = 255
    showCursor(true)

    -- Reset fields
    for tab, fields in pairs(inputFields) do
        for name, field in pairs(fields) do
            field.text = ""
            field.focused = false
        end
    end

    errorMessage = ""
    successMessage = ""
end

-- Hide login GUI
function hideLoginGUI()
    if not isGUIVisible then return end

    targetAlpha = 0
    showCursor(false)

    -- Will be hidden after fade out
end

-- Render the GUI
function renderLoginGUI()
    -- Animate alpha
    fadeAlpha = fadeAlpha + (targetAlpha - fadeAlpha) * animationSpeed

    if fadeAlpha < 1 and targetAlpha == 0 then
        isGUIVisible = false
        return
    end

    if not isGUIVisible then return end

    local alpha = math.floor(fadeAlpha)

    -- Background overlay
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, math.floor(alpha * 0.7)))

    -- Main panel
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(30, 30, 30, alpha))

    -- Panel border
    dxDrawRectangle(panelX, panelY, panelW, 5, tocolor(255, 102, 0, alpha))

    -- Logo/Title
    dxDrawText(
        "JEBIGA GAMING",
        panelX, panelY + 20,
        panelX + panelW, panelY + 60,
        tocolor(255, 102, 0, alpha),
        1.5, "default-bold", "center", "center"
    )

    -- Subtitle
    dxDrawText(
        "Multi-Gamemode Server",
        panelX, panelY + 55,
        panelX + panelW, panelY + 80,
        tocolor(180, 180, 180, alpha),
        0.9, "default", "center", "center"
    )

    -- Tab buttons
    local tabY = panelY + 90
    local tabW = (panelW - 30) / 2
    local tabH = 35

    -- Login tab
    local loginTabColor = currentTab == "login" and tocolor(255, 102, 0, alpha) or tocolor(60, 60, 60, alpha)
    dxDrawRectangle(panelX + 10, tabY, tabW, tabH, loginTabColor)
    dxDrawText(
        "LOGIN",
        panelX + 10, tabY,
        panelX + 10 + tabW, tabY + tabH,
        tocolor(255, 255, 255, alpha),
        1.0, "default-bold", "center", "center"
    )

    -- Register tab
    local registerTabColor = currentTab == "register" and tocolor(255, 102, 0, alpha) or tocolor(60, 60, 60, alpha)
    dxDrawRectangle(panelX + 20 + tabW, tabY, tabW, tabH, registerTabColor)
    dxDrawText(
        "REGISTER",
        panelX + 20 + tabW, tabY,
        panelX + 20 + tabW * 2, tabY + tabH,
        tocolor(255, 255, 255, alpha),
        1.0, "default-bold", "center", "center"
    )

    -- Input fields
    local fields = inputFields[currentTab]
    local fieldH = 40
    local fieldX = panelX + 20
    local fieldW = panelW - 40

    for name, field in pairs(fields) do
        local y = panelY + field.y

        -- Field background
        local bgColor = field.focused and tocolor(50, 50, 50, alpha) or tocolor(40, 40, 40, alpha)
        dxDrawRectangle(fieldX, y, fieldW, fieldH, bgColor)

        -- Field border
        local borderColor = field.focused and tocolor(255, 102, 0, alpha) or tocolor(80, 80, 80, alpha)
        dxDrawRectangle(fieldX, y + fieldH - 2, fieldW, 2, borderColor)

        -- Label
        local label = name:gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)
        if name == "confirmPassword" then label = "Confirm Password" end

        dxDrawText(
            label,
            fieldX + 10, y - 20,
            fieldX + fieldW, y,
            tocolor(150, 150, 150, alpha),
            0.85, "default", "left", "center"
        )

        -- Field text
        local displayText = field.text
        if field.isPassword and #displayText > 0 then
            displayText = string.rep("●", #displayText)
        end

        if #displayText == 0 and not field.focused then
            displayText = "Enter " .. label:lower() .. "..."
            dxDrawText(
                displayText,
                fieldX + 10, y,
                fieldX + fieldW - 10, y + fieldH,
                tocolor(100, 100, 100, alpha),
                1.0, "default", "left", "center"
            )
        else
            -- Show cursor if focused
            if field.focused then
                displayText = displayText .. (math.floor(getTickCount() / 500) % 2 == 0 and "|" or "")
            end

            dxDrawText(
                displayText,
                fieldX + 10, y,
                fieldX + fieldW - 10, y + fieldH,
                tocolor(255, 255, 255, alpha),
                1.0, "default", "left", "center"
            )
        end
    end

    -- Error message
    if errorMessage ~= "" then
        dxDrawText(
            errorMessage,
            panelX, panelY + panelH - 100,
            panelX + panelW, panelY + panelH - 80,
            tocolor(255, 80, 80, alpha),
            0.9, "default", "center", "center"
        )
    end

    -- Success message
    if successMessage ~= "" then
        dxDrawText(
            successMessage,
            panelX, panelY + panelH - 100,
            panelX + panelW, panelY + panelH - 80,
            tocolor(80, 255, 80, alpha),
            0.9, "default", "center", "center"
        )
    end

    -- Submit button
    local btnY = panelY + panelH - 70
    local btnH = 45
    local btnText = currentTab == "login" and "LOGIN" or "REGISTER"

    -- Check hover
    local mx, my = getCursorPosition()
    if mx and my then
        mx, my = mx * screenW, my * screenH
    end

    local btnHover = mx and my and mx >= fieldX and mx <= fieldX + fieldW and my >= btnY and my <= btnY + btnH

    local btnColor = btnHover and tocolor(255, 130, 50, alpha) or tocolor(255, 102, 0, alpha)
    dxDrawRectangle(fieldX, btnY, fieldW, btnH, btnColor)
    dxDrawText(
        btnText,
        fieldX, btnY,
        fieldX + fieldW, btnY + btnH,
        tocolor(255, 255, 255, alpha),
        1.2, "default-bold", "center", "center"
    )

    -- Guest button
    if currentTab == "login" then
        dxDrawText(
            "Play as Guest",
            panelX, panelY + panelH - 20,
            panelX + panelW, panelY + panelH,
            tocolor(150, 150, 150, alpha),
            0.8, "default", "center", "center"
        )
    end
end

addEventHandler("onClientRender", root, renderLoginGUI)

-- Handle mouse clicks
function handleLoginClick(button, state, mx, my)
    if button ~= "left" or state ~= "down" then return end
    if not isGUIVisible then return end

    local alpha = fadeAlpha

    -- Tab clicks
    local tabY = panelY + 90
    local tabW = (panelW - 30) / 2
    local tabH = 35

    -- Login tab
    if mx >= panelX + 10 and mx <= panelX + 10 + tabW and my >= tabY and my <= tabY + tabH then
        currentTab = "login"
        errorMessage = ""
        successMessage = ""
        return
    end

    -- Register tab
    if mx >= panelX + 20 + tabW and mx <= panelX + 20 + tabW * 2 and my >= tabY and my <= tabY + tabH then
        currentTab = "register"
        errorMessage = ""
        successMessage = ""
        return
    end

    -- Input field clicks
    local fields = inputFields[currentTab]
    local fieldH = 40
    local fieldX = panelX + 20
    local fieldW = panelW - 40

    -- Unfocus all first
    for _, field in pairs(fields) do
        field.focused = false
    end

    for name, field in pairs(fields) do
        local y = panelY + field.y
        if mx >= fieldX and mx <= fieldX + fieldW and my >= y and my <= y + fieldH then
            field.focused = true
            return
        end
    end

    -- Submit button click
    local btnY = panelY + panelH - 70
    local btnH = 45

    if mx >= fieldX and mx <= fieldX + fieldW and my >= btnY and my <= btnY + btnH then
        submitForm()
        return
    end

    -- Guest button click
    if currentTab == "login" then
        if mx >= panelX and mx <= panelX + panelW and my >= panelY + panelH - 25 and my <= panelY + panelH then
            hideLoginGUI()
            -- Play as guest
            outputChatBox("#FFFF00[Jebiga] #FFFFFFPlaying as guest. Use /register to save your progress!", 255, 255, 255, true)
            return
        end
    end
end

addEventHandler("onClientClick", root, handleLoginClick)

-- Handle keyboard input
function handleLoginKey(button, press)
    if not isGUIVisible or not press then return end

    local fields = inputFields[currentTab]

    -- Find focused field
    local focusedField = nil
    local focusedName = nil
    for name, field in pairs(fields) do
        if field.focused then
            focusedField = field
            focusedName = name
            break
        end
    end

    if button == "backspace" and focusedField then
        focusedField.text = focusedField.text:sub(1, -2)
    elseif button == "enter" then
        submitForm()
    elseif button == "tab" then
        -- Move to next field
        local fieldOrder = currentTab == "login"
            and { "username", "password" }
            or { "username", "password", "confirmPassword", "email" }

        for i, name in ipairs(fieldOrder) do
            if name == focusedName then
                fields[name].focused = false
                local nextName = fieldOrder[i + 1] or fieldOrder[1]
                fields[nextName].focused = true
                break
            end
        end
    elseif button == "escape" then
        hideLoginGUI()
    end
end

addEventHandler("onClientKey", root, handleLoginKey)

-- Handle character input
function handleLoginCharacter(char)
    if not isGUIVisible then return end

    local fields = inputFields[currentTab]

    for name, field in pairs(fields) do
        if field.focused then
            -- Limit length
            if #field.text < 50 then
                field.text = field.text .. char
            end
            break
        end
    end
end

addEventHandler("onClientCharacter", root, handleLoginCharacter)

-- Submit form
function submitForm()
    errorMessage = ""
    successMessage = ""

    local fields = inputFields[currentTab]

    if currentTab == "login" then
        local username = fields.username.text
        local password = fields.password.text

        if username == "" then
            errorMessage = "Please enter a username"
            return
        end

        if password == "" then
            errorMessage = "Please enter a password"
            return
        end

        -- Send login request
        triggerServerEvent("jebiga:account:requestLogin", localPlayer, username, password)

    else -- register
        local username = fields.username.text
        local password = fields.password.text
        local confirmPassword = fields.confirmPassword.text
        local email = fields.email.text

        if username == "" then
            errorMessage = "Please enter a username"
            return
        end

        if #username < 3 then
            errorMessage = "Username must be at least 3 characters"
            return
        end

        if password == "" then
            errorMessage = "Please enter a password"
            return
        end

        if #password < 6 then
            errorMessage = "Password must be at least 6 characters"
            return
        end

        if password ~= confirmPassword then
            errorMessage = "Passwords do not match"
            return
        end

        -- Send register request
        triggerServerEvent("jebiga:account:requestRegister", localPlayer, username, password, email)
    end
end

-- Handle server responses
addEvent("jebiga:account:loginSuccess", true)
addEventHandler("jebiga:account:loginSuccess", root, function(data)
    local message = type(data) == "string" and data or "Login successful!"
    successMessage = message
    hideLoginGUI()
    outputChatBox("#00FF00[Jebiga] #FFFFFF" .. message, 255, 255, 255, true)
end)

addEvent("jebiga:account:loginFailed", true)
addEventHandler("jebiga:account:loginFailed", root, function(message)
    errorMessage = message or "Login failed"
end)

addEvent("jebiga:account:registerSuccess", true)
addEventHandler("jebiga:account:registerSuccess", root, function(message)
    successMessage = message or "Registration successful!"
    currentTab = "login" -- Switch to login tab
    outputChatBox("#00FF00[Jebiga] #FFFFFF" .. (message or "Account created!"), 255, 255, 255, true)
end)

addEvent("jebiga:account:registerFailed", true)
addEventHandler("jebiga:account:registerFailed", root, function(message)
    errorMessage = message or "Registration failed"
end)

addEvent("jebiga:account:logout", true)
addEventHandler("jebiga:account:logout", root, function(message)
    outputChatBox("#FFFF00[Jebiga] #FFFFFF" .. (message or "Logged out"), 255, 255, 255, true)
    showLoginGUI()
end)

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    createLoginGUI()

    -- Show login GUI on join
    setTimer(function()
        local loggedIn = getElementData(localPlayer, "jebiga:loggedIn")
        if not loggedIn then
            showLoginGUI()
        end
    end, 1500, 1)
end)

-- Command to show login
addCommandHandler("loginpanel", function()
    if isGUIVisible then
        hideLoginGUI()
    else
        showLoginGUI()
    end
end)

-- Also allow /account command
addCommandHandler("account", function()
    if isGUIVisible then
        hideLoginGUI()
    else
        showLoginGUI()
    end
end)

-- Show on player spawn if not logged in
addEventHandler("onClientPlayerSpawn", localPlayer, function()
    setTimer(function()
        local loggedIn = getElementData(localPlayer, "jebiga:loggedIn")
        if not loggedIn and not isGUIVisible then
            showLoginGUI()
        end
    end, 500, 1)
end)

-- Export functions
function isLoginGUIVisible()
    return isGUIVisible
end
