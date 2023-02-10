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

        local mac = Properties["MAC Address"]

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