--[[
    MemeSense init
    Entry point. Loads the library and the UI-settings modules.

    Usage:
        local init = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/xolylol/memesense/main/init/init.lua"
        ))()
        local lib = init.lib

        local win = lib:window({ title = "Meme", title2 = "Sense" })
        -- ... your tabs ...
        init:settings(win)   -- adds the "UI Settings" tab

    Files (same paths as in the repo):
        memesense.lua        the GUI library
        init/init.lua        this file
        init/presets.lua     menu size presets (Compact, Large, Mobile...)
        init/themes.lua      themes and saved theme configs
        init/watermark.lua   watermark settings
        init/settings.lua    the "UI Settings" tab

    If a file exists in the executor workspace under the same path,
    it is used instead of downloading it from GitHub.
    Set getgenv().MEMESENSE_BASE to load from a fork.
]]

local genv = (getgenv and getgenv()) or _G

local BASE = genv.MEMESENSE_BASE
    or "https://raw.githubusercontent.com/xolylol/memesense/main/"

local HttpService = game:GetService("HttpService")

-- file helpers (safe on executors with missing functions)
local fs = {}

function fs.has(p)
    if type(isfile) ~= "function" then
        return false
    end
    local ok, r = pcall(isfile, p)
    return ok and r == true
end

function fs.read(p)
    if fs.has(p) then
        local ok, r = pcall(readfile, p)
        if ok and type(r) == "string" then
            return r
        end
    end
    return nil
end

function fs.write(p, s)
    if type(writefile) ~= "function" then
        return false
    end
    return (pcall(writefile, p, s))
end

function fs.dir(p)
    if type(isfolder) ~= "function" then
        return
    end
    if type(makefolder) ~= "function" then
        return
    end
    local ok, r = pcall(isfolder, p)
    if ok and not r then
        pcall(makefolder, p)
    end
end

function fs.del(p)
    if type(delfile) == "function" and fs.has(p) then
        pcall(delfile, p)
    end
end

function fs.list(p, ext)
    local out = {}
    if type(listfiles) ~= "function" then
        return out
    end
    local ok, r = pcall(listfiles, p)
    if not ok or type(r) ~= "table" then
        return out
    end
    for _, f in ipairs(r) do
        local n = tostring(f):match("([^/\\]+)%." .. ext .. "$")
        if n then
            out[#out + 1] = n
        end
    end
    table.sort(out)
    return out
end

-- json helpers
local function jenc(t)
    local ok, r = pcall(HttpService.JSONEncode, HttpService, t)
    return ok and r or nil
end

local function jdec(s)
    if type(s) ~= "string" then
        return nil
    end
    local ok, r = pcall(HttpService.JSONDecode, HttpService, s)
    return (ok and type(r) == "table") and r or nil
end

-- loading: workspace copy first, GitHub second
local function fetch(path)
    local src = fs.read(path)
    if src and src ~= "" then
        return src, "workspace"
    end
    local ok, res = pcall(function()
        return game:HttpGet(BASE .. path)
    end)
    if ok and type(res) == "string" and res ~= "" then
        return res, "GitHub"
    end
    error("[memesense] cannot load " .. path .. ": " .. tostring(res), 0)
end

local function import(path)
    local src, from = fetch(path)
    local fn, err = loadstring(src, "=" .. path)
    if not fn then
        error("[memesense] " .. path .. " compile error: " .. tostring(err), 0)
    end
    return fn(), from
end

local Init = {
    version = "1.0.0",
    BASE = BASE,
    fs = fs,
    jenc = jenc,
    jdec = jdec,
    import = import,
}

local lib, from = import("memesense.lua")
Init.lib = lib
print("[memesense] library loaded from " .. from
    .. " (build " .. tostring(lib.BuildVersion) .. ")")

local function loadmod(name)
    return (import("init/" .. name .. ".lua"))(Init)
end

-- order matters: themes must snapshot the default colors first
Init.themes = loadmod("themes")
Init.presets = loadmod("presets")
Init.watermark = loadmod("watermark")
Init.ui = loadmod("settings")

-- apply saved preset / theme / watermark without building any UI
function Init:setup()
    return self.ui.apply()
end

-- apply saved state and add the "UI Settings" tab to the window
function Init:settings(win, opts)
    return self.ui.build(win, opts)
end

return Init
