-- K-Anator's Utilities // A monolithic mess of a class to help out the RLS servers.

----Config----
local commandPrefix = "!" -- prefix used to identify commands entered through chat
local debugOutput = false -- set to false to hide console printed information
local timerLength = 5 -- How many seconds to countdown
local timerMargin = 4000 -- Margin in milliseconds between 1 and "GO!"
local leaderboardPath = "Resources/KN8R_Utils/UserStats/" -- Directory to store leaderboard data, include trailing "/"
local roleList = "Resources/KN8R_Utils/roles.json" -- "Resources/KN8R_Utils/roles.json"
local blackList = "Resources/KN8R_Utils/bans.json" -- "Resources/KN8R_Utils/bans.json"
----Not Config----
local countdownIsActive = false
local timer

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

    -- Custom
    MP.RegisterEvent("raceBegin", "raceBegin")
    MP.RegisterEvent("raceCheckpoint", "raceCheckpoint")
    MP.RegisterEvent("raceFinishLap", "raceFinishLap")
    MP.RegisterEvent("raceEnd", "raceEnd")
    MP.RegisterEvent("raceLapInvalidated", "raceLapInvalidated")
    MP.RegisterEvent("racePitEnter", "racePitEnter")
    MP.RegisterEvent("racePitExit", "racePitExit")
    MP.RegisterEvent("loadRaceLeaderboard", "loadRaceLeaderboard")
    MP.RegisterEvent("saveRaceLeaderboard", "saveRaceLeaderboard")
    MP.RegisterEvent("getLeaderboard", "getLeaderboard")
    MP.RegisterEvent("countdownTimer", "countdownTimer")

    print("K-Anator's Utilities Loaded!")
end

------------------------------BEAMP BOILERPLATE------------------------------

-- A player has authenticated and is requesting to join
-- The player's name (string), forum role (string), guest account (bool), identifiers (table -> ip, beammp)
function onPlayerAuth(player_name, role, isGuest, identifiers)
    if player_name == "USERNAME" then
        return "You cannot connect to this server due to performance issues."
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
    -- MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " has joined the server!")
    sendLeaderboard(player_id)
end

-- A player has disconnected
-- The player's ID (number)
function onPlayerDisconnect(player_id)
    if debugOutput then
        print("onPlayerDisconnect: player_id: " .. player_id)
    end
    MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " has left the server!")
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
    MP.SendChatMessage(-1, player_name .. " completed lap: " .. lap .. "!")
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
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
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
        MP.SendChatMessage(-1, tostring(timer + 1))
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
    else
        print("Timer already active, cancelling.")
        MP.SendChatMessage(player_id, "Countdown is currently active!")
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
