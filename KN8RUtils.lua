-- K-Anator's Utilities // A monolithic mess of a class to help out the RLS servers.
---- Config ----
local debugCommands = false -- set to false to disable commands not fully implemented
local timerLength = 5 -- How many seconds to countdown by default
local timerMargin = 2500 -- Margin in milliseconds between 1 and "GO!"
local leaderboardPath = "Resources/KN8R_Utils/UserStats/" -- Directory to store leaderboard data, include trailing "/"
local roleList = "Resources/KN8R_Utils/roles.json" -- "Resources/KN8R_Utils/roles.json"
local blackList = "Resources/KN8R_Utils/bans.json" -- "Resources/KN8R_Utils/bans.json"
local showEventMessages = true
---- Not Config ----
local commandPrefix = "!"
local countdownIsActive = false
local isEventmode = false -- use to disable spawning vehicles for users with perm 0
local timer = timerLength
local currentBans = {
    users = {}
}
local currentRoles = {
    users = {}
}
local currentUsers = {
    users = {}
}
local currentRacers = {}

function onInit() -- runs when plugin is loaded

    -- Provided by BeamMP
    MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
    MP.RegisterEvent("onPlayerConnecting", "onPlayerConnecting")
    MP.RegisterEvent("onPlayerJoining", "onPlayerJoining")
    MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
    MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
    MP.RegisterEvent("onChatMessage", "onChatMessage")
    MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
    MP.RegisterEvent("onVehicleEdited", "onVehicleEdited")
    MP.RegisterEvent("onVehicleReset", "onVehicleReset")
    MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
    -- FRE:KN8R
    MP.RegisterEvent("playerBegin", "playerBegin")
    MP.RegisterEvent("playerCheckpoint", "playerCheckpoint")
    MP.RegisterEvent("playerFinishLap", "playerFinishLap")
    MP.RegisterEvent("playerEnd", "playerEnd")
    MP.RegisterEvent("playerLapInvalidated", "playerLapInvalidated")
    MP.RegisterEvent("playerPitEnter", "playerPitEnter")
    MP.RegisterEvent("playerPitExit", "playerPitExit")
    -- FRE:Leaderboards
    MP.RegisterEvent("loadRaceLeaderboard", "loadRaceLeaderboard")
    MP.RegisterEvent("saveRaceLeaderboard", "saveRaceLeaderboard")
    MP.RegisterEvent("getLeaderboard", "getLeaderboard")
    -- FRE:MPEvents
    -- MP.RegisterEvent("MP_hideVehicles", "MPhideVehicles")
    -- MP.RegisterEvent("MP_hideVehicle", "MPhideVehicle")
    MP.RegisterEvent("playerAction", "playerAction")
    -- KN8RUtils
    MP.RegisterEvent("getPlayerRole", "getPlayerRole")
    MP.RegisterEvent("countdownTimer", "countdownTimer")
    MP.RegisterEvent("addModButtons", "addModButtons")

    print("K-Anator's Utilities Loading!")
    loadBanList()
    loadRolesList()
    print("K-Anator's Utilities Ready!")
end

------------------------------BEAMP BOILERPLATE------------------------------

function onPlayerAuth(player_name, role, isGuest, identifiers)
    for i, v in ipairs(currentBans.users) do
        if tonumber(identifiers.beammp) == tonumber(v.beammp) then
            local message = "Sorry " .. player_name .. ", you were banned by " .. v.bannedby ..
                                " for the following reason: \"" .. v.reason ..
                                "\" Please post a screenshot of this dialogue along with your appeal on Discord." ..
                                " BeamMPID: " .. v.beammp
            return tostring(message)
        end
    end
    if isGuest then
        return "No guests allowed, please use a BeamMP account."
    end
end

function onPlayerConnecting(player_id)
    currentUsers.users[player_id] = {
        permissions = getPlayerRole(player_id),
        isHidden = false,
        isRacing = false
    }
end

function onPlayerJoining(player_id)
end

function onPlayerJoin(player_id)
    sendLeaderboard(player_id)
    local permissions = getPlayerRole(player_id)
    if tonumber(permissions) > 2 then

        MP.TriggerClientEvent(player_id, "addModButtons", "please")
    end
end

function onPlayerDisconnect(player_id)
    currentUsers[player_id] = nil
end

function onChatMessage(player_id, player_name, message)
    if message:sub(1, 1) == commandPrefix then -- if the character at index 1 of the string is the command prefix then
        command = string.sub(message, 2) -- the command is everything in the chat message from string index 2 to the end of the string
        onCommand(player_id, command) -- call the onCommand() function passing in the player's ID and the command string
        return 1 -- prevent the command from showing up in the chat
    else -- otherwise do nothing
    end
end

function onVehicleSpawn(player_id, vehicle_id, data)
    local player_name = MP.GetPlayerName(player_id)
    if isEventmode then
        MP.SendChatMessage(player_id, "Sorry, you cannot spawn a vehicle right now.")
        return 1
    end
    MP.TriggerClientEvent(player_id, "updateConfig", player_name)
end

function onVehicleEdited(player_id, vehicle_id, data)
    local player_name = MP.GetPlayerName(player_id)
    if isEventmode then
        MP.SendChatMessage(player_id, "Sorry, you cannot edit your vehicle right now.")
        return 1
    end
    MP.TriggerClientEvent(player_id, "updateConfig", player_name)
end

function onVehicleReset(player_id, vehicle_id, data)
    local player_name = MP.GetPlayerName(player_id)
    if not showEventMessages then
        return
    end
    for ID, permissions in ipairs(currentUsers.users) do
        if tonumber(permissions) >= 2 then
            MP.SendChatMessage(ID, player_name .. " reset their vehicle!")
        end
    end
end

function onVehicleDeleted(player_id, vehicle_id)
end

------------------------------CRAP K-ANATOR WROTE------------------------------

function playerBegin(player_id, data) -- Triggered when a player starts a race | data = trackname
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local trackname = data
    if not showEventMessages then
        return
    end
    for ID, permissions in pairs(currentUsers.users) do
        if tonumber(permissions) >= 2 then
            MP.SendChatMessage(ID, player_name .. " started " .. trackname .. "!")
        end
    end
end

function playerCheckpoint(player_id, data) -- Triggered when a player hits a checkpoint | data = checkpoint index
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local checkpoint = data
    if not showEventMessages then
        return
    end
end

function playerFinishLap(player_id, data) -- Triggered when a player finishes a lap | data = lap index
    local raceData = Util.JsonDecode(data)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local track = raceData[0]
    local lap = raceData[1]
    if not showEventMessages then
        return
    end
    for ID, permissions in pairs(currentUsers.users) do
        if tonumber(permissions) >= 2 then
            MP.SendChatMessage(ID, player_name .. " completed lap: " .. lap .. " of " .. track)
        end
    end
    -- MP.SendChatMessage(-1, player_name .. " completed lap: " .. lap .. "!")
end

function playerEnd(player_id, data) -- Triggered when a player completes a race | data = trackname
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local trackname = data
    if not showEventMessages then
        return
    end
    for ID, permissions in pairs(currentUsers.users) do
        if tonumber(permissions) >= 2 then
            MP.SendChatMessage(ID, player_name .. " finished " .. trackname .. "!")
        end
    end
end

function playerLapInvalidated(player_id, data) -- Triggered when a player invalidates their lap | data = number of missed checkpoints
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local missedcheckpoints = data
    if not showEventMessages then
        return
    end
    for ID, permissions in pairs(currentUsers.users) do
        if tonumber(permissions) >= 2 then
            MP.SendChatMessage(ID, player_name .. " missed " .. missedcheckpoints .. " checkpoints!")
        end
    end
end

function playerPitEnter(player_id, data) -- Triggered when a player enters the pits | data = lap entered on (+1 because first lap is lap 0)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data
    if not showEventMessages then
        return
    end
end

function playerPitExit(player_id, data) -- Triggered when a player exits the pits | data = lap exited (+1 because first lap is lap 0)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data
    if not showEventMessages then
        return
    end
end

function sendLeaderboard(player_id)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local leaderboardFile = leaderboardPath .. beammp .. ".json"
    if not FS.IsFile(leaderboardFile) then
        return
    end
    local file = io.open(leaderboardFile, "r")
    local leaderboardData = file:read "a"
    io.close(file)
    if leaderboardData then
        MP.TriggerClientEvent(player_id, "retrieveServerLeaderboard", leaderboardData)
    end
end

function getLeaderboard(player_id, data)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp
    local leaderboardData = data
    local leaderboardFile = leaderboardPath .. beammp .. ".json"
    local file = io.open(leaderboardFile, "w+")
    file:write(leaderboardData)
    file:close()
end

function countdownTimer(timerLength)
    countdownIsActive = true
    timer = timer - 1
    if timer > -1 then
        MP.SendChatMessage(-1, tostring(timer + 1) .. "...")
    end
    if timer == -1 then
        MP.Sleep(Util.RandomIntRange(0, timerMargin))
        MP.SendChatMessage(-1, "GREEN! GREEN! GREEN!")
        MP.CancelEventTimer("countdownTimer")
        countdownIsActive = false
    end
    if timer < -1 or nil then
        MP.CancelEventTimer("countdownTimer")
        countdownIsActive = false
    end
end

function getPlayerByName(name) -- Returns player_id based on their current username
    local players = MP.GetPlayers()
    for k, v in pairs(players) do
        if v == name then
            return k, v
        end
    end
end

function getPlayerRole(player_id) -- Returns permissions level based on player_id
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp
    local permissions
    for k, v in ipairs(currentRoles.users) do
        if tonumber(v.beammp) == tonumber(beammp) then
            permissions = v.permissions
            return v.permissions
        end
    end
    if permissions == nil then
        return 0
    end
end

function getPlayerVehicleIDs(player_id) -- returns a table of (server) vehicle IDs based on player_id
    local vehicles = {}
    local player_vehicles = MP.GetPlayerVehicles(player_id)

    for vehicle_id, vehicle_data in pairs(player_vehicles) do
        local start = string.find(vehicle_data, "{")
        local formattedVehicleData = string.sub(vehicle_data, start, -1)
        local vehicleData = Util.JsonDecode(formattedVehicleData)
        table.insert(vehicles, vehicleData.vid)
    end
    return vehicles
end

function loadBanList()
    local file = io.open(blackList, "r+")
    local blackListData = file:read "a"
    if blackListData == "" then
        print("No users were found in blacklist!")
        io.close(file)
        currentBans = {
            users = {}
        }
        return
    end
    currentBans = Util.JsonDecode(blackListData)
    print("Bans loaded for " .. #currentBans.users .. " user(s)")
    io.close(file)
    return
end

function loadRolesList()
    local file = io.open(roleList, "r+")
    local roleListData = file:read "a"
    if currentRoles == "" then
        print("No roles were loaded!")
        io.close(file)
        currentRoles = {
            users = {}
        }
        return
    end
    currentRoles = Util.JsonDecode(roleListData)
    print("Roles loaded for " .. #currentRoles.users .. " user(s)")
    io.close(file)
end

-- delete a player's vehicles by their name
local function deletePlayerVehicles(name)
    local player_id = getPlayerByName(name)
    local player_vehicles = MP.GetPlayerVehicles(player_id)
    for vehicle_id, vehicle_data in pairs(player_vehicles) do
        MP.RemoveVehicle(player_id, vehicle_id)
    end
end

-- Kick a user by their name
local function kickUser(name, reason)
    local player_id = getPlayerByName(name)
    MP.DropPlayer(player_id, "You were kicked for: " .. reason)
    return 1
end

-- Ban a user by their name
local function banUser(name, reason, bannedby)
    print(bannedby .. " has banned " .. name .. " for: \"" .. reason .. "\"")
    local player_id = getPlayerByName(name)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp
    local bannedUser = {
        beammp = beammp,
        bannedby = bannedby,
        reason = reason
    }
    table.insert(currentBans.users, bannedUser)
    local banData = Util.JsonEncode(currentBans)
    local file = io.open(blackList, "w+")
    file:write(banData)
    file:close()
    kickUser(name, reason)
end

local function toggleEventMode(bool)
    if bool then
        isEventmode = bool
    else
        isEventmode = not isEventmode
    end
    return isEventmode
end

local function raceJoin(player_id)
    local player_name = MP.GetPlayerName(player_id)
    -- print(player_name .. " has accepted the race!")
    currentRacers[player_id] = MP.GetPlayerIdentifiers(player_id).beammp
    -- send this data to the person that initiated the race
end

function playerAction(player_id, data)
    local permissions = tonumber(getPlayerRole(player_id))
    local parsedData = Util.JsonDecode(data)
    local actionedID = getPlayerByName(parsedData.playerName)
    local actionedPerms = getPlayerRole(actionedID)
    -- Commands for "Drivers" | 1 or higher

    -- Commands for "Mods" | 2 or higher
    if parsedData.action == "kick" and permissions >= 2 then
        if permissions > actionedPerms then
            kickUser(parsedData.playerName, parsedData.reason)
            MP.SendChatMessage(player_id, "You kicked " .. parsedData.playerName)
            return
        else
            MP.SendChatMessage(player_id, "You can't kick someone with an equal or greater role than you!")
            return
        end
    elseif parsedData.action == "ban" and permissions >= 2 then
        if permissions > actionedPerms then
            banUser(parsedData.playerName, parsedData.reason, MP.GetPlayerName(player_id))
            MP.SendChatMessage(player_id, "You banned " .. parsedData.playerName)
            return
        else
            MP.SendChatMessage(player_id, "You can't ban someone with an equal or greater role than you!")
        end
    elseif parsedData.action == "delete" and permissions >= 2 then
        if permissions > actionedPerms then
            deletePlayerVehicles(parsedData.playerName)
        else
            MP.SendChatMessage(player_id, "You can't delete someone's vehicles with an equal or greater role than you!")
        end
    elseif parsedData.action == "queuerace" and permissions >= 2 then
        -- Race was initiated, show all players vote dialogue
    elseif parsedData.action == "startrace" and permissions >= 2 then
        -- Race was started, do race related stuff
    end

    -- Commands for "Admins" | 3

end

function raceGrid()
    -- place players on grid based on best times
end

function raceStart()
    -- start the race
end

function onCommand(player_id, data)
    local data = split(data)
    local command = data[1] -- get the command from the data
    local args = {} -- initialize an arguments table
    if data[2] then -- if there is at least one argument
        local argIndex = 1
        for dataIndex = 2, #data do
            args[argIndex] = data[dataIndex]
            argIndex = argIndex + 1
        end
    end
    local permissions = tonumber(getPlayerRole(player_id))

    ---- "!start [time]" Starts a race countdown with the given arguement if it has one.
    if command == "start" and not countdownIsActive and not isEventmode then
        if args[1] then
            timer = tonumber(args[1])
        else
            timer = timerLength
        end
        MP.SendChatMessage(-1, "Drivers ready!")
        MP.CreateEventTimer("countdownTimer", 1000)
    elseif command == "start" and countdownIsActive then
        MP.SendChatMessage(player_id, "Countdown is currently active!")
        return 1
    elseif command == "start" and isEventmode then
        MP.SendChatMessage(player_id, "You can't start a countdown during an event!")
        return 1
    end

    ---- !test ----
    if command == "test" then
        local randInt = Util.RandomIntRange(1, 50)
        if randInt == 42 then
            MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " found an easter egg!")
        elseif randInt == 4 then
            MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " thinks they're funny")
        elseif randInt == 36 then
            MP.SendChatMessage(player_id, MP.GetPlayerName(player_id) .. ", you are breaking the car!")
        elseif randInt == 26 then
            MP.SendChatMessage(player_id, "Don't test me!")
        end
        -- print(currentUsers)
        -- toggleEventMode()
        return 1
    end

    if command == "event" then
        if getPlayerRole(player_id) >= 2 then
            toggleEventMode()
            MP.SendChatMessage(player_id, "Set event mode to: " .. tostring(isEventmode))
            return 1
        elseif getPlayerRole(player_id) < 2 or nil then
            MP.SendChatMessage(player_id, "You do not have permission to send this command!")
        end
    end

    -- "!race [raceName] [laps]"
    if command == "race" then
        if not debugCommands then
            MP.SendChatMessage(player_id, "Command not implemented")
            return 1
        end
        local raceName = args[1]
        local lapCount = args[2]
        return 1
    end

    -- "!hideme" Hide the players vehicle from everyone
    if command == "hideme" then
        if not debugCommands then
            MP.SendChatMessage(player_id, "Command not implemented")
            return 1
        end
        local playername = MP.GetPlayerName(player_id)
        currentUsers[player_id].isHidden = true
        print("Hiding " .. playername .. "'s vehicle(s) from everyone")
        local players = MP.GetPlayers()
        for k, v in pairs(players) do
            if not v == playername then
                print("Telling " .. v .. " not to hide cars")
            else
                print("Telling " .. v .. " to hide cars")
                MP.TriggerClientEvent(getPlayerByName(v), "MP_hideVehicle", playername)
            end
        end
        return 1
    end

    -- "!hideothers" Hide everyone from this player
    if command == "hideothers" then
        if not debugCommands then
            MP.SendChatMessage(player_id, "Command not implemented")
            return 1
        end
        print("Hiding everyone's vehicles from " .. MP.GetPlayerName(player_id))
        MP.TriggerClientEvent(player_id, "MP_hideVehicles")
        return 1
    end

    -- "!showme" Show this player to everyone, if hidden
    if command == "showme" then
        if not debugCommands then
            MP.SendChatMessage(player_id, "Command not implemented")
            return 1
        end
        MP.TriggerClientEvent(-1, "MP_showVehicle")
        return 1
    end

    -- "!showothers" Show every vehicle to this player that wants to be seen
    if command == "showothers" then
        if not debugCommands then
            MP.SendChatMessage(player_id, "Command not implemented")
            return 1
        end
        MP.TriggerClientEvent(player_id, "MP_showVehicles", tostring(vehicles))
        return 1
    end
end

-- function for splitting strings by a separator into a table
function split(str, sep)
    local sep = sep or " "
    local t = {}
    for str in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end
