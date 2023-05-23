---
-- @Liquipedia
-- wiki=smash
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})

local TierCustom = Table.copy(Tier)

--- Builds the display for a given (tier, tierType) tuple
--- smash want to have tier displayed without tiertype
--- tiertype gets only stored and used for queries
---@param tier integer
---@param tierType string?
---@param options table?
---@return string?
function TierCustom.display(tier, tierType, options)
	local tierData = Tier.raw(tier, tierType)

	if not tierData then return end

	return Tier.displaySingle(tierData, Tier._displayOptions(options or {}, 'tier'))
end

return TierCustom
