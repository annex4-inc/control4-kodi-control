local VERSION = "Driver Version"
local IP  = "IP Address"

local ID_REMOTE  = 5001
local ID_NETWORK = 6001

require('lib.kodi')
require('lib.kodiremote')

Driver = (function()
    local class = {
        remote = KodiRemote(ID_REMOTE)
    }

    local commands = {
        ["NOTIFICATION"] = function(tParams)
            class.kodi:showNotification(tParams.Title or "", tParams.Message or "", tParams.Image or "info", tonumber(tParams.Duration) or 5000)
        end,
        ["Play Favourite"] = function(tParams)
            class.kodi:playFavourite(tParams.Title)
        end
    }

    function class.OnNetworkBindingChanged(idBinding, bIsBound)
        if (idBinding == ID_NETWORK) then
            if (bIsBound) then
                local ip = C4:GetBindingAddress(idBinding)

                class.kodi.tcpConnection:updateAddress(ip)
            end
        end
    end

    function class.ExecuteCommand(strCommand, tParams)
        Logger.Trace("Driver.ExecuteCommand")
        Logger.Debug(strCommand, tParams)

        if (not class.kodi) then
            return
        end

        local command = commands[strCommand]

        if (command) then
            command(tParams)
        end
    end

    function class.OnDriverLateInit()
        local ip = C4:GetBindingAddress(ID_NETWORK)

        C4:UpdateProperty(VERSION, C4:GetDriverConfigInfo("semver"))

        class.kodi = Kodi(ip and ip ~= "" and ip or "127.0.0.1", 9090, ID_NETWORK)
        class.kodi:connect()
    end

    Hooks.Register(class, "Driver")

    return class
end) ()