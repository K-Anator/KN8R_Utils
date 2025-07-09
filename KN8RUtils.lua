-- K-Anator's Utilities // A monolithic mess of a class to help out the RLS servers.
---- Config ----
local debugOutput = false -- set to false to hide console printed information
local timerLength = 5 -- How many seconds to countdown by default
local timerMargin = 2500 -- Margin in milliseconds between 1 and "GO!"
local leaderboardPath = "Resources/KN8R_Utils/UserStats/" -- Directory to store leaderboard data, include trailing "/"
local roleList = "Resources/KN8R_Utils/roles.json" -- "Resources/KN8R_Utils/roles.json"
local blackList = "Resources/KN8R_Utils/bans.json" -- "Resources/KN8R_Utils/bans.json"
---- Not Config ----
local commandPrefix = "!"
local countdownIsActive = false
local timer = timerLength
local currentBans = {
    users = {}
}
local currentRoles = {
    users = {}
}
local currentUsers = {}
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
    MP.RegisterEvent("raceBegin", "raceBegin")
    MP.RegisterEvent("raceCheckpoint", "raceCheckpoint")
    MP.RegisterEvent("raceFinishLap", "raceFinishLap")
    MP.RegisterEvent("raceEnd", "raceEnd")
    MP.RegisterEvent("raceLapInvalidated", "raceLapInvalidated")
    MP.RegisterEvent("racePitEnter", "racePitEnter")
    MP.RegisterEvent("racePitExit", "racePitExit")
    -- FRE:Leaderboards
    MP.RegisterEvent("loadRaceLeaderboard", "loadRaceLeaderboard")
    MP.RegisterEvent("saveRaceLeaderboard", "saveRaceLeaderboard")
    MP.RegisterEvent("getLeaderboard", "getLeaderboard")
    -- KN8RUtils
    MP.RegisterEvent("countdownTimer", "countdownTimer")
    MP.RegisterEvent("MP_hideVehicles", "MP_hideVehicles")
    MP.RegisterEvent("kickUser", "kickUser") -- potential use via clientside UI
    -- MP.RegisterEvent("banUser", "banUser") -- potential use via clientside UI
    -- MP.RegisterEvent("getPlayerRole", "getPlayerRole")
    MP.RegisterEvent("playerAction", "playerAction")

    print("K-Anator's Utilities Loading!")
    loadBanList()
    loadRolesList()
    print("K-Anator's Utilities Ready!")
end

------------------------------BEAMP BOILERPLATE------------------------------

-- A player has authenticated and is requesting to join
-- The player's name (string), forum role (string), guest account (bool), identifiers (table -> ip, beammp)
function onPlayerAuth(player_name, role, isGuest, identifiers)
    for i, v in ipairs(currentBans.users) do
        if tonumber(identifiers.beammp) == tonumber(v.beammp) then
            print("User matched banlist, disconnecting.")
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

-- A player is loading in (Before loading the map)
-- The player's ID (number)
function onPlayerConnecting(player_id)
    if debugOutput then
        print("onPlayerConnecting: player_id: " .. player_id)
    end
end

-- A player is loading the map and will be joined soon
-- The player's ID (number)
function onPlayerJoining(player_id)
    if debugOutput then
        print("onPlayerJoining: player_id: " .. player_id)
    end
end

-- A player has joined and loaded in
-- The player's ID (number)
function onPlayerJoin(player_id)
    if debugOutput then
        print("onPlayerJoin: player_id: " .. player_id)
    end
    currentUsers[player_id] = getPlayerRole(player_id)
    print(currentUsers)
    -- MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " has joined the server!")
    sendLeaderboard(player_id)
end

-- A player has disconnected
-- The player's ID (number)
function onPlayerDisconnect(player_id)
    if debugOutput then
        print("onPlayerDisconnect: player_id: " .. player_id)
    end
    currentUsers[player_id] = nil
    -- MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " has left the server!")
end

-- A chat message was sent
-- The sender's ID, the sender's name, and the chat message
function onChatMessage(player_id, player_name, message)
    if debugOutput then
        print("onChatMessage: player_id: " .. player_id .. " | player_name: " .. player_name .. " | Message: " ..
                  message)
    end

    if message:sub(1, 1) == commandPrefix then -- if the character at index 1 of the string is the command prefix then
        command = string.sub(message, 2) -- the command is everything in the chat message from string index 2 to the end of the string
        onCommand(player_id, command) -- call the onCommand() function passing in the player's ID and the command string
        return 1 -- prevent the command from showing up in the chat
    else -- otherwise do nothing
    end
end

-- This is called when someone spawns a vehicle
-- The player's ID (number), the vehicle ID (number), and the vehicle data (table)
function onVehicleSpawn(player_id, vehicle_id, data)
    local player_name = MP.GetPlayerName(player_id)
    if debugOutput then
        print("onVehicleSpawn: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
        print("data:")
        print(data)
    end
    MP.TriggerClientEvent(player_id, "updateConfig", player_name)
end

-- This is called when someone edits a vehicle, or replaces their existing one
-- The player's ID (number), the vehicle ID (number), and the vehicle data (table)
function onVehicleEdited(player_id, vehicle_id, data)
    local player_name = MP.GetPlayerName(player_id)
    if debugOutput then
        print("onVehicleEdited: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
        print("data:")
        print(data)
    end
    MP.TriggerClientEvent(player_id, "updateConfig", player_name)
end

-- This is called when someone resets a vehicle
-- The player's ID (number), the vehicle ID (number), and the vehicle data (table)
function onVehicleReset(player_id, vehicle_id, data)
    local player_name = MP.GetPlayerName(player_id)
    if debugOutput then
        print("onVehicleReset: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
        print("data:")
        print(data)
    end
end

-- This is called when someone deletes a vehicle they own
-- The player's ID (number) and the vehicle ID (number)
function onVehicleDeleted(player_id, vehicle_id)
    if debugOutput then
        print("onVehicleDeleted: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
    end
end

------------------------------CRAP K-ANATOR WROTE------------------------------

function raceBegin(player_id, data) -- Triggered when a player starts a race | data = trackname
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local trackname = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " started: " .. trackname .. "!")
    end
end

function raceCheckpoint(player_id, data) -- Triggered when a player hits a checkpoint | data = checkpoint index
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local checkpoint = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " went through checkpoint: " .. checkpoint .. "!")
    end
end

function raceFinishLap(player_id, data) -- Triggered when a player finishes a lap | data = lap index
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " completed lap: " .. lap .. "!")
    end
    for ID, permissions in pairs(currentUsers) do
        if permissions >= 2 then
            MP.SendChatMessage(ID, player_name .. " completed lap: " .. lap .. "!")
        end
    end
    -- MP.SendChatMessage(-1, player_name .. " completed lap: " .. lap .. "!")
end

function raceEnd(player_id, data) -- Triggered when a player completes a race | data = trackname
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local trackname = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " completed: " .. trackname .. "!")
    end
end

function raceLapInvalidated(player_id, data) -- Triggered when a player invalidates their lap | data = number of missed checkpoints
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local missedcheckpoints = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. "  missed " .. missedcheckpoints .. " checkpoints!")
    end
end

function racePitEnter(player_id, data) -- Triggered when a player enters the pits | data = lap entered on (+1 because first lap is lap 0)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " entered pit on: " .. lap + 1 .. "!")
    end
end

function racePitExit(player_id, data) -- Triggered when a player exits the pits | data = lap exited (+1 because first lap is lap 0)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " exited pit on: " .. lap + 1 .. "!")
    end
end

function sendLeaderboard(player_id)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    print(player_name .. " is requesting their leaderboard.")

    local leaderboardFile = leaderboardPath .. beammp .. ".json"
    if not FS.IsFile(leaderboardFile) then
        print("Stats for " .. player_name .. " don't exist, wait for them to be uploaded")
        return
    end
    local file = io.open(leaderboardFile, "r")
    local leaderboardData = file:read "a"
    io.close(file)
    if leaderboardData then
        print("Sending " .. player_name .. " leaderboard." .. leaderboardData)
        MP.TriggerClientEvent(player_id, "retrieveServerLeaderboard", leaderboardData)
    else
        print("Leaderboard data was empty for some reason, not sending")
    end
end

function getLeaderboard(player_id, data)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp
    local leaderboardData = data
    local leaderboardFile = leaderboardPath .. beammp .. ".json"

    print("Player: " .. player_name .. " wants to update their leaderboard")
    print(leaderboardData)

    local file = io.open(leaderboardFile, "w+")
    file:write(leaderboardData)
    file:close()

    print("Leaderboard received from " .. player_name)
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

function getPlayerRole(player_id) -- Returns permission level based on player_id
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp
    for k, v in pairs(currentRoles.users) do
        if tonumber(v.beammp) == tonumber(beammp) then
            return v.permissions
        end
        return 0
    end
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

local function raceJoin(player_id)
    local player_name = MP.GetPlayerName(player_id)
    print(player_name .. " has accepted the race!")
    currentRacers[player_id] = MP.GetPlayerIdentifiers(player_id).beammp
end

function playerAction(player_id, data)
    local permissions = tonumber(getPlayerRole(player_id))
    if permissions < 3 then
        return
    end
    local parsedData = Util.JsonDecode(data)
    local actionedID = getPlayerByName(parsedData.playerName)
    local actionedPerms = getPlayerRole(actionedID)
    if parsedData.action == "kick" then
        if permissions > actionedPerms then
            kickUser(parsedData.playerName, parsedData.reason)
        end
    elseif parsedData.action == "ban" then
        if permissions > actionedPerms then
            banUser(parsedData.playerName, parsedData.reason, MP.GetPlayerName(player_id))
        end
    end
end

function raceGrid()
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
    if debugOutput then
        print("onCommand: player_id: " .. player_id .. " | command: " .. command)
        print("args:")
        print(args)
    end
    ---- "!start [time]" Starts a race countdown with the given arguement if it has one.
    if command == "start" and not countdownIsActive then
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
    end
    ---- "!ban [player_name] [Reason]"
    if command == "ban" then
        if tonumber(getPlayerRole(player_id)) >= 2 then
            local name = args[1]
            local reason = ""
            for k, v in pairs(args) do
                if k > 1 then -- add args beyond the username to the reason
                    reason = tostring(reason) .. v .. " "
                end
            end
            banUser(name, reason, MP.GetPlayerName(player_id))
            MP.SendChatMessage(player_id, "Your ban was successful!")
            return
        else
            MP.SendChatMessage(player_id, "You do not have permission to send this command!")
            return
        end
    end
    if command == "kick" then
        if tonumber(getPlayerRole(player_id)) >= 2 then
            local name = args[1]
            local reason = ""
            for k, v in pairs(args) do
                if k > 1 then -- add args beyond the username to the reason
                    reason = tostring(reason) .. v .. " "
                end
            end
            kickUser(name, reason)
            MP.SendChatMessage(player_id, "Your kick was successful!")
            return
        else
            MP.SendChatMessage(player_id, "You do not have permission to send this command!")
            return
        end
    end
    ---- !test ----
    if command == "test" then
        print("Test message")
        for ID, permissions in pairs(currentUsers) do
            if tonumber(permissions) >= 2 then
                MP.SendChatMessage(ID, " completed test message!")
            end
        end
    end

    if command == "hideme" then
        print("Hiding vehicle")
        local vehicles = ""
        local player_vehicles = MP.GetPlayerVehicles(player_id)

        for vehicle_id, vehicle_data in pairs(player_vehicles) do
            local start = string.find(vehicle_data, "{")
            local formattedVehicleData = string.sub(vehicle_data, start, -1)
            local vehicleData = Util.JsonDecode(formattedVehicleData)
            vehicles = vehicles .. vehicleData.vid .. ","
        end
        MP.TriggerClientEvent(-1, "MP_hideVehicles", vehicles)
        print(vehicles)
    end

    if command == "hideothers" then
        MP.TriggerClientEvent(player_id, "hideOthers", "please")
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
