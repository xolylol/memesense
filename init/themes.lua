-- Themes: built-in presets, a small color editor and saved
-- theme configs (workspace/<lib.dir>/themes/<name>.json).

return function(Init)
    local lib, fs = Init.lib, Init.fs
    local rgb = Color3.fromRGB
    local M = {}

    -- default colors, taken before anything is changed
    local base = {}
    for k, v in pairs(lib.thm) do
        base[k] = v
    end
    M.base = base

    M.order = {
        "MemeSense", "Ocean", "Violet", "Emerald",
        "Amber", "Mono", "Midnight",
    }

    -- built-in themes only list what differs from the default
    M.builtin = {
        MemeSense = {},
        Ocean = { acc = rgb(59, 152, 230) },
        Violet = { acc = rgb(150, 100, 255) },
        Emerald = { acc = rgb(46, 204, 113) },
        Amber = { acc = rgb(255, 170, 0) },
        Mono = { acc = rgb(235, 235, 240) },
        Midnight = {
            acc = rgb(88, 101, 242),
            bg = rgb(12, 13, 18),
            side = rgb(14, 15, 21),
            nav = rgb(19, 20, 28),
            navp = rgb(25, 26, 38),
            row = rgb(16, 17, 23),
            card = rgb(22, 23, 32),
            cardh = rgb(29, 30, 41),
            ctl = rgb(22, 24, 34),
            ctlh = rgb(29, 32, 45),
            pop = rgb(15, 16, 23),
            panel = rgb(22, 23, 32),
            trk = rgb(24, 25, 34),
        },
    }

    -- colors shown in the editor
    M.keyorder = { "acc", "bg", "side", "ctl", "txt", "dim" }
    M.keys = {
        acc = "Accent",
        bg = "Background",
        side = "Sidebar",
        ctl = "Controls",
        txt = "Text",
        dim = "Dim text",
    }

    M.current = nil

    local function folder()
        return lib.dir .. "/themes"
    end

    local function path(n)
        return folder() .. "/" .. n .. ".json"
    end

    function M.clean(n)
        n = tostring(n or "")
        n = n:gsub("[^%w _%-]", "")
        n = n:gsub("^%s+", "")
        n = n:gsub("%s+$", "")
        return n:sub(1, 32)
    end

    function M.saved()
        return fs.list(folder(), "json")
    end

    -- built-in names first, then saved ones
    function M.names()
        local out = {}
        for _, n in ipairs(M.order) do
            out[#out + 1] = n
        end
        for _, n in ipairs(M.saved()) do
            if not M.builtin[n] then
                out[#out + 1] = n
            end
        end
        return out
    end

    function M.exists(name)
        if M.builtin[name] then
            return true
        end
        return fs.has(path(M.clean(name)))
    end

    -- full color table of a theme, or nil if it does not exist
    function M.get(name)
        local t = {}
        for k, v in pairs(base) do
            t[k] = v
        end
        local over = M.builtin[name]
        if over then
            for k, v in pairs(over) do
                t[k] = v
            end
            return t
        end
        local d = Init.jdec(fs.read(path(M.clean(name))))
        local cols = d and d.colors
        if type(cols) ~= "table" then
            return nil
        end
        for k, h in pairs(cols) do
            if t[k] ~= nil and type(h) == "string" then
                local ok, c = pcall(Color3.fromHex, h)
                if ok and typeof(c) == "Color3" then
                    t[k] = c
                end
            end
        end
        return t
    end

    function M.apply(name)
        local t = M.get(name)
        if not t then
            return false
        end
        lib:applytheme(t)
        M.current = name
        return true
    end

    -- saves the colors that are currently on screen
    function M.save(name)
        name = M.clean(name)
        if name == "" or M.builtin[name] then
            return nil
        end
        local cols = {}
        for k, v in pairs(lib.thm) do
            cols[k] = v:ToHex()
        end
        fs.dir(lib.dir)
        fs.dir(folder())
        local data = Init.jenc({ name = name, colors = cols })
        if fs.write(path(name), data or "{}") then
            M.current = name
            return name
        end
        return nil
    end

    function M.delete(name)
        if M.builtin[name] then
            return false
        end
        fs.del(path(M.clean(name)))
        return true
    end

    return M
end
