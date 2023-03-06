---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})

local NON_BREAKING_SPACE = '&nbsp;'

local TierCustom = Table.copy(Tier)

--- Converts input to standardized identifier format
---@param input string|integer|nil
---@return string|integer|nil
function TierCustom.toIdentifier(input)
	if String.isEmpty(input) then
		return
	end

	return tonumber(input)
		or Tier.legacyNumbers[string.lower(input):gsub(' ', '')]
		or string.lower(input):gsub(' ', '')
end

return TierCustom
