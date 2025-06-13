---
-- @Liquipedia
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local CustomOpponentDisplay = Table.merge(OpponentDisplay, {propTypes = {}, types={}})

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
		local showFactionBackground = opponent.type == Opponent.solo or opponent.extradata.hasFactionOrFlag

		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')
			:addClass(showFactionBackground and Faction.bgClass(opponent.players[1].faction) or nil)

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
			}))
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

CustomOpponentDisplay.BracketOpponentEntry.addScores = OpponentDisplay.BracketOpponentEntry.addScores

---@class WarcraftInlineOpponentProps: InlineOpponentProps
---@field opponent WarcraftStandardOpponent
---@field showFaction boolean?

---@param props WarcraftInlineOpponentProps
---@return Html|nil
function CustomOpponentDisplay.InlineOpponent(props)
	local opponent = props.opponent

	if Opponent.typeIsParty((opponent or {}).type) then
		return mw.html.create()
			:node(CustomOpponentDisplay.InlinePlayers(props))
			:node(props.note and mw.html.create('sup'):addClass('note'):wikitext(props.note) or '')

	end

	return OpponentDisplay.InlineOpponent(props)
end

---@class WarcraftBlockOpponentProps: BlockOpponentProps
---@field opponent WarcraftStandardOpponent
---@field showFaction boolean?

---@param props WarcraftBlockOpponentProps
---@return Html
function CustomOpponentDisplay.BlockOpponent(props)
	local opponent = props.opponent

	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.literal and opponent.extradata.hasFactionOrFlag then
		return CustomOpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	elseif Opponent.typeIsParty((opponent or {}).type) then
		return CustomOpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	end

	return OpponentDisplay.BlockOpponent(props)
end

---@param props WarcraftInlineOpponentProps
---@return Html
function CustomOpponentDisplay.InlinePlayers(props)
	local showFaction = props.showFaction ~= false
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		return tostring(PlayerDisplay.InlinePlayer(Table.merge(props, {player = player, showFaction = showFaction})))
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
	local showFaction = props.showFaction ~= false

	--only apply note to first player, hence extract it here
	local note = Table.extract(props, 'note')

	local playerNodes = Array.map(opponent.players, function(player, playerIndex)
		return PlayerDisplay.BlockPlayer(Table.merge(props, {
			team = player.team,
			player = player,
			showFaction = showFaction,
			note = playerIndex == 1 and note or nil,
		})):addClass(props.playerClass)
	end)

	local playersNode = mw.html.create('div')
		:addClass('block-players-wrapper')

	for _, playerNode in ipairs(playerNodes) do
		playersNode:node(playerNode)
	end

	return playersNode
end

return CustomOpponentDisplay
