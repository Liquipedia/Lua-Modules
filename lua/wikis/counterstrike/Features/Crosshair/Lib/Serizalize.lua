local Lua = require('Module:Lua')
local bit32 = require('bit32')

local Base57 = Lua.import('Module:Features/Crosshair/Lib/Base57')
local Utils = Lua.import('Module:Features/Crosshair/Lib/Utils')

---@class CrosshairCs2V1Parser : CrosshairSerializer
local CrosshairCs2V1Parser = {}

---@param crosshair Crosshair
---@return string?
function CrosshairCs2V1Parser.encode(crosshair)
end

---@param input string
---@return Crosshair?
function CrosshairCs2V1Parser.decode(input)
end

---@class CrosshairLegacyV1Parser : CrosshairSerializer
local CrosshairLegacyV1Parser = {}

---@param crosshair Crosshair
---@return string?
function CrosshairLegacyV1Parser.encode(crosshair)
end

---@param input string
---@return Crosshair
function CrosshairLegacyV1Parser.decode(input)
    if #input ~= 34 then
        error("Sharecode with invalid length: should be 34 characters")
    end
    if input:sub(1, 4) ~= 'CSGO' then
        error("Sharecode is not prefixed with CSGO")
    end

    -- Remove CSGO prefix and "-" separators
    local sharecode = input:gsub("CSGO", ""):gsub("-", "")
    local bytes = Base57.decode(sharecode)
    assert(bytes, "Base57 decoding failed")

    local checksum = bytes[1]
    assert(checksum == Utils.eightBitChecksum(bytes), "Checksum did not match")

    assert(bytes[2] == 1, "Unexpected version (not 1)")

    ---@type Crosshair
    return {
        gap = bytes[3] / 10,
        outline = bit32.band(bytes[4] / 2, 7)
    }
end

return {
    Cs2V1 = CrosshairCs2V1Parser,
    LegacyV1 = CrosshairLegacyV1Parser
}