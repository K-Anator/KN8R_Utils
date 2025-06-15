-- K-Anator's Utilities.
-- json = require("json")
local commandPrefix = "!" -- prefix used to identify commands entered through chat

local debugOutput = true -- set to false to hide console printed information

local userStatsPath = "Resources/KN8R_Utils/UserStats/"
local leaderboardFile = "Resources/KN8R_Utils/UserStats/races_leaderboard.json"

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
    MP.RegisterEvent("raceUpdateStats", "raceUpdateStats")
    MP.RegisterEvent("raceCreateStats", "raceCreateStats")
    MP.RegisterEvent("loadRaceLeaderboard", "loadRaceLeaderboard")
    MP.RegisterEvent("saveRaceLeaderboard", "saveRaceLeaderboard")

    print("K-Anator's Utilities Loaded!")
end

-- A player has authenticated and is requesting to join
-- The player's name (string), forum role (string), guest account (bool), identifiers (table -> ip, beammp)
function onPlayerAuth(player_name, role, isGuest, identifiers)
    local ip = identifiers.ip
    local beammp = identifiers.beammp or "N/A"
    if debugOutput then
        print(
            "onPlayerAuth: player_name: " .. player_name .. " | role: " .. role .. " | isGuest: " .. tostring(isGuest) ..
                " | identifiers: ip: " .. ip .. " - beammp: " .. beammp)
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
    MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " has joined the server!")
    --sendUserLeaderboard(player_id)
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
    if debugOutput then
        print("onVehicleSpawn: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
        print("data:")
        print(data)
    end
end

-- This is called when someone edits a vehicle, or replaces their existing one
-- The player's ID (number), the vehicle ID (number), and the vehicle data (table)
function onVehicleEdited(player_id, vehicle_id, data)
    if debugOutput then
        print("onVehicleEdited: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
        print("data:")
        print(data)
    end
end

-- This is called when someone resets a vehicle
-- The player's ID (number), the vehicle ID (number), and the vehicle data (table)
function onVehicleReset(player_id, vehicle_id, data)
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

------------------------------BEGIN CUSTOM FUNCTIONS------------------------------

	-- This will be called when the client-side examplePlugin triggers the server event "onJump"
	-- The player's ID, and the data

	-- function onJump(player_id, data)
	-- if debugOutput then
	-- print("onJump: player_id: " .. player_id .. " | Data: " .. data)
	-- end
	-- MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. " jumped " .. data .. " meters")
	-- end
	-- This will be called when the client-side examplePlugin triggers the server event "onSpeed"
	-- The player's ID, and the data

	-- function onSpeed(player_id, data)
	-- if debugOutput then
	-- print("onSpeed: player_id: " .. player_id .. " | Data: " .. data)
	-- end
	-- MP.SendChatMessage(-1, MP.GetPlayerName(player_id) .. "'s speed is: " .. data)
	-- end
function raceBegin(player_id, data)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local trackname = data
	local currentlap = 1
	local currentcheckpoint = 0
	local ispitted = 0
    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " started: " .. trackname .. "!")
    end


    raceUpdateStats(player_name, beammp, trackname, currentlap, currentcheckpoint, ispitted)

end

function raceCheckpoint(player_id, data)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local checkpoint = data

    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " went through checkpoint: " .. checkpoint .. "!")
    end
end

function raceFinishLap(player_id, data)
    local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data

    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " completed lap: " .. lap .. "!")
    end
end

function raceEnd(player_id, data)
	local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local trackname = data

    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " completed: " .. trackname .. "!")
    end
end

function raceLapInvalidated(player_id, data)
	local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local missedcheckpoints = data

    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. "  missed " .. missedcheckpoints .. " checkpoints!")
    end
end

function racePitEnter(player_id, data)
	local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data

    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " entered pit on: " .. lap + 1 .. "!")
    end
end

function racePitExit(player_id, data)
	local player_name = MP.GetPlayerName(player_id)
    local beammp = MP.GetPlayerIdentifiers(player_id).beammp or "N/A"
    local lap = data

    if debugOutput then
        print(player_name .. "(" .. beammp .. ")" .. " exited pit on: " .. lap + 1 .. "!")
    end
end

function raceUpdateStats(player_name, beammp, trackname, currentlap, currentcheckpoint, ispitted)
	local currentPlayerStats = userStatsPath .. "/" .. trackname .. "/" .. beammp .. ".json"
    -- Check for player stats and create them if needed
    if not FS.IsFile(currentPlayerStats) then
		print("Stats for this player don't exist, creating them.")
        raceCreateStats(trackname, beammp)
    end    
    -- Do stat update stuff
    json.writeJson(currentPlayerStats, {
        playerName = player_name,
        currentLap = currentlap,
		currentCheckpoint = currentcheckpoint,
		isPitted = ispitted
    })
end


function raceCreateStats(trackname, beammp)

    if not FS.IsDirectory(userStatsPath .. "/" .. trackname) then
        -- Create the directory
        local tracksuccess, error_message = FS.CreateDirectory(userStatsPath .. "/" .. trackname)
        if not tracksuccess then
            print("failed to create track directory: " .. error_message)
        else
            print("Track directory created!")
        end
    else
        print("Track directory already exists!")
    end

    if not FS.IsFile(userStatsPath .. "/" .. trackname .. "/" .. beammp .. ".json") then
        -- Create the user file

        local playersuccess, error_message =
            io.open(userStatsPath .. "/" .. trackname .. "/" .. beammp .. ".json", "w+")

        if not playersuccess then
            print("failed to create player file: " .. error_message)
        else
            print("Player file created!")
        end
        io.close(playersuccess)
    else
        print("Player file already exists!")
    end
end

local function sendUserLeaderboard(player_id)
    --MP.TriggerClientEvent("getLeaderboardMP", leaderboardFile)
end

function saveRaceLeaderboard(player_id, leaderboardData)
    print("Saving leaderboards to server")
    json.writeJson(userStatsPath .. "/" .. player_id .. ".json", leaderboardData)
end

function loadRaceLeaderboard(player_id)
    print("Loading leaderboards from server")
    local leaderboardData = json.readJson(userStatsPath .. "/" .. player_id .. ".json")
    MP.TriggerClientEvent(player_id, "returnLeaderboard", leaderboardData)
    MP.TriggerClientEvent(player_id, "loadLeaderboard")
end

-- This is called when a command is entered in chat
-- The player's ID, and the data containing the command and the arguments
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
    MP.TriggerClientEventJson(player_id, command, args) -- trigger the client event for the player that entered the command, sending arguments
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
