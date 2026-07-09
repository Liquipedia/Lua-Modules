---
-- @Liquipedia
-- page=Module:TournamentInputStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local I = HtmlWidgets.I
local Abbr = HtmlWidgets.Abbr

local DEFAULT_PLAYER_COUNT = Table.getByPathOrNil(Info, {'config', 'participants', 'defaultPlayerNumber'}) or 3

local PLAYER_INPUT = {
	MOUSE_KEYBOARD = 'Mouse & Keyboard',
	CONTROLLER = 'Controller',
	HYBRID = 'Hybrid',
	UNKNOWN = 'Unknown',
}

local TEAM_INPUT = {
	MIXED = 'Mixed',
}

local PLAYER_INPUT_ICON_DATA = {
	[PLAYER_INPUT.MOUSE_KEYBOARD] = {
		title = PLAYER_INPUT.MOUSE_KEYBOARD,
		iconClasses = {'fas', 'fa-mouse'},
	},
	[PLAYER_INPUT.CONTROLLER] = {
		title = PLAYER_INPUT.CONTROLLER,
		iconClasses = {'fas', 'fa-gamepad-alt'},
	},
	[PLAYER_INPUT.HYBRID] = {
		title = PLAYER_INPUT.HYBRID,
		iconClasses = {'fas', 'fa-keyboard'},
	},
	[PLAYER_INPUT.UNKNOWN] = {
		title = PLAYER_INPUT.UNKNOWN,
		iconClasses = {'fas', 'fa-question-circle'},
	},
}

---@type table<string, string>
local INPUT_SUMMARY_BADGE_CLASSES = {
	[PLAYER_INPUT.CONTROLLER] = 'forest-green-bg',
	[PLAYER_INPUT.MOUSE_KEYBOARD] = 'sapphire-bg',
	[PLAYER_INPUT.HYBRID] = 'vivid-violet-bg',
	[TEAM_INPUT.MIXED] = 'bright-sun-bg',
	[PLAYER_INPUT.UNKNOWN] = 'gray-bg',
}

---@class TournamentInputStats: BaseClass
---@field args table<string, any>
---@field tournamentPageNames string[]
---@field teamRows table[]
---@field totalPlayerCount integer
---@field lpdbInputsByPage table<string, string>
---@field manualFallbackInputsByPage table<string, string>
---@field playerCounts table<string, integer>
---@operator call(table<string, any>): TournamentInputStats
local TournamentInputStats = Class.new(function(self, args)
	self.args = args
	self.tournamentPageNames = self:_readTournamentPageNames(args)

	self.teamRows = {}
	self.totalPlayerCount = 0

	self.lpdbInputsByPage = {}
	self.manualFallbackInputsByPage = {}

	self.playerCounts = {
		[PLAYER_INPUT.MOUSE_KEYBOARD] = 0,
		[PLAYER_INPUT.CONTROLLER] = 0,
		[PLAYER_INPUT.HYBRID] = 0,
		[PLAYER_INPUT.UNKNOWN] = 0,
	}

	self:_readManualFallbackInputs()
end)

---@param frame Frame|table
---@return Renderable
function TournamentInputStats.run(frame)
	return TournamentInputStats(Arguments.getArgs(frame)):fetch():build()
end

---@private
---@param args table
---@return string[]
function TournamentInputStats:_readTournamentPageNames(args)
	local spec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()
	local pageNames = spec and spec.pageNames or {}

	local tournamentPageNames = Array.unique(Array.filter(
		Array.map(Array.flatten(pageNames), Page.pageifyLink),
		String.isNotEmpty
	)) --[[@as string[] ]]

	if Logic.isEmpty(tournamentPageNames) then
		local currentPage = Page.pageifyLink(mw.title.getCurrentTitle().prefixedText)
		if currentPage then
			return {currentPage}
		else
			return {}
		end
	end

	return tournamentPageNames
end

---@private
function TournamentInputStats:_readManualFallbackInputs()
	Table.iter.forEachPair(self.args, function(key, value)
		if type(key) ~= 'string' or not String.startsWith(key, 'input_') or String.isEmpty(value) then
			return
		end

		local pageName = Page.pageifyLink(key:sub(7))
		if pageName then
			self.manualFallbackInputsByPage[pageName] = self:_toPlayerInput(value)
		end
	end)
end

---@private
---@return string
function TournamentInputStats:_buildPlacementConditions()
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
			ConditionUtil.anyOf(ColumnName('pagename'), self.tournamentPageNames),
		}

	return tostring(conditions)
end

---@private
---@param input string?
---@return string
function TournamentInputStats:_toPlayerInput(input)
	if input == PLAYER_INPUT.MOUSE_KEYBOARD then
		return PLAYER_INPUT.MOUSE_KEYBOARD
	elseif input == PLAYER_INPUT.CONTROLLER then
		return PLAYER_INPUT.CONTROLLER
	elseif input == PLAYER_INPUT.HYBRID then
		return PLAYER_INPUT.HYBRID
	end

	return PLAYER_INPUT.UNKNOWN
end

---@private
---@param pageName string?
---@param input string?
function TournamentInputStats:_storeLpdbInput(pageName, input)
	pageName = Page.pageifyLink(pageName)
	if not pageName then
		return
	end

	if Logic.isEmpty(self.lpdbInputsByPage[pageName]) then
		self.lpdbInputsByPage[pageName] = input or ''
	end
end

---@private
---@param players standardPlayer[]
function TournamentInputStats:_fetchLpdbInputs(players)
	local pageNames = Array.unique(Array.filter(
		Array.map(players, function(player)
			return Page.pageifyLink(player.pageName)
		end),
		String.isNotEmpty
	))

	if Logic.isEmpty(pageNames) then
		return
	end

	Lpdb.executeMassQuery('player', {
		conditions = tostring(ConditionUtil.anyOf(ColumnName('pagename'), pageNames)),
		query = 'pagename, extradata',
		limit = 5000,
	}, function(playerRecord)
		if playerRecord then
			self:_storeLpdbInput(
				playerRecord.pagename,
				Table.getByPathOrNil(playerRecord, {'extradata', 'input'})
			)
		end
	end)
end

---@private
---@param player standardPlayer
---@return string?
function TournamentInputStats:_getPlayerInput(player)
	local pageName = Page.pageifyLink(player.pageName)
	if not pageName then
		return nil
	end

	local lpdbInput = Logic.nilIfEmpty(self.lpdbInputsByPage[pageName])
	if lpdbInput then
		return lpdbInput --[[@as string]]
	end

	-- Manual fallback inputs are intentionally only used for redlinks.
	if not Page.exists(pageName) then
		return self.manualFallbackInputsByPage[pageName]
	end

	return nil
end

---@return self
function TournamentInputStats:fetch()
	---@type table[]
	local opponents = {}
	---@type standardPlayer[]
	local allPlayers = {}

	Lpdb.executeMassQuery('placement', {
		limit = 5000,
		conditions = self:_buildPlacementConditions(),
		query = 'opponentname, opponenttemplate, opponenttype, opponentplayers',
	}, function(placement)
		local opponent = Opponent.fromLpdbStruct(placement)
		local players = opponent and opponent.players
		if players and Logic.isNotEmpty(players) then
			table.insert(opponents, opponent)
			Array.forEach(players, function(player)
				if player and Logic.isNotEmpty(player.displayName) then
					table.insert(allPlayers, player)
				end
			end)
		end
	end)

	self:_fetchLpdbInputs(allPlayers)

	Array.forEach(opponents, function(opponent)
		local playerEntries = {}
		local players = opponent and opponent.players or {}

		for index = 1, math.min(#players, DEFAULT_PLAYER_COUNT) do
			local player = players[index]
			if player and Logic.isNotEmpty(player.displayName) then
				local input = self:_toPlayerInput(self:_getPlayerInput(player))

				self.playerCounts[input] = (self.playerCounts[input] or 0) + 1
				self.totalPlayerCount = self.totalPlayerCount + 1

				table.insert(playerEntries, {
					player = player,
					input = input,
				})
			end
		end

		if Logic.isNotEmpty(playerEntries) then
			table.insert(self.teamRows, {
				opponentName = opponent.name or Opponent.toName(opponent),
				opponentTemplate = opponent.template,
				playerEntries = playerEntries,
				teamInput = self:_summarizeTeamInputs(playerEntries),
			})
		end
	end)

	Array.sortInPlaceBy(self.teamRows, function(row)
		return mw.ustring.lower(row.opponentName or '')
	end)

	return self
end

---@private
---@param count integer
---@return string
function TournamentInputStats:_formatCountWithPercentage(count)
	if self.totalPlayerCount <= 0 then
		return tostring(count)
	end

	return count .. ' (' .. MathUtil.formatPercentage(count / self.totalPlayerCount, 1) .. ')'
end

---@private
---@param playerEntries table[]
---@return string
function TournamentInputStats:_summarizeTeamInputs(playerEntries)
	local hasMouseKeyboard = Array.any(playerEntries, function(entry)
		return entry.input == PLAYER_INPUT.MOUSE_KEYBOARD
	end)
	local hasController = Array.any(playerEntries, function(entry)
		return entry.input == PLAYER_INPUT.CONTROLLER
	end)
	local hasHybrid = Array.any(playerEntries, function(entry)
		return entry.input == PLAYER_INPUT.HYBRID
	end)

	local knownTypeCount = 0
	local lastKnownType = PLAYER_INPUT.UNKNOWN

	if hasMouseKeyboard then
		knownTypeCount = knownTypeCount + 1
		lastKnownType = PLAYER_INPUT.MOUSE_KEYBOARD
	end
	if hasController then
		knownTypeCount = knownTypeCount + 1
		lastKnownType = PLAYER_INPUT.CONTROLLER
	end
	if hasHybrid then
		knownTypeCount = knownTypeCount + 1
		lastKnownType = PLAYER_INPUT.HYBRID
	end

	if knownTypeCount == 0 then
		return PLAYER_INPUT.UNKNOWN
	elseif knownTypeCount == 1 then
		return lastKnownType
	else
		return TEAM_INPUT.MIXED
	end
end

---@private
---@param summaryValue string
---@return string
function TournamentInputStats:_getSummaryBadgeClass(summaryValue)
	local class = INPUT_SUMMARY_BADGE_CLASSES[summaryValue] or INPUT_SUMMARY_BADGE_CLASSES[PLAYER_INPUT.UNKNOWN]
	return class or 'gray-bg'
end

---@private
---@param input string
---@return Renderable
function TournamentInputStats:_buildInputIcon(input)
	local data = PLAYER_INPUT_ICON_DATA[input] or PLAYER_INPUT_ICON_DATA[PLAYER_INPUT.UNKNOWN]

	return Abbr{
		attributes = {title = data and data.title or input},
		children = I{
			classes = data and data.iconClasses or {'fas', 'fa-question-circle'},
			attributes = {['aria-hidden'] = 'true'},
		}
	}
end

---@private
---@param row table
---@return Renderable|string
function TournamentInputStats:_buildTeamDisplay(row)
	if String.isEmpty(row.opponentTemplate) then
		return tostring(row.opponentName or '-')
	end

	return OpponentDisplay.InlineTeamContainer{
		template = row.opponentTemplate,
		style = 'short',
	}
end

---@private
---@param row table
---@return table
function TournamentInputStats:_buildPlayersDisplay(row)
	return Array.interleave(Array.map(row.playerEntries, function(entry)
		return PlayerDisplay.InlinePlayer{
			player = entry.player,
			showFlag = false,
		}
	end), ', ')
end

---@private
---@param row table
---@return table
function TournamentInputStats:_buildInputsDisplay(row)
	return Array.interleave(Array.map(row.playerEntries, function(entry)
		return self:_buildInputIcon(entry.input)
	end), '&nbsp;')
end

---@private
---@param label string
---@param value integer
---@return Renderable
function TournamentInputStats:_buildSummaryBox(label, value)
	return Div{
		classes = {'stats-summary-card'},
		children = {
			Div{
				classes = {'stats-summary-card__subtitle'},
				children = label,
			},
			Div{
				classes = {'stats-summary-card__title'},
				children = self:_formatCountWithPercentage(value),
			},
		}
	}
end

---@private
---@return Renderable
function TournamentInputStats:_buildSummaryBoxes()
	return Div{
		classes = {'stats-summary-cards'},
		css = {
			['margin-bottom'] = '16px',
		},
		children = WidgetUtil.collect(
			self:_buildSummaryBox('Mouse & Keyboard Players', self.playerCounts[PLAYER_INPUT.MOUSE_KEYBOARD] or 0),
			self:_buildSummaryBox('Controller Players', self.playerCounts[PLAYER_INPUT.CONTROLLER] or 0),
			(self.playerCounts[PLAYER_INPUT.HYBRID] or 0) > 0
				and self:_buildSummaryBox('Hybrid Players', self.playerCounts[PLAYER_INPUT.HYBRID] or 0)
				or nil,
			(self.playerCounts[PLAYER_INPUT.UNKNOWN] or 0) > 0
				and self:_buildSummaryBox('Unknown', self.playerCounts[PLAYER_INPUT.UNKNOWN] or 0)
				or nil
		)
	}
end

---@private
---@param summaryValue string
---@return Renderable
function TournamentInputStats:_buildSummaryBadge(summaryValue)
	return Span{
		classes = {self:_getSummaryBadgeClass(summaryValue)},
		css = {
			display = 'inline-block',
			padding = '4px 14px',
			['border-radius'] = '999px',
			['font-weight'] = '600',
			['white-space'] = 'nowrap',
		},
		children = summaryValue,
	}
end

---@private
---@return Renderable?
function TournamentInputStats:_buildEmptyStateRow()
	if Logic.isNotEmpty(self.teamRows) then
		return nil
	end

	return TableWidgets.Row{
		children = TableWidgets.Cell{
			colspan = 4,
			css = {
				['font-style'] = 'italic',
				opacity = '0.7',
				['text-align'] = 'center',
			},
			children = 'No player input data found.',
		}
	}
end

---@return Renderable
function TournamentInputStats:build()
	local rows = Array.map(self.teamRows, function(row)
		return TableWidgets.Row{
			children = {
				TableWidgets.Cell{
					attributes = {['data-sort-value'] = row.opponentName or ''},
					children = self:_buildTeamDisplay(row),
				},
				TableWidgets.Cell{
					nowrap = false,
					children = self:_buildPlayersDisplay(row),
				},
				TableWidgets.Cell{
					align = 'center',
					children = self:_buildInputsDisplay(row),
				},
				TableWidgets.Cell{
					align = 'center',
					children = self:_buildSummaryBadge(row.teamInput),
				},
			}
		}
	end)

	local tableWidget = TableWidgets.Table{
		sortable = true,
		columns = {
			{align = 'left'},
			{align = 'left'},
			{align = 'center'},
			{align = 'center'},
		},
		children = {
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{children = 'Team'},
							TableWidgets.CellHeader{children = 'Players'},
							TableWidgets.CellHeader{children = 'Inputs'},
							TableWidgets.CellHeader{children = 'Team input'},
						}
					}
				}
			},
			TableWidgets.TableBody{
				children = WidgetUtil.collect(
					self:_buildEmptyStateRow(),
					rows
				)
			},
		}
	}

	return Div{
		css = {
			display = 'inline-block',
			['max-width'] = '100%',
		},
		children = {
			self:_buildSummaryBoxes(),
			tableWidget,
		}
	}
end

return TournamentInputStats
