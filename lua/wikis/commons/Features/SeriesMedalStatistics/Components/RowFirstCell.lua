---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Components/RowFirstCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Types = Lua.import('Module:Features/SeriesMedalStatistics/Types')

local RowFirstCell = {}

---@param statsType string
---@param opponents standardOpponent[]
---@return fun(key: string|table):(string|number|Html|VNode|Widget)?
function RowFirstCell.run(statsType, opponents)
	if statsType == Types.statsTypes.FACTION then
		return function(faction)
			---@cast faction string?
			return Faction.Icon{faction = faction, showLink = false} .. ' ' .. Faction.toName(faction)
		end
	elseif statsType == Types.statsTypes.FLAG then
		return function(flag)
			---@cast flag string?
			return Flags.Icon{flag = flag, shouldLink = false} .. ' ' .. Flags.CountryName{flag = flag}
		end
	elseif statsType == Types.statsTypes.PARTICIPANT then
		return function(identifier)
			return OpponentDisplay.BlockOpponent{opponent = opponents[identifier]}
		end
	elseif statsType == Types.statsTypes.PARTICIPANT_TEAM then
		return function(identifier)
			return OpponentDisplay.BlockOpponent{opponent = Opponent.readOpponentArgs{
				type = Opponent.team,
				template = identifier,
			}}
		end
	end
end

return RowFirstCell
