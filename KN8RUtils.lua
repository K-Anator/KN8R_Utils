-- K-Anator's Utilities.
json = require("json")

local commandPrefix = "!" -- prefix used to identify commands entered through chat

local debugOutput = true -- set to false to hide console printed information

local userStatsPath = "Resources/KN8R_Utils/UserStats/"
local leaderboardPath = "Resources/KN8R_Utils/UserStats/"

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

    print("K-Anator's Utilities Loaded!")
end

-- A player has authenticated and is requesting to join
-- The player's name (string), forum role (string), guest account (bool), identifiers (table -> ip, beammp)
function onPlayerAuth(player_name, role, isGuest, identifiers)
    if player_name == "CamaroCars" then
        return "You cannot connect to this server due to performance issues."
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

        if message == "!start" then
            MP.SendChatMessage(-1, "Race is about to start!")
            countdown()
            return
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
        sendLeaderboard(player_id) -- Testing, get rid of this and use onPlayerJoin
    end

    -- This is called when someone deletes a vehicle they own
    -- The player's ID (number) and the vehicle ID (number)
    function onVehicleDeleted(player_id, vehicle_id)
        if debugOutput then
            print("onVehicleDeleted: player_id: " .. player_id .. " | vehicle_id: " .. vehicle_id)
        end
    end

    ------------------------------BEGIN CUSTOM FUNCTIONS------------------------------

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

    function createLeaderboard(beammp)
        if not FS.IsFile(userStatsPath .. "/" .. beammp .. ".json") then
            local playersuccess, error_message = io.open(userStatsPath .. "/" .. beammp .. ".json", "w+")
            if not playersuccess then
                print("failed to create player file: " .. error_message)
            else
                print("Player stats file created!")
                io.close(playersuccess)
            end
        else
            print("Player already has stats file!")
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

        -- does leaderboard for this player exist?
        local leaderboardFile = leaderboardPath .. beammp .. ".json"
        if not FS.IsFile(leaderboardFile) then
            print("Stats file for " .. player_name .. " doesn't exist, creating it.")
            createLeaderboard(beammp)
        end

        print("Player: " .. player_name .. " wants to update their leaderboard")
        print(leaderboardData)

        local file = io.open(leaderboardFile, "w+")
        file:write(leaderboardData)
        file:close()

        print("Leaderboard received from " .. player_name)
    end

    function countdown()

        local length = 5

        for i = 0, length do
            if i < length then
                MP.SendChatMessage(-1, "Race Starts in " .. length - i)
            end

            if i == length then
                MP.SendChatMessage(-1, "Go!")
            end
            MP.Sleep(1000)
        end
    end
end
