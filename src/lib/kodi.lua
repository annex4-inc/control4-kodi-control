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

        ['Other.PlaybackStopped'] = 'onPlaybackStop'
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

        -- Response.data.item (One of several types, 'title' common across all)
        -- Response.data.player

        -- Update variable information
        if (response and response.data and response.data.item.title) then
            C4:SetVariable("CURRENT_TITLE", response.data.item.title)
        else
            C4:SetVariable("CURRENT_TITLE", "")
        end

        Driver.remote:notifyPlay()
    end

    function class:onPlayerPause(response)
        Logger.Trace("Kodi.onPlayerPause")

        C4:FireEvent("On Player Pause")

        Driver.remote:notifyPause()
    end

    function class:onPlaybackStop(response)
        C4:SetVariable("CURRENT_TITLE", "")
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