-- UiLib Advanced Example
-- A "super in-depth" example demonstrating many of the library features:
-- - Pages, SubPages, Sections
-- - Toggles, Keybinds, Sliders, Dropdowns, Multi Dropdowns
-- - Colorpickers that update Library theme items live
-- - Theme presets (save/load/export)
-- - Config management (create/load/save/delete)
-- - Notifications, threads, SafeCall usage
-- - A scripting executor and a few tiny utility helpers

-- Load library (same as example)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YhRyptix/Ui-Library/refs/heads/main/ogGM_pzr3ybWsd.lua"))()
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Utility helpers
local function Notify(title, desc, dur)
    Library:Notification(title, desc or "", dur or 4)
end

local function SafeRun(fn)
    return Library:SafeCall(fn)
end

-- Create Window
local Window = Library:Window({
    Logo = "123748867365417",
    FadeSpeed = 0.2,
    PagePadding = 18,
    Size = UDim2.new(0, 780, 0, 520)
})

-- Pages
local Pages = {
    ["Main"] = Window:Page({Icon = "109391165290124", Search = true}),
    ["Settings"] = Window:Page({Icon = "72974659157165", Search = false}),
    ["Scripting"] = Window:Page({Icon = "82402610527668", Search = true}),
    ["Utilities"] = Window:Page({Icon = "129960652808688", Search = true}),
}

-- =========================
-- Main Page: Controls demo
-- =========================
local MainSub = Pages["Main"]:SubPage({Name = "Primary"})
local MainLeft = MainSub:Section({Name = "General", Side = "Left"})
local MainRight = MainSub:Section({Name = "Advanced", Side = "Right"})

-- Toggle with keybind (holds a background thread doing a demo action)
local DemoRunning = false
local AutoNotifyThread = nil
local Toggle = MainLeft:Toggle({
    Name = "Enable Demo Loop",
    Flag = "EnableDemoLoop",
    Default = false,
    Callback = function(val)
        DemoRunning = val
        if DemoRunning then
            Notify("Demo", "Demo loop enabled", 2)
            -- spawn a thread that shows notifications every 6s while enabled
            AutoNotifyThread = Library:Thread(function()
                while DemoRunning do
                    Notify("Demo Tick", "Demo loop is running — show something or run your code here", 3)
                    task.wait(6)
                end
            end)
        else
            Notify("Demo", "Demo loop disabled", 2)
        end
    end
})

Toggle:Keybind({
    Name = "Demo Keybind",
    Flag = "DemoKeybind",
    Default = Enum.KeyCode.G,
    Mode = "Toggle",
    Callback = function(held)
        Notify("Keybind", "Demo keybind toggled: " .. tostring(held), 2)
    end
})

-- Colorpicker that updates library theme Accent dynamically (and shows hex)
MainLeft:Label("Theme Accent", "Left"):Colorpicker({
    Name = "Accent Color",
    Flag = "AccentColor",
    Default = Library.Theme.Accent,
    Callback = function(value, alpha)
        -- value is Color3
        Library:ChangeTheme("Accent", value)
        Notify("Theme", "Accent updated", 1)
    end
})

-- Slider + Dropdown combo
MainLeft:Slider({
    Name = "Demo Intensity",
    Flag = "DemoIntensity",
    Min = 0, Default = 20, Max = 100, Suffix = "%", Decimals = 0,
    Callback = function(val)
        -- Use value somewhere in your logic
        -- Example: change the frequency of the demo notifications
        Notify("Intensity", "Set to " .. tostring(val) .. "%", 1)
    end
})

MainLeft:Dropdown({
    Name = "Mode",
    Flag = "DemoMode",
    Items = {"Normal", "Stealth", "Aggressive"},
    Multi = false,
    MaxSize = 25,
    Callback = function(value)
        Notify("Mode", "Selected: " .. tostring(value), 1)
    end
})

-- Right Section: Advanced interactions
MainRight:Button({
    Name = "Send Test Notification",
    Callback = function()
        Library:Notification("Test", "This notification demonstrates the theme and animations.", 4)
    end
})

-- Button with SubButton and example usage
MainRight:Button({
    Name = "Theme Preset",
    Callback = function()
        Notify("Theme Preset", "Use the subbutton to save current theme as a preset.", 3)
    end
}):SubButton({
    Name = "Save Preset",
    Callback = function()
        local Name = "preset_" .. os.date("%Y%m%d_%H%M%S")
        local ok, err = pcall(function()
            if not isfolder(Library.Folders.Themes) then makefolder(Library.Folders.Themes) end
            writefile(Library.Folders.Themes .. "/" .. Name .. ".json", HttpService:JSONEncode(Library.Theme))
        end)
        if ok then Notify("Saved", "Theme preset saved: " .. Name, 3) else Notify("Error", tostring(err), 4) end
    end
})

-- Colorpicker palette with live preview panel (the preview frame will auto-update with theme changes)
local Preview = Instance.new("Frame")
Preview.Name = "UiLib_Preview"
Preview.Size = UDim2.new(0, 120, 0, 60)
Preview.Position = UDim2.new(0, 0, 0, 0)
Preview.AnchorPoint = Vector2.new(0, 0)
Preview.BackgroundColor3 = Library.Theme["Accent"]
Preview.BorderSizePixel = 0
Preview.ZIndex = 2

-- Parent the preview inside the "Advanced" section so it follows the window (instead of top-right of the screen)
if MainRight and MainRight.Instance then
    Preview.Parent = MainRight.Instance
else
    Preview.Parent = Library.Holder.Instance -- fallback
end

-- Add to library theme so Library:ChangeTheme updates it
Library:AddToTheme(Preview, {BackgroundColor3 = "Accent"})

MainRight:Label("Preview", "Left")

-- =========================
-- Settings page: Configs + Theming
-- =========================
local SettingsSub = Pages["Settings"]:SubPage({Name = "Settings"})
local ThemeSection = SettingsSub:Section({Name = "Theming", Side = "Left"})
local ConfigsSection = SettingsSub:Section({Name = "Configs", Side = "Right"})

-- Dynamic theming controls: one colorpicker per theme key
for Key, Value in Library.Theme do
    ThemeSection:Label(Key, "Left"):Colorpicker({
        Name = Key,
        Flag = "Theme_" .. Key,
        Default = Value,
        Callback = function(val)
            Library:ChangeTheme(Key, val)
        end
    })
end

-- Theme import/export utilities
ThemeSection:Textbox({
    Name = "Preset Name",
    Default = "",
    Flag = "ThemePresetName",
    Placeholder = "my-theme",
    Callback = function(val) end
})

ThemeSection:Button({
    Name = "Export Theme",
    Callback = function()
        local Name = Library.Flags["ThemePresetName"] or ("theme_" .. os.date("%Y%m%d_%H%M%S"))
        if not isfolder(Library.Folders.Themes) then makefolder(Library.Folders.Themes) end
        local exportTheme = {}
        for k,v in Library.Theme do
            local ok, typ = pcall(function() return typeof(v) end)
            if ok and typ == "Color3" then
                exportTheme[k] = { r = math.floor(v.R * 255), g = math.floor(v.G * 255), b = math.floor(v.B * 255) }
            else
                exportTheme[k] = v
            end
        end
        writefile(Library.Folders.Themes .. "/" .. Name .. ".json", HttpService:JSONEncode(exportTheme))
        Notify("Export", "Theme exported as " .. Name, 3)
    end
}):SubButton({
    Name = "Import Theme",
    Callback = function()
        -- Choose a theme file (simple example: take first file in Themes folder)
        if not isfolder(Library.Folders.Themes) then Notify("Import", "No themes folder", 3); return end
        local files = listfiles(Library.Folders.Themes)
        if #files < 1 then Notify("Import", "No theme files found", 3); return end
        local file = files[1]
        local data = readfile(file)
        local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok and decoded then
            for k,v in decoded do
                if type(v) == "table" and v.r and v.g and v.b then
                    Library:ChangeTheme(k, Color3.fromRGB(v.r, v.g, v.b))
                else
                    Library:ChangeTheme(k, v)
                end
            end
            Notify("Import", "Imported theme from " .. file, 3)
        else
            Notify("Error", "Failed to import theme: malformed JSON", 4)
        end
    end
})

-- Configs: showcase config listing, save/load/delete
local ConfigsDropdown = ConfigsSection:Dropdown({
    Name = "Configs",
    Flag = "ConfigsList",
    Items = {},
    Multi = false,
    MaxSize = 80,
    Callback = function(val)
        Library.Flags["ConfigsList_Selected"] = val
    end
})

-- Try to populate the dropdown now (safe when folder exists)
if ConfigsDropdown then
    Library:RefreshConfigsList(ConfigsDropdown)
end

ConfigsSection:Textbox({
    Name = "Config Name",
    Default = "",
    Flag = "NewConfigName",
    Placeholder = "my_config",
    Callback = function(v) end
})

ConfigsSection:Button({
    Name = "Create Config",
    Callback = function()
        local name = Library.Flags["NewConfigName"]
        if not name or name == "" then Notify("Error", "Please enter a name", 2); return end
        if not isfolder(Library.Folders.Configs) then makefolder(Library.Folders.Configs) end
        if isfile(Library.Folders.Configs .. "/" .. name .. ".json") then Notify("Error", "Config already exists", 3); return end
        writefile(Library.Folders.Configs .. "/" .. name .. ".json", Library:GetConfig())
        Notify("Saved", "Created config " .. name, 3)
        -- refresh list
        if ConfigsDropdown then Library:RefreshConfigsList(ConfigsDropdown) end
    end
}):SubButton({
    Name = "Save Current",
    Callback = function()
        local selected = Library.Flags["ConfigsList_Selected"]
        if not selected then Notify("Error", "Select a config to overwrite", 2); return end
        writefile(Library.Folders.Configs .. "/" .. selected, Library:GetConfig())
        Notify("Saved", "Saved config " .. selected, 3)
        if ConfigsDropdown then Library:RefreshConfigsList(ConfigsDropdown) end
    end
})

ConfigsSection:Button({
    Name = "Load Config",
    Callback = function()
        local selected = Library.Flags["ConfigsList_Selected"]
        if not selected then Notify("Error", "No config selected", 2); return end
        Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. selected))
        Notify("Loaded", "Loaded config " .. selected, 3)
    end
}):SubButton({
    Name = "Delete",
    Callback = function()
        local selected = Library.Flags["ConfigsList_Selected"]
        if not selected then Notify("Error", "No config selected", 2); return end
        delfile(Library.Folders.Configs .. "/" .. selected)
        Notify("Deleted", "Deleted config " .. selected, 3)
        if ConfigsDropdown then Library:RefreshConfigsList(ConfigsDropdown) end
    end
})

-- Utility to refresh configs dropdown (attempt to find the dropdown instance and call its Refresh)
Library:Thread(function()
    task.wait(0.25) -- give the UI a moment
    -- Refresh the real dropdown if it's available
    if ConfigsDropdown then
        Library:RefreshConfigsList(ConfigsDropdown)
    end
end)

-- =========================
-- Scripting Page: Execute quick scripts safely
-- =========================
local ScriptSub = Pages["Scripting"]:SubPage({Name = "Executor"})
local ExecutorSection = ScriptSub:Section({Name = "Quick Exec", Side = "Left"})

local code = "print(\"Hello from UiLib executor!\")"
ExecutorSection:Textbox({
    Name = "Lua Code",
    Flag = "LuaExecCode",
    Placeholder = "print('hello')",
    Default = code,
    Callback = function(v) end
})

ExecutorSection:Button({
    Name = "Run Code",
    Callback = function()
        local raw = Library.Flags["LuaExecCode"] or ""
        local ok, res = pcall(function()
            local f = loadstring(raw)
            if not f then error("Compilation failed") end
            return f()
        end)
        if ok then Notify("Executed", "Code ran successfully", 3) else Notify("Error", tostring(res), 6) end
    end
})

-- =========================
-- Utilities Page: helpful demos
-- =========================
local UtilSub = Pages["Utilities"]:SubPage({Name = "Helpers"})
local UtilsLeft = UtilSub:Section({Name = "General Helpers", Side = "Left"})

-- Rainbow Accent toggle: cycles the Accent color smoothly
local rainbowEnabled = false
UtilsLeft:Toggle({
    Name = "Rainbow Accent",
    Flag = "RainbowAccent",
    Default = false,
    Callback = function(v)
        rainbowEnabled = v
        if rainbowEnabled then
            Library:Thread(function()
                local t = 0
                while rainbowEnabled do
                    t = (t + 1) % 360
                    local h = t / 360
                    local col = Library.FromHSV and Color3.fromHSV(h, 0.9, 0.9) or Color3.new(1,1,1)
                    Library:ChangeTheme("Accent", col)
                    task.wait(0.03)
                end
            end)
        else
            Notify("Rainbow", "Stopped rainbow", 2)
        end
    end
})

-- Export a small status report about library flags (example of reading Library.Flags)
UtilsLeft:Button({
    Name = "Dump Flags (console)",
    Callback = function()
        for k,v in Library.Flags do
            print(k, v)
        end
        Notify("Flags", "Dumped to console", 2)
    end
})

-- Small demo of Library.SafeCall (wrap an unsafe function and show result)
UtilsLeft:Button({
    Name = "SafeCall Demo",
    Callback = function()
        local ok = Library:SafeCall(function()
            -- intentionally cause an error inside SafeCall
            error("Oops, this was caught safely")
        end)
        if not ok then Notify("SafeCall", "Error was handled (see notification)", 3) end
    end
})

-- Final: brief startup notification
Notify("UiLib Advanced Example", "Example loaded. Explore Pages -> Settings -> Scripting -> Utilities.", 6)

-- end of advanced example
