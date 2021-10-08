local inDuty = {} 
ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)


--------------------DISCORD FUNCTIONS-----------------
function getPlayerDc(playId)
    local identifiers = GetPlayerIdentifiers(playId)

    local discord = nil

    for _, identifier in pairs(identifiers) do
        if (string.match(string.lower(identifier), 'discord:')) then
            discord = string.sub(identifier, 9)
        end
    end
    return discord
end

function getLabelTes(dcId, cb)
    local infok = nil
    if dcId ~= nil then
        PerformHttpRequest("https://discordapp.com/api/guilds/" .. Config.GuildId .. "/members/" .. dcId, function(errorCode, resultData, resultHeaders)
            if resultData ~= nil then
                local data = {data=resultData, code=errorCode, headers=resultHeaders}
                local roles = json.decode(resultData).roles
                for v=1, #roles, 1 do 
                    for i, k in pairs(Config.Admins) do
                        if roles[v] == k[1] then
                            infok = k
                        end
                    end
                end
            else
                print('Előfurdalhat konfigurációs hiba vagy olyan játékos próbált dutyzni aki nem discord tag!')
            end
        end, "GET", "", {["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. Config.BotToken})
    end

    Wait(700)

    cb(infok)
end

function sendToDiscord(name, message, color)
    local connect = {
          {
              ["color"] = color,
              ["title"] = "**".. name .."**",
              ["description"] = message,
              ["footer"] = {
                  ["text"] = "villamos_aduty :)",
              },
          }
      }
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({embeds = connect}), { ['Content-Type'] = 'application/json' })
end

------------------COMMAND--------------------
AddEventHandler('playerDropped', function(reason)
    if inDuty[source] ~= nil then
        inDuty[source] = nil
        TriggerClientEvent("villamos_aduty:sendData", -1, inDuty)
        if Config.Webhook ~= nil then
            sendToDiscord(GetPlayerName(source), GetPlayerName(source) .. " kilépett a szolgálatból! (lelépett a szerverről)", 16711680)
        end
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 0, 0},
            multiline = true,
            args = {"Aduty", GetPlayerName(source) .. " kilépett a szolgálatból!"}
        })
    end
end)

RegisterCommand(Config.Command, function(source, args, raw)
	local adm = ESX.GetPlayerFromId(source)
    if adm.getGroup() ~= "user" then
        if inDuty[source] == nil then
            getLabelTes(getPlayerDc(source), function(aData)
                if aData == nil then 
                    TriggerClientEvent('chat:addMessage', source, {
                        color = { 255, 0, 0},
                        multiline = true,
                        args = {"Aduty", "Nincs megfelelő rangod Discordon, így nem léphetsz szolgálatba!"}
                     })                  
                else
                    inDuty[source] = aData
                    TriggerClientEvent("villamos_aduty:sendData", -1, inDuty)
                    TriggerClientEvent('chat:addMessage', -1, {
                        color = { 255, 0, 0},
                        multiline = true,
                        args = {"Aduty", GetPlayerName(source) .. " szolgálatba lépett! /report [üzenet] a segítség kéréshez"}
                    })
                    TriggerClientEvent('villamos_aduty:enable', source)
                    if Config.Webhook ~= nil then
                        sendToDiscord(GetPlayerName(source), GetPlayerName(source) .. " szolgálatba lépett!", 6415476)
                    end
                end
            end)
        else
            inDuty[source] = nil
            TriggerClientEvent("villamos_aduty:sendData", -1, inDuty)
            TriggerClientEvent('chat:addMessage', -1, {
                color = { 255, 0, 0},
                multiline = true,
                args = {"Aduty", GetPlayerName(source) .. " kilépett a szolgálatból!"}
            })
            TriggerClientEvent('villamos_aduty:disable', source)
            if Config.Webhook ~= nil then
                sendToDiscord(GetPlayerName(source), GetPlayerName(source) .. " kilépett a szolgálatból!", 16711680)
            end
        end
    end
end, false);


-------------KLIENS KÜLDÉS----------
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    TriggerClientEvent("villamos_aduty:sendData", source, inDuty)
end)

--------------EXPORTOK---------------
exports('getDutys', function()
    return inDuty;
end)
