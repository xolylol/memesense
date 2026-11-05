-- The "UI Settings" tab: menu preset, DPI scale, theme, theme
-- configs and watermark. Everything here is saved to
-- <lib.dir>/init.json and restored on the next launch.

return function(Init)
    local lib, fs = Init.lib, Init.fs
    local presets = Init.presets
    local themes = Init.themes
    local watermark = Init.watermark
    local M = {}

    M.state = {}

    local loaded = false
    local pending = false

    local function file()
        return lib.dir .. "/init.json"
    end

    local function load()
        if loaded then
            return
        end
        loaded = true
        M.state = Init.jdec(fs.read(file())) or {}
    end

    function M.save()
        if pending then
            return
        end
        pending = true
        task.delay(0.4, function()
            pending = false
            fs.dir(lib.dir)
            fs.write(file(), Init.jenc(M.state) or "{}")
        end)
    end

    -- colors edited by hand on top of the chosen theme
    local function applycolors()
        local cols = M.state.colors
        if type(cols) ~= "table" then
            return
        end
        local t = {}
        for k, h in pairs(cols) do
            local ok, c = pcall(Color3.fromHex, h)
            if ok and typeof(c) == "Color3" then
                t[k] = c
            end
        end
        lib:applytheme(t)
    end

    -- restores the saved state (first launch: Compact preset)
    function M.apply()
        load()
        local s = M.state
        if s.theme and not themes.apply(s.theme) then
            s.theme = nil
        end
        applycolors()
        if type(s.scale) == "number" then
            lib:setscale(s.scale)
        elseif not presets.apply(s.preset or "Compact") then
            presets.apply("Compact")
        end
        s.wm = watermark.apply(s.wm)
    end

    function M.build(win, opts)
        opts = opts or {}
        M.apply()
        local s = M.state

        local tab = win:tab({
            name = opts.name or "UI Settings",
            icon = opts.icon or "sliders",
            save = false,
        })

        -- menu: preset + DPI scale
        local menu = tab:section({ name = "Menu", side = 1 })
        local dpi
        menu:dropdown({
            name = "Preset",
            flag = "ui_preset",
            nocfg = true,
            values = presets.order,
            default = presets.current,
            cb = function(v)
                if presets.apply(v) then
                    s.preset, s.scale = v, nil
                    if dpi then
                        dpi:set(lib:getscale(), true)
                    end
                    M.save()
                end
            end,
        })
        dpi = menu:slider({
            name = "DPI scale",
            flag = "ui_dpi",
            nocfg = true,
            release = true,
            min = 0.5,
            max = 1.5,
            dec = 2,
            default = lib:getscale(),
            cb = function(v)
                lib:setscale(v)
                s.scale = v
                M.save()
            end,
        })

        -- theme: preset list + color editor
        local th = tab:section({ name = "Theme", side = 1 })
        local pickers = {}
        local tdrop

        local function sync()
            for k, el in pairs(pickers) do
                el:set(lib.thm[k], nil, true)
            end
        end

        tdrop = th:dropdown({
            name = "Theme",
            flag = "ui_theme",
            nocfg = true,
            values = themes.names(),
            default = s.theme or "MemeSense",
            cb = function(v)
                if themes.apply(v) then
                    s.theme, s.colors = v, nil
                    sync()
                    M.save()
                end
            end,
        })
        for _, k in ipairs(themes.keyorder) do
            pickers[k] = th:colorpicker({
                name = themes.keys[k],
                flag = "ui_th_" .. k,
                nocfg = true,
                default = lib.thm[k],
                cb = function(v)
                    lib:applytheme({ [k] = v })
                    s.colors = s.colors or {}
                    s.colors[k] = v:ToHex()
                    M.save()
                end,
            })
        end

        -- theme configs: save / delete your own themes
        local cfg = tab:section({ name = "Theme configs", side = 2 })
        local nm = cfg:input({
            flag = "ui_th_name",
            nocfg = true,
            placeholder = "Theme name",
        })
        cfg:button({
            name = "Save current colors",
            cb = function()
                local n = themes.save(nm.val)
                if not n then
                    lib:notify("Enter a valid theme name")
                    return
                end
                tdrop:setvalues(themes.names())
                tdrop:set(n, true)
                s.theme, s.colors = n, nil
                M.save()
                lib:notify("Theme saved: " .. n)
            end,
        })
        cfg:button({
            name = "Delete selected",
            cb = function()
                local n = tdrop.val
                if themes.builtin[n] then
                    lib:notify("Built-in themes can't be deleted")
                    return
                end
                themes.delete(n)
                themes.apply("MemeSense")
                tdrop:setvalues(themes.names())
                tdrop:set("MemeSense", true)
                s.theme, s.colors = nil, nil
                sync()
                M.save()
                lib:notify("Theme deleted: " .. tostring(n))
            end,
        })
        cfg:button({
            name = "Refresh list",
            cb = function()
                tdrop:setvalues(themes.names())
            end,
        })

        -- watermark
        watermark.section(tab, 2, s.wm, function(state)
            s.wm = state
            M.save()
        end)

        M.save()
        return tab
    end

    return M
end
