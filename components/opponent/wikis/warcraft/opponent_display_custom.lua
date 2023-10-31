---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent/Custom', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display/Custom', {requireDevIfEnabled = true})

local CustomOpponentDisplay = Table.merge(OpponentDisplay, {propTypes = {}, types={}})

CustomOpponentDisplay.propTypes.InlineOpponent = TypeUtil.extendStruct(OpponentDisplay.propTypes.InlineOpponent, {
	opponent = MatchGroupUtil.types.GameOpponent,
	showRace = 'boolean?',
})

---Display component for an opponent entry appearing in a bracket match.
---@class WarcraftBracketOpponentEntry
---@operator call(...): WarcraftBracketOpponentEntry
---@field content Html
---@field root Html
CustomOpponentDisplay.BracketOpponentEntry = Class.new(
	---@param self self
	---@param opponent WarcraftStandardOpponent
	---@param options {forceShortName: boolean}
	function(self, opponent, options)
		local showRaceBackground = opponent.type == Opponent.solo or opponent.extradata.hasRaceOrFlag

		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')
			:addClass(showRaceBackground and Faction.bgClass(opponent.players[1].race) or nil)

		if opponent.type == Opponent.team then
			self.content:node(OpponentDisplay.BlockTeamContainer({
				showLink = false,
				style = 'hybrid',
				team = opponent.team,
				template = opponent.template,
			}))
		else
			self.content:node(CustomOpponentDisplay.BlockOpponent({
				opponent = opponent,
				overflow = 'ellipsis',
				playerClass = 'starcraft-bracket-block-player',
				showLink = false,
				showRace = not showRaceBackground,
			}))
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

CustomOpponentDisplay.BracketOpponentEntry.addScores = OpponentDisplay.BracketOpponentEntry.addScores

---@class WarcraftInlineOpponentProps: InlineOpponentProps
---@field opponent WarcraftStandardOpponent
---@field showRace boolean?

---@param props WarcraftInlineOpponentProps
---@return Html|string|nil
function CustomOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.InlineOpponent)
	local opponent = props.opponent

	if Opponent.typeIsParty((opponent or {}).type) then
		return CustomOpponentDisplay.InlinePlayers(props)
	end

	return OpponentDisplay.InlineOpponent(props)
end

CustomOpponentDisplay.propTypes.BlockOpponent = TypeUtil.extendStruct(OpponentDisplay.propTypes.BlockOpponent, {
	opponent = MatchGroupUtil.types.GameOpponent,
	showRace = 'boolean?',
	playerClass = 'string?',
})

---@class WarcraftBlockOpponentProps: BlockOpponentProps
---@field opponent WarcraftStandardOpponent
---@field showRace boolean?

---@param props WarcraftBlockOpponentProps
---@return Html
function CustomOpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.BlockOpponent)
	local opponent = props.opponent

	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.literal and opponent.extradata.hasRaceOrFlag then
		return CustomOpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	elseif Opponent.typeIsParty((opponent or {}).type) then
		return CustomOpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	end

	return OpponentDisplay.BlockOpponent(props)
end

---@param props WarcraftInlineOpponentProps
---@return Html
function CustomOpponentDisplay.InlinePlayers(props)
	local showRace = props.showRace ~= false
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		return tostring(PlayerDisplay.InlinePlayer(Table.merge(props, {player = player, showRace = showRace})))
	end)

	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	return mw.html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

---@param props WarcraftBlockOpponentProps
---@return Html
function CustomOpponentDisplay.BlockPlayers(props)
	local opponent = props.opponent
	local showRace = props.showRace ~= false

	--only apply note to first player, hence extract it here
	local note = Table.extract(props, 'note')

	local playerNodes = Array.map(opponent.players, function(player, playerIndex)
		return PlayerDisplay.BlockPlayer(Table.merge(props, {
			team = player.team,
			player = player,
			showRace = showRace,
			note = playerIndex == 1 and note or nil,
		})):addClass(props.playerClass)
	end)

	local playersNode = mw.html.create('div')
		:addClass(props.showPlayerTeam and 'player-has-team' or nil)

	for _, playerNode in ipairs(playerNodes) do
		playersNode:node(playerNode)
	end

	return playersNode
end

return CustomOpponentDisplay
