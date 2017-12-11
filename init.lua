-- Systems CAN NOT be called draw or update
local lve = {}
lve.debugModes = {
    error = 1,
    warning = 2,
    info = 3
}

lve.debugText = {
    "[!] Error in function ",
    "[?] Warning in function ",
    "[ ] Info from function "
}

lve.debugMode = 0

local folderOfThisFile = (...)

local Engine = require(folderOfThisFile .. ".engine")(lve)
local System = require(folderOfThisFile .. ".system")(lve)

function lve.setDebugMode(debugMode)
    if lve.debugModes[debugMode] then
        lve.debugMode = lve.debugModes[debugMode]
    end
end

function lve.debug(debugType, functionName, message)
    if lve.debugModes[debugType] <= lve.debugMode then
        print(lve.debugText[lve.debugModes[debugType]] .. functionName .. "!  " .. message)
    end
end

function lve.newEngine()
    local newEngine = setmetatable({}, Engine)
    newEngine:init()

    return newEngine
end

function lve.newSystem(name)
    if not name then
        lve.debug("error", "lve.newSystem", "No system name provided!")
        return
    end

    if not type(name) == "string" then
        lve.debug("error", "lve.newSystem", "name is not of type string. Did you call lve:newSystem instead of lve.newSystem?")
        return
    end

    local newSystem = setmetatable({}, System)

    newSystem:init(name)

    return newSystem
end

function lve.newComponent(name)
    if not name then
        lve.debug("error", "lve.newComponent", "No component name provided!")
        return
    end

    if not type(name) == "string" then
        lve.debug("error", "lve.newComponent", "name is not of type string. Did you call lve:newComponent instead of lve.newComponent?")
        return
    end

    local newComponent = {}
    newComponent.type = "Component"
    newComponent.name = name

    return newComponent
end

return lve
