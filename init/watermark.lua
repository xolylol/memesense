-- Watermark settings.

return function(Init)
    local lib = Init.lib
    local M = {}

    M.defaults = {
        on = true,
        show = { "Name", "FPS", "Ping", "Time" },
        text = "",
    }

    local function copy(t)
        local o = {}
        for k, v in pairs(t) do
            o[k] = v
        end
        return o
    end

    -- state: { on = bool, show = { ... }, text = string }
    function M.apply(state)
        local s = copy(M.defaults)
        if type(state) == "table" then
            for k, v in pairs(state) do
                s[k] = v
            end
        end
        lib:setwatermark(s)
        return s
    end

    -- builds the Watermark section on a tab
    -- onchange(state) is called after every change
    function M.section(tab, side, state, onchange)
        state = M.apply(state)
        local function changed()
            if onchange then
                onchange(state)
            end
        end
        local s = tab:section({ name = "Watermark", side = side or 2 })
        s:toggle({
            name = "Enable",
            flag = "ui_wm_on",
            nocfg = true,
            default = state.on == true,
            cb = function(v)
                state.on = v
                lib:setwatermark({ on = v })
                changed()
            end,
        })
        s:dropdown({
            name = "Show",
            flag = "ui_wm_show",
            nocfg = true,
            multi = true,
            icon = false,
            values = { "Name", "FPS", "Ping", "Time" },
            default = state.show,
            cb = function(v)
                state.show = v
                lib:setwatermark({ show = v })
                changed()
            end,
        })
        s:input({
            flag = "ui_wm_text",
            nocfg = true,
            placeholder = "Custom text...",
            cb = function(v)
                state.text = v
                lib:setwatermark({ text = v })
                changed()
            end,
        })
        s:button({
            name = "Reset position",
            cb = function()
                lib:resetwatermark()
            end,
        })
        return s
    end

    return M
end
