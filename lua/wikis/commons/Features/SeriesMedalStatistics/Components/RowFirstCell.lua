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

local Component = Lua.import('Module:Widget/Component')

---@param props {statsType: string, opponents: standardOpponent[], identifier: string}
---@return Renderable
local render = function(props)
	local opponents = props.opponents
	local statsType = props.statsType
	local identifier = props.identifier

	if statsType == Types.statsTypes.FACTION then
		return Faction.Icon{faction = identifier, showLink = false} .. ' ' .. Faction.toName(identifier)
	elseif statsType == Types.statsTypes.FLAG then
		return Flags.Icon{flag = identifier, shouldLink = false} .. ' ' .. Flags.CountryName{flag = identifier}
	elseif statsType == Types.statsTypes.PARTICIPANT then
		return OpponentDisplay.BlockOpponent{opponent = opponents[identifier]}
	elseif statsType == Types.statsTypes.PARTICIPANT_TEAM then
		return OpponentDisplay.BlockOpponent{opponent = Opponent.readOpponentArgs{
			type = Opponent.team,
			template = identifier,
		}}
	end
	-- this case can not happen
	error('Invalid statsType')
end

return Component.component(render)
