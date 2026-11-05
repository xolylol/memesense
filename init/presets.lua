-- Menu size presets.
-- Every preset only changes the menu DPI scale (and, for Mobile,
-- shows the round open button). Add your own entries to M.list.

return function(Init)
    local lib = Init.lib
    local M = {}

    M.order = { "Compact", "Default", "Large", "Mobile", "Auto" }

    -- scale = nil means "fit to the screen automatically"
    M.list = {
        Compact = { scale = 0.80 },
        Default = { scale = 1.00 },
        Large = { scale = 1.25 },
        Mobile = { scale = nil, mobilebtn = true },
        Auto = { scale = nil },
    }

    M.current = "Compact"

    function M.apply(name)
        local p = M.list[name]
        if not p then
            return false
        end
        lib:setscale(p.scale)
        if p.mobilebtn ~= nil then
            lib:setmobilebtn(p.mobilebtn)
        end
        M.current = name
        return true
    end

    return M
end
