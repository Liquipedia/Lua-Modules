local Lua = require('Module:Lua')
local WidgetFactory = Lua.import('Module:Widget/Factory')
local ____exports = {}
local Image = setmetatable(
    {},
    {__call = function(____, ____, ____bindingPattern0)
        local className
        local link
        local height
        local width
        local alt
        local src
        src = ____bindingPattern0.src
        alt = ____bindingPattern0.alt
        if alt == nil then
            alt = ""
        end
        width = ____bindingPattern0.width
        height = ____bindingPattern0.height
        link = ____bindingPattern0.link
        if link == nil then
            link = ""
        end
        className = ____bindingPattern0.className
        if className == nil then
            className = ""
        end
        local function generateResizing()
            if height ~= nil and width ~= nil then
                return ((("|" .. tostring(width)) .. "x") .. tostring(height)) .. "px"
            elseif width ~= nil then
                return ("|" .. tostring(width)) .. "px"
            elseif height ~= nil then
                return ("|x" .. tostring(height)) .. "px"
            else
                return ""
            end
        end
        local size = generateResizing()
        local wikiCode = (((((((("[[File:" .. src) .. size) .. "|link=") .. link) .. "|alt=") .. alt) .. "|class=") .. className) .. "]]"
        return wikiCode
    end}
)
____exports.default = Image
return ____exports
