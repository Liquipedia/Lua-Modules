---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local OpponentDisplay = Lua.import('Module:OpponentDisplay')
local CustomPlayerDisplay = Lua.import('Module:Player/Display/Custom')

local CustomOpponentDisplay = Table.deepCopy(OpponentDisplay)

CustomOpponentDisplay.propTypes.InlineOpponent = TypeUtil.extendStruct(
	OpponentDisplay.propTypes.InlineOpponent,
	{
		showFaction = 'boolean?'
	}
)

--[[
Displays an opponent as an inline element. Useful for describing opponents in
prose.
]]
function CustomOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.InlineOpponent)
	local opponent = props.opponent

	if opponent.type == 'team' then
		return OpponentDisplay.InlineTeamContainer({
			flip = props.flip,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' then
		return OpponentDisplay.InlineOpponent(props)
	else -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return CustomOpponentDisplay.PlayerInlineOpponent(props)
	end
end

CustomOpponentDisplay.propTypes.BlockOpponent = TypeUtil.extendStruct(
	OpponentDisplay.propTypes.BlockOpponent,
	{
		showFaction = 'boolean?'
	}
)

--[[
Displays a player opponent (solo, duo, trio, or quad) as an inline element.
]]
function CustomOpponentDisplay.PlayerInlineOpponent(props)
	props.showFaction = props.showFaction ~= false
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		local node = CustomPlayerDisplay.InlinePlayer(
			Table.merge(props, {player = player})
		)
		return tostring(node)
	end)
	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	return mw.html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

return CustomOpponentDisplay
