---
-- @Liquipedia
-- page=Module:GameTable/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')
local Opponent = Lua.import('Module:Opponent/Custom')

local CharacterGameTable = Lua.import('Module:GameTable/Character')

local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local MatchSummaryCharacters = Lua.import('Module:Widget/Match/Summary/Characters')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ValorantCharacterGameTable: CharacterGameTable
---@operator call(table): ValorantCharacterGameTable
local CustomCharacterGameTable = Class.new(CharacterGameTable, function (self)
	self.args.showBans = false

	if self.args.tableMode == Opponent.solo then
		self.isPickedByRequired = true
		self.args.showOnlyGameStats = true
		self.statsFromMatches = CharacterGameTable.statsFromMatches
	end
end)

---@param game CharacterGameTableGame
---@return number?
function CustomCharacterGameTable:getCharacterPick(game)
	if self.config.mode ~= Opponent.solo then
		return CharacterGameTable.getCharacterPick(self, game)
	end
	local aliases = self.config.aliases
	local found

	Array.forEach(game.opponents, function(opponent, opponentIndex)
		if found then return end
		Array.forEach(opponent.players, function(player, playerIndex)
			if found then return end
			if aliases[player.player] then
				game.pickedByplayer = playerIndex
				found = opponentIndex
				return
			end
		end)
	end)

	return found
end

---@return integer
function CustomCharacterGameTable:getNumberOfPicks()
	return 10
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CustomCharacterGameTable:getCharacterKey(opponentIndex, playerIndex)
	return 't' .. opponentIndex .. 'p' .. playerIndex .. 'agent'
end

---@protected
---@return table[]
function CustomCharacterGameTable:buildColumnDefinitions()
	local config = self.config
	return WidgetUtil.collect(
		{
			-- Date column
			align = 'left',
			sortType = 'number',
		},
		config.showTier and {align = 'left'} or nil,
		config.showType and {align = 'center'} or nil,
		config.showIcon and {
			align = 'center',
			unsortable = true,
		} or nil,
		{
			-- Tournament column
			align = 'left',
		},
		{
			-- Map column
			align = 'left',
		},
		config.showResult and WidgetUtil.collect(
			config.mode == Opponent.solo and {align = 'left'} or nil,
			config.mode ~= Opponent.team and {
				{align = 'right'}, -- Kills
				{align = 'right'}, -- Deaths
				{align = 'right'}, -- Assists
				{align = 'right'} -- Ratio
			} or nil,
			{
				-- Picks column
				align = 'center',
				unsortable = true,
			},
			{
				-- Team column
				align = 'center',
			},
			{
				-- Score column
				align = 'center',
			},
			{
				-- vs. Team column
				align = 'center',
			},
			{
				-- vs. Picks column
				align = 'center',
			}
		) or nil,
		config.showLength and {
			align = 'left',
		} or nil,
		config.showPatch and {
			align = 'left',
		} or nil,
		config.showVod and {
			align = 'left',
			unsortable = true,
		} or nil,
		config.showMatchPage and {
			align = 'center',
			unsortable = true,
		} or nil
	)
end

---@return Html
function CustomCharacterGameTable:headerRow()
	---@param text string?
	---@return Widget
	local makeHeaderCell = function(text)
		return TableWidgets.CellHeader{children = text}
	end

	local config = self.config

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			makeHeaderCell('Date'),
			config.showTier and makeHeaderCell('Tier') or nil,
			config.showType and makeHeaderCell('Type') or nil,
			config.showIcon and makeHeaderCell() or nil,
			makeHeaderCell('Tournament'),
			makeHeaderCell('Map'),
			config.showResult and WidgetUtil.collect(
				config.mode == Opponent.solo and makeHeaderCell('Pick') or nil,
				config.mode ~= Opponent.team and {
					makeHeaderCell('K'),
					makeHeaderCell('D'),
					makeHeaderCell('A'),
					makeHeaderCell('Ratio'),
				} or nil,
				makeHeaderCell(config.mode == Opponent.solo and 'Team Picks' or 'Picks'),
				makeHeaderCell(),
				makeHeaderCell('Score'),
				makeHeaderCell(),
				makeHeaderCell('vs. Picks')
			) or nil,
			config.showLength and makeHeaderCell('Length') or nil,
			config.showPatch and makeHeaderCell('Patch') or nil,
			config.showVod and TableWidgets.CellHeader{
				align = 'center',
				children = 'VOD'
			} or nil,
			config.showMatchPage and makeHeaderCell() or nil
		)}
	}}
end

---@param participant table
---@return string?
function CustomCharacterGameTable:_getRatio(participant)
	local kills = tonumber(participant.kills) or 0
	local deaths = tonumber(participant.deaths) or 0
	if deaths == 0 then
		return nil
	end

	return MathUtil.formatRounded{value = kills / deaths, precision = 1}
end

---@param match CharacterGameTableMatch
---@param game CharacterGameTableGame
---@return Widget[]?
function CustomCharacterGameTable:displayGame(match, game)
	---@param children Renderable|Renderable[]?
	---@return Table2Cell
	local makeCell = function (children)
		return TableWidgets.Cell{children = children}
	end

	local indexes = ((self.isCharacterTable and game.pickedBy == game.winner) or match.result.flipped) and {2, 1} or {1, 2}

	local opponent = match.opponents[indexes[1]]
	local opponentVs = match.opponents[indexes[2]]

	---@type Widget[]
	local cells = {makeCell(LinkWidget{link = game.map})}

	---@param cell Widget
	local function addCell(cell)
		table.insert(cells, cell)
	end

	if self.config.mode ~= Opponent.team then
		local participant = game.opponents[game.pickedBy].players[game.pickedByplayer]
		if self.config.mode == Opponent.solo then
			local index = Array.indexOf(game.picks[game.pickedBy], function (pick)
				return participant.agent == pick
			end)
			addCell(makeCell(index > 0 and MatchSummaryCharacters{
				characters = {table.remove(game.picks[game.pickedBy], index)}
			} or nil))
		end
		addCell(makeCell(participant and participant.kills or nil))
		addCell(makeCell(participant and participant.deaths or nil))
		addCell(makeCell(participant and participant.assists or nil))
		addCell(makeCell(participant and self:_getRatio(participant) or nil))
	end

	addCell(self:_displayCharacters(game, indexes[1], 'picks'))
	addCell(self:_displayOpponent(opponent, false))
	addCell(self:_displayScore(game, indexes[1], indexes[2]))
	addCell(self:_displayOpponent(opponentVs, true))
	addCell(self:_displayCharacters(game, indexes[2], 'picks'))

	return cells
end

---@param frame Frame
---@return Widget
function CustomCharacterGameTable.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomCharacterGameTable(args):readConfig():query():build()
end

return CustomCharacterGameTable
