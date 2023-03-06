---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})

local TierCustom = Table.copy(Tier)

--- Converts input to standardized identifier format
---@param input string|integer|nil
---@return string|integer|nil
function TierCustom.toIdentifier(input)
	if String.isEmpty(input) then
		return
	end

	return tonumber(input)
		or Tier.toNumber(input)
		or string.lower(input):gsub(' ', '')
end

return TierCustom
