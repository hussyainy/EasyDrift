---@diagnostic disable: undefined-global
Modules.UI.ScoreboardData = {}
Modules.UI.IsScoreboardOpen = false

Modules.UI.pages["scoreboard"] = {
    label = "scoreboard",
    active = false,
    lockControls = false,
    showCursor = false,
    drawFunction = function()
        Modules.UI.DrawScoreboard()
    end,
}

function Modules.UI.DrawScoreboard()
    local baseX = 0.5
    local baseY = 0.5
    local width = 0.3
    local height = 0.5

    -- Draw Background
    DrawRect(baseX, baseY, width, height, 0, 0, 0, 200)

    -- Draw Title
    Modules.UI.DrawTexts(baseX, baseY - (height/2) + 0.02, ConfigShared.ScoreboardTitle or "TOP DRIFTERS", true, 0.8, {250, 224, 64, 255}, Modules.UI.font["forza"] or 1, false, false)

    -- Draw Header
    local startY = baseY - (height/2) + 0.08
    Modules.UI.DrawTexts(baseX - (width/2) + 0.02, startY, "Name", false, 0.4, {255, 255, 255, 255}, Modules.UI.font["forza"] or 4, false, false)
    Modules.UI.DrawTexts(baseX + (width/2) - 0.02, startY, "Score", false, 0.4, {255, 255, 255, 255}, Modules.UI.font["forza"] or 4, true, false) -- Right justify score

    -- Draw Separator
    DrawRect(baseX, startY + 0.040, width - 0.02, 0.002, 255, 255, 255, 150)

    -- Draw List
    local currentY = startY + 0.05
    if Modules.UI.ScoreboardData then
        for i, data in ipairs(Modules.UI.ScoreboardData) do
            if i > (ConfigShared.ScoreboardTopCount or 10) then break end

            local name = data.name or "Unknown"
            local score = Modules.Utils.Comma_value(data.score or 0)

            -- Rank color
            local color = {255, 255, 255, 255}
            if i == 1 then color = {255, 215, 0, 255} end -- Gold
            if i == 2 then color = {192, 192, 192, 255} end -- Silver
            if i == 3 then color = {205, 127, 50, 255} end -- Bronze

            Modules.UI.DrawTexts(baseX - (width/2) + 0.02, currentY, i .. ". " .. name, false, 0.35, color, Modules.UI.font["forza"] or 4, false, false)
            Modules.UI.DrawTexts(baseX + (width/2) - 0.02, currentY, score, false, 0.35, color, Modules.UI.font["forza"] or 4, true, false)

            currentY = currentY + 0.035
        end
    else
        Modules.UI.DrawTexts(baseX, currentY, "Loading...", true, 0.35, {255, 255, 255, 255}, Modules.UI.font["forza"] or 4, false, false)
    end
end

RegisterNetEvent('drift:receiveTopScores')
AddEventHandler('drift:receiveTopScores', function(data)
    Modules.UI.ScoreboardData = data
end)

function Modules.UI.ToggleScoreboard()
    Modules.UI.IsScoreboardOpen = not Modules.UI.IsScoreboardOpen
    if Modules.UI.IsScoreboardOpen then
        TriggerServerEvent('drift:getTopScores')
        Modules.UI.SetPageActive("scoreboard")
    else
        Modules.UI.SetPageInactive("scoreboard")
    end
end

RegisterCommand(ConfigShared.ScoreboardCommand, function()
    if ConfigShared.EnableScoreboard then
        Modules.UI.ToggleScoreboard()
    end
end, false)

Citizen.CreateThread(function()
    while true do
        if ConfigShared.EnableScoreboard and IsControlJustReleased(0, ConfigShared.ScoreboardKey) then
            Modules.UI.ToggleScoreboard()
        end
        Wait(0)
    end
end)
