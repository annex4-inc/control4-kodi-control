-- Optimization include files
#include utility/localized.lua #endinclude

-- Utility libraries
#include utility/hooks.lua #endinclude 	-- Load hooks first so other objects can bind themselves
#include utility/timer.lua #endinclude
#include utility/assert.lua #endinclude
#include utility/logger.lua #endinclude -- Introduce logger so objects can bind themselves to logging

-- String manipulation and parsing
#include utility/string.lua #endinclude
#include utility/table.lua #endinclude
#include utility/url.lua #endinclude
#include utility/event.lua #endinclude
#include utility/file.lua #endinclude
#include utility/time.lua #endinclude
#include utility/bithelper.lua #endinclude
#include utility/enum.lua #endinclude

#include proxy/proxy.lua #endinclude
#include proxy/cable.lua #endinclude

-- Formats
#include format/http.lua #endinclude
#include format/json.lua #endinclude
#include format/xml.lua #endinclude

#include connection/connection.lua #endinclude
#include connection/tcpconnection.lua #endinclude
#include connection/httpconnection.lua #endinclude
#include connection/websocket.lua #endinclude

#include utility/wol.lua #endinclude

#include security/authentication.lua #endinclude

#include api/annex4.lua #endinclude

-- Create authentication instance
local g_authentication = Authentication(nil, "kodi_control_ip_annex4.c4z")

-- Set the Annex4 API filename
Annex4.SetFilename("kodi_control_ip_annex4.c4z")

-- Notify every proxy that they require authentication to invoke commands
Proxy.RequiresAuthentication(true)

local VERSION = "Driver Version"
local MAC = "MAC Address"
local IP  = "IP Address"

Annex4.IgnoreProperty(IP)
Annex4.IgnoreProperty(MAC)

local ID_REMOTE  = 5001
local ID_NETWORK = 6001

Kodi = (function(baseClass)
    local class = {}; class.__index = class

    class.MediaTypes = {
        Movie = "movie",
        Episode = "episode",
        TVShow = "tvshow",
        Season = "season",
    }

    class.TransportState = {
        ["Stop"] = 0,
        ["Play"] = 1,
        ["Pause"] = 2,
    }

    class.Images = {
        ["Info"]    = "info",
        ["Warning"] = "warning",
        ["Error"]   = "error"
    }

    class.Inputs = {
        {name = "Fullscreen", action = "fullscreen"},
        {name = "On Screen Display", action = "osd"},
        {name = "Toggle Subtitles", action = "showsubtitles"},
        {name = "Menu", action = "menu"},
        {name = "Context Menu", action = "contextmenu"},
        {name = "Red", action = "red"},
        {name = "Green", action = "green"},
        {name = "Yellow", action = "yellow"},
        {name = "Blue", action = "blue"},
        {name = "Screenshot", action = "screenshot"},
        {name = "Next Subtitle", action = "nextsubtitle"},
        {name = "Cycle Subtitle", action = "cyclesubtitle"},
        {name = "Subtitle Delay +", action = "subtitledelayplus"},
        {name = "Subtitle Delay -", action = "subtitledelayminus"},
        {name = "Next Language", action = "audionextlanguage"},
    }

    local variables = {
        {label = "Title", type = "STRING"},
        {label = "Type", type = "STRING"},
        {label = "End", type = "BOOLEAN"},
    }

    local notifications = {
        ['GUI.OnScreensaverActivated']   = 'onScreensaverActivated',
        ['GUI.OnScreensaverDeactivated'] = 'onScreensaverDeactivated',
        ['GUI.OnDPMSActivated']          = 'onDPMSActivated',
        ['GUI.OnDPMSDeactivated']        = 'onDPMSDeactivated',
        ['GUI.OnFavouritesUpdated']      = 'onFavouritesUpdated',

        ['Player.OnStop']  = 'onPlayerStop',
        ['Player.OnPlay']  = 'onPlayerPlay',
        ['Player.OnPause'] = 'onPlayerPause',
        ['Player.OnSeek']  = 'onPlayerSeek',
        ['Player.OnSpeedChanged'] = 'onSpeedChanged',

        ['Playlist.OnAdd']    = 'onPlaylistAdd',
        ['Playlist.OnClear']  = 'onPlaylistClear',
        ['Playlist.OnRemove'] = 'onPlaylistRemove',

        ['Application.OnVolumeChanged'] = 'onVolumeChanged',

        ['Input.OnInputRequested'] = 'onInputRequested',
        ['Input.OnInputFinished']  = 'onInputFinished',

        ['System.OnLowBattery'] = 'onLowBattery',
        ['System.OnQuit'] = 'onQuit',
        ['System.OnRestart'] = 'onRestart',
        ['System.OnWake'] = 'onWake',
        ['System.OnSleep'] = 'onSleep',
    }

    function class:onScreensaverActivated()
        Logger.Trace("Kodi.onScreensaverActivated")

        C4:FireEvent("Screensaver Activated")
    end

    function class:onScreensaverDeactivated()
        Logger.Trace("Kodi.onScreensaverDeactivated")

        C4:FireEvent("Screensaver Activated")
    end

    function class.onFavouritesUpdated()
        Logger.Trace("Kodi.onFavouritesUpdated")

        C4:FireEvent("Favourites Updated")
    end

    function class:onPlayerStop(response)
        Logger.Trace("Kodi.onPlayerStop")

        C4:FireEvent("On Player Stop")

        Driver.remote:notifyStop()
    end

    function class:onPlayerPlay(response)
        Logger.Trace("Kodi.onPlayerPlay")

        C4:FireEvent("On Player Play")

        Driver.remote:notifyPlay()
    end

    function class:onPlayerPause(response)
        Logger.Trace("Kodi.onPlayerPause")

        C4:FireEvent("On Player Pause")

        Driver.remote:notifyPause()
    end

    function class:onPlaylistAdd(response)
        Logger.Trace("Kodi.onPlaylistAdd")

        C4:FireEvent("On Playlist Add")
    end

    function class:onPlaylistRemove(response)
        Logger.Trace("Kodi.onPlaylistRemove")

        C4:FireEvent("On Playlist Remove")
    end

    function class:onPlaylistClear(response)
        Logger.Trace("Kodi.onPlaylistClear")

        C4:FireEvent("On Playlist Clear")
    end

    --- Sends a generic json RPC request
    -- @param id The identifier to be used to identify and route the response
    -- @param method The method
    -- @param params The paramters attached to the method
    function class:jsonRPCRequest(id, method, params, callback, ...)
        -- Auto increment JSON RPC id
        self.currentId = self.currentId + 1

        -- Limit the ID to 1-25
        if (self.currentId > 25) then
            self.currentId = 1
        end

        id = id or self.currentId

        local request = {
            jsonrpc = "2.0",
            id = id,
            method = method,
            params = params
        }

        -- Set the callback handle for the ID
        self.handles[id] = {
            callback = callback,
            args = arg
        }

        local encoded = JSON.Encode(request)

        self:sendText(encoded, callback)
    end

    function class:sendBlocking(method, params)
        local request = {
            jsonrpc = "2.0",
            id = 100,
            method = method,
            params = params
        }

        local headers = {
            ['Content-Type'] = 'application/json'
        }

        self.tcpConnection:post('/jsonrpc', headers, JSON.Encode(request))
    end

    --- Basic input request
    -- @param action The action to send
    function class:inputAction(action, callback)
        self:jsonRPCRequest(nil, "Input.ExecuteAction", {
            action = action
        }, callback)
    end

    --- Actives the specific window
    -- @param window The window to go to
    function class:activateWindow(window, callback)
        self:jsonRPCRequest(nil, "GUI.ActivateWindow", {
            window = window
        }, callback)
    end

    function class:getFavourites(callback)
        self:jsonRPCRequest(nil, "Favourites.GetFavourites", {
            type = "media",
            properties = { "window", "windowparameter", "thumbnail", "path" }
        }, callback)
    end

    function class:playFavourite(name, callback)
        self:getFavourites(function(obj, res)
            Logger.Info(res)
            if (res and res.limits.total > 0) then
                for _, f in ipairs(res.favourites)  do
                    if (f.title == name) then
                        self:jsonRPCRequest(nil, "Playlist.Clear", {
                            playlistId = 0
                        })

                        self:jsonRPCRequest(nil, "Playlist.Add", {
                            playlistid = 0,
                            item = {
                                file = f.path
                            }
                        })

                        self:playerOpen({
                            playlistid = 0
                        })
                    end
                end
            end
        end)
    end

    --- Shows a notification on Kodi
    function class:showNotification(title, message, image, displayTime, callback)
        self:jsonRPCRequest(nil, "GUI.ShowNotification", {
            title = title,
            message = message,
            image = image or "info",
            displaytime = displayTime or 5000
        }, callback)
    end

    --- Opens a player and starts the file specified
    -- @param item The item to playback
    -- @param callback The callback function to supply the response to
    function class:playerOpen(item, callback, ...)
        self:jsonRPCRequest(nil, "Player.Open", {
            item = item
        }, callback, unpack(arg))
    end

    --- Opens a player and starts the file specified
    -- @param item The item to playback
    -- @param callback The callback function to supply the response to
    function class:playerGoTo(playerid, to, callback)
        self:jsonRPCRequest(nil, "Player.GoTo", {
            playerid = playerid,
            to = to,
        }, callback)
    end

    --- Retrieves the items in a playlist
    -- @param playlistid The playlist to retrieve
    -- @param callback The callback function to supply the response to
    function class:getPlaylistItems(playlistid, properties, callback, ...)
        self:jsonRPCRequest(nil, "Playlist.GetItems", {
            playlistid = playlistid,
            properties = properties
        }, callback, unpack(arg))
    end

    --- Inserts and item into the playlist
    -- @param playlistId The playlist to add the item to
    -- @param position The position to add the item to
    -- @param item The item to be added
    function class:playlistInsert(playlistId, position, item)
        self:jsonRPCRequest(nil, "Playlist.Insert", {
            playlistid = playlistId,
            position = position,
            item = item
        })
    end

    --- Creates a new favourite in kodi
    -- @param title The title of the media
    -- @param type The type of media
    -- @param path The path to the media
    -- @param thumbnail The image for the media
    function class:addFavourite(title, type, path, thumbnail, window, windowparameter, callback)
        self:jsonRPCRequest(nil, "Favourites.AddFavourite", {
            title = title,
            type = type,
            path = path,
            thumbnail = thumbnail,
            window = window,
            windowparameter = windowparameter
        }, callback)
    end

    ---	Generic handler for Kodi data
    -- @param frame The frame to handle
    function class:globalHandle(frame)
        Logger.Trace("Kodi.globalHandle")

        -- Handles pong for us
        baseClass.globalHandle(self, frame)

        if (self.isUpgraded) then
            if (frame and frame.payload) then
                local result, response = pcall(JSON.Decode, frame.payload)

                if (result and response and type(response) == "table") then
                    -- Determine method
                    local method = response.method
                    local id     = response.id

                    if (id and self.handles[id]) then
                        local callback = self.handles[id].callback
                        local args     = self.handles[id].args

                        if (callback and type(callback) == "function") then
                            callback(self, response.result, unpack(args))
                        end

                        self.handles[id] = nil
                    else
                        local callback = notifications[method]

                        if (callback) then
                            class[callback](self, response.params)
                        end
                    end
                else
                    Logger.Trace("Bad Frame:")
                    hexdump(frame.payload)
                end
            end
        end
    end

    local mt = {
        __call = function(self, ip, port, binding)
            local instance = baseClass("ws://" .. ip .. ":" .. tostring(port) .. "/jsonrpc", true, {KEEP_ALIVE = true, BINDING = binding})
                  instance.tcpConnection = HTTPConnection(ip, 8080, false)
                  instance.currentId = 1
                  instance.handles = {}

            setmetatable(instance, class)

            return instance
        end,

        __index = baseClass
    }

    setmetatable(class, mt)

    return class
end) (WebSocket)

KodiRemote = (function(baseClass)
    local class = {}; class.__index = class

    class.buttons = {
        ['Button - Guide']      = 'guide',
        ['Button - DVR'] 		= 'pvr',
        ['Button - Menu'] 		= 'menu',
        ['Button - Star'] 		= 'star',
        ['Button - Pound']      = 'pound',
        ['Button - Red']	    = 'programA',
        ['Button - Green']      = 'programB',
        ['Button - Yellow']     = 'programC',
        ['Button - Blue']       = 'programD',
    }

    class.dynamicCommands = {
        ["Fullscreen"]        = {index = 1, command = "fullscreen"},
        ["On Screen Display"] = {index = 2, command = "osd"},
        ["Toggle Subtitles"]  = {index = 3, command = "showsubtitles"},
        ["Menu"]              = {index = 4, command = "menu"},
        ["Context Menu"]      = {index = 5, command = "contextmenu"},
        ["Red"]               = {index = 6, command = "red"},
        ["Green"]             = {index = 7, command = "green"},
        ["Yellow"]            = {index = 8, command = "yellow"},
        ["Blue"]              = {index = 9, command = "blue"},
        ["Screenshot"]        = {index = 10, command = "screenshot"},
        ["Go Home"]           = {index = 11, command = "home", type = "window"},
        ["Go Favourites"]     = {index = 12, command = "favourites", type = "window", blocking = true},
        ["No Operation"]      = {index = 13, command = "noop"},
        ["Next Subtitle"]     = {index = 14, command = "nextsubtitle"},
        ["Cycle Subtitle"]    = {index = 15, command = "cyclesubtitle"},
        ["Subtitle Delay +"]  = {index = 16, command = "subtitledelayplus"},
        ["Subtitle Delay -"]  = {index = 17, command = "subtitledelayminus"},
        ["Next Language"]     = {index = 18,  command = "audionextlanguage"},
    }

    local favourites = {
        "media",
        "window",
        "script",
        "unknown"
    }

    local simple_map = {
        --"up", "down", "left", "right",
        --"number0", "number1", "number2", "number3", "number4", "number5", "number6", "number7", "number8", "number9",
        "play", "pause", "stop",
        "red", "green", "blue", "yellow",
        "menu", "back", "info",
        "record",
        --"mute",
    }

    local mapping = {
        --enter    = "select",
        skipFwd  = "skipnext",
        skipRev  = "skipprevious",
        scanFwd  = "fastforward",
        scanRev  = "rewind",
        pageUp   = "pageup",
        pageDown = "pagedown",
        volumeUp = "volumeup",
        volumeDown = "volumedown",
        channelUp = "channelup",
        channelDown = "channeldown",
        programA = "red",
        programB = "green",
        programC = "yellow",
        programD = "blue",
        cancel = "close",
        recall = "back",
        menu   = "contextmenu",
        pound  = "osd",
        star   = "menu",
        pvr    = "osd",
    }

    local advanced = {
        number0 = "number0",
        number1 = "number1",
        number2 = "number2",
        number3 = "number3",
        number4 = "number4",
        number5 = "number5",
        number6 = "number6",
        number7 = "number7",
        number8 = "number8",
        number9 = "number9",
    }

    for index, key in ipairs(simple_map) do
        class[key] = function(callback)
            Driver.kodi:inputAction(key, callback)
        end
    end

    for key, value in pairs(mapping) do
        class[key] = function(callback)
            Driver.kodi:inputAction(value, callback)
        end
    end

    function class:number0()
        Driver.kodi:inputAction("number0")
        Driver.kodi:inputAction("nextletter")
    end

    function class:number1()
        Driver.kodi:inputAction("number1")
        Driver.kodi:inputAction("prevletter")
    end

    function class:number2()
        Driver.kodi:inputAction("jumpsms2")
    end

    function class:number3()
        Driver.kodi:inputAction("jumpsms3")
    end

    function class:number4()
        Driver.kodi:inputAction("jumpsms4")
    end

    function class:number5()
        Driver.kodi:inputAction("jumpsms5")
    end

    function class:number6()
        Driver.kodi:inputAction("jumpsms6")
    end

    function class:number7()
        Driver.kodi:inputAction("jumpsms7")
    end

    function class:number8()
        Driver.kodi:inputAction("jumpsms8")
    end

    function class:number9()
        Driver.kodi:inputAction("jumpsms9")
    end

    function class:up()
        Driver.kodi:jsonRPCRequest(nil, "GUI.GetProperties", {properties = {"fullscreen", "currentwindow", "currentcontrol"}}, function(obj, res)
            if (res and res.currentwindow and res.currentwindow.label == "Fullscreen video") then
                Driver.kodi:inputAction("bigstepforward")
            else
                Driver.kodi:inputAction("up")
            end
        end)
    end

    function class:down()
        Driver.kodi:jsonRPCRequest(nil, "GUI.GetProperties", {properties = {"fullscreen", "currentwindow", "currentcontrol"}}, function(obj, res)
            if (res and res.currentwindow and res.currentwindow.label == "Fullscreen video") then
                Driver.kodi:inputAction("bigstepback")
            else
                Driver.kodi:inputAction("down")
            end
        end)
    end

    function class:left()
        Driver.kodi:jsonRPCRequest(nil, "GUI.GetProperties", {properties = {"fullscreen", "currentwindow", "currentcontrol"}}, function(obj, res)
            if (res and res.currentwindow and res.currentwindow.label == "Fullscreen video") then
                Driver.kodi:inputAction("stepback")
            else
                Driver.kodi:inputAction("left")
            end
        end)
    end

    function class:right()
        Driver.kodi:jsonRPCRequest(nil, "GUI.GetProperties", {properties = {"fullscreen", "currentwindow", "currentcontrol"}}, function(obj, res)
            if (res and res.currentwindow and res.currentwindow.label == "Fullscreen video") then
                Driver.kodi:inputAction("stepforward")
            else
                Driver.kodi:inputAction("right")
            end
        end)
    end

    function class:enter()
        Driver.kodi:jsonRPCRequest(nil, "GUI.GetProperties", {properties = {"fullscreen", "currentwindow", "currentcontrol"}}, function(obj, res)
            if (res and res.currentwindow and res.currentwindow.label == "Fullscreen video") then
                Driver.kodi:inputAction("playpause")
            else
                Driver.kodi:inputAction("select")
            end
        end)
    end

    function class:on()
        Logger.Trace("KodiRemote.on")

        local mac = Properties[MAC]

        if (mac) then
            WOL.On(mac)
        end
    end

    function class.OnPropertyChanged(strProperty)
        local method = class.buttons[strProperty]

        if (method) then
            class[method] = function(self)
                local cmd = class.dynamicCommands[Properties[strProperty]]

                if (cmd) then
                    if (cmd.type == "window") then
                        if (cmd.blocking) then
                            Driver.kodi:sendBlocking("GUI.ActivateWindow", { window = cmd.command })
                        else
                            Driver.kodi:activateWindow(cmd.command)
                        end
                    else
                        Driver.kodi:inputAction(cmd.command)
                    end
                else
                    Logger.Error("KodiMediaService: Failed to configure button")
                end
            end
        end
    end

    local mt = {
        __call = function(self, proxyId)
            assert(baseClass, "Class 'KodiRemote' requires a base class")

            local instance = baseClass and baseClass(proxyId)

            setmetatable(instance, class)

            return instance
        end,

        __index = baseClass
    }

    setmetatable(class, mt)

    if (Hooks) then
        Hooks.Register(class, "KodiRemote")
    end

    return class
end) (Cable)

Driver = (function()
    local ip = C4:GetBindingAddress(ID_NETWORK)

    local class = {
        kodi = Kodi(ip and ip ~= "" and ip or "127.0.0.1", 9090, ID_NETWORK),
        remote = KodiRemote(ID_REMOTE)
    }

    class.kodi:connect()

    function class.OnNetworkBindingChanged(idBinding, bIsBound)
        if (idBinding == ID_NETWORK) then
            if (bIsBound) then
                local ip = C4:GetBindingAddress(idBinding)

                Driver.kodi.tcpConnection:updateAddress(ip)

                if (ip and ip ~= "") then
                    Annex4.UpdateProperty(IP, ip)
                else
                    Annex4.UpdateProperty(IP, "Not set")
                end
            else
                Annex4.UpdateProperty(IP, "Not set")
            end
        end
    end

    function class.OnPropertyChanged(strProperty)
        Logger.Force(Verbosity.INFO, string.format("Driver.OnPropertyChanged[%s]: %s", strProperty, Properties[strProperty]))

        if (strProperty == VERSION) then
            C4:UpdateProperty(VERSION, "0.0.38")
        end
    end

    function class.ExecuteCommand(strCommand, tParams)
        Logger.Trace("Driver.ExecuteCommand")
        Logger.Debug(strCommand, tParams)
        
        if (strCommand == "NOTIFICATION") then
            class.kodi:showNotification(tParams.Title or "", tParams.Message or "", tParams.Image or "info", tonumber(tParams.Duration) or 5000)
        elseif (strCommand == "Play Favourite") then
            class.kodi:playFavourite(tParams.Title)
        end
    end

    -- Driver initialized after project load
    function class.OnDriverLateInit()
        -- TODO Create variables
    end

    Hooks.Register(class, "Driver")

    return class
end) ()

-- Initialize
for k, v in pairs(Properties) do
	OnPropertyChanged(k)
end
