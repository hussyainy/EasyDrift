---@diagnostic disable: undefined-global
local oxmysql = exports.oxmysql

-- Create table if not exists
Citizen.CreateThread(function()
    Wait(1000) -- Wait for MySQL to be ready
    if oxmysql then
        oxmysql:execute([[
            CREATE TABLE IF NOT EXISTS drift_scores (
                id INT AUTO_INCREMENT PRIMARY KEY,
                identifier VARCHAR(50),
                name VARCHAR(50),
                score INT,
                duration INT,
                date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])
        print("^2[EasyDrift] Database initialized.^7")
    else
        print("^1[EasyDrift] oxmysql not found! Database saving will not work.^7")
    end
end)

local function getPlayerIdentifier(source)
    local numIds = GetNumPlayerIdentifiers(source)
    for i = 0, numIds - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, "license") then
            return id
        end
    end
    return GetPlayerIdentifier(source, 0)
end

RegisterNetEvent('drift:saveScore')
AddEventHandler('drift:saveScore', function(score, duration)
    local src = source
    local identifier = getPlayerIdentifier(src)
    local name = GetPlayerName(src)

    if not score or not duration then return end
    
    -- Validation
    -- Max points per ms calculation
    -- From client: 
    -- Points += (Angle / 100) * TimeFrame
    -- Points += Static * TimeFrame
    
    local maxAngle = ConfigShared.MaxAngle or 50
    local staticPoints = ConfigShared.StaticPointToAdd or 1
    
    -- Max possible points per millisecond
    local maxPointsPerMs = 0
    if ConfigShared.AddPointBasedOnAngle then
        maxPointsPerMs = maxPointsPerMs + (maxAngle / 100)
    end
    if ConfigShared.AddStaticPointOnDrifting then
        maxPointsPerMs = maxPointsPerMs + staticPoints
    end
    
    -- Calculate max possible score for the duration
    local maxPossibleScore = maxPointsPerMs * duration
    
    -- Add tolerance (e.g., 50% buffer for lag/latency/floating point errors/client frame time variations)
    -- Increased tolerance because frame times can vary and client calculation might slightly differ
    local tolerance = 1.5 
    local allowedScore = maxPossibleScore * tolerance
    
    -- Check if score is suspiciously high
    if score > allowedScore then
        print(string.format("^1[EasyDrift] Possible exploit detected from %s (ID: %s). Score: %s, Duration: %s, MaxAllowed: %s^7", name, src, score, duration, allowedScore))
        -- You can add ban logic here or kick
        -- DropPlayer(src, "Drift score exploit detected.")
        return
    end

    if oxmysql then
        -- Save to DB
        oxmysql:insert('INSERT INTO drift_scores (identifier, name, score, duration) VALUES (?, ?, ?, ?)', {
            identifier, name, score, duration
        }, function(id)
            -- print("Saved drift score for " .. name)
        end)
    end
end)

RegisterNetEvent('drift:getTopScores')
AddEventHandler('drift:getTopScores', function()
    local src = source
    if oxmysql then
        local limit = ConfigShared.ScoreboardTopCount or 10
        oxmysql:execute('SELECT name, score FROM drift_scores ORDER BY score DESC LIMIT ?', {limit}, function(result)
            TriggerClientEvent('drift:receiveTopScores', src, result)
        end)
    else
        TriggerClientEvent('drift:receiveTopScores', src, {})
    end
end)
