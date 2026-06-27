---
-- @Liquipedia
-- page=Module:Widget/TournamentPlayerStats/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TournamentPlayerStatsTableProps
---@field players TournamentPlayerStats.Player[]

---@class TournamentPlayerStatsTable: Widget
---@operator call(TournamentPlayerStatsTableProps): TournamentPlayerStatsTable
local TournamentPlayerStatsTable = Class.new(Widget)

TournamentPlayerStatsTable.defaultProps = {
	players = {},
}

---@class TournamentPlayerStatsTableColumn
---@field key string
---@field label string

---@type TournamentPlayerStatsTableColumn[]
local COLUMNS = {
	{key = 'games', label = 'GP'},
	{key = 'kills', label = 'K'},
	{key = 'assists', label = 'A'},
	{key = 'knocks', label = 'Knocks'},
	{key = 'damage', label = 'Dmg dealt'},
	{key = 'damageTaken', label = 'Dmg taken'},
	{key = 'damageDiff', label = 'Dmg diff'},
}

---@param value number
---@return string
local function formatNumber(value)
	return MathUtil.formatRounded{value = value, precision = 0}
end

---@param key string
---@param value number?
---@return string
local function formatStat(key, value)
	if value == nil then
		return '-'
	end

	if key == 'damageDiff' then
		if value > 0 then
			return '+' .. formatNumber(value)
		elseif value == 0 then
			return '0'
		end
	end

	return formatNumber(value)
end

---@param player TournamentPlayerStats.Player
---@return Renderable
local function renderTeam(player)
	if Logic.isEmpty(player.team) then
		return '-'
	end

	return OpponentDisplay.InlineTeamContainer{
		template = player.team,
		style = 'icon',
	}
end

---@param player TournamentPlayerStats.Player
---@return Renderable
local function renderPlayer(player)
	return PlayerDisplay.InlinePlayer{
		player = player,
	}
end

---@param key string
---@param player TournamentPlayerStats.Player
---@return Renderable
local function renderStat(key, player)
	local value = player[key]
	local text = formatStat(key, value)

	if key ~= 'damageDiff' or value == nil or value == 0 then
		return text
	end

	return Html.Span{
		classes = {value > 0 and 'forest-green-text' or 'cinnabar-text'},
		children = text,
	}
end

---@param title string
---@param player TournamentPlayerStats.Player?
---@param stat string
---@return Renderable?
local function summaryCard(title, player, stat)
	local value = player and player[stat]
	if type(value) ~= 'number' or value <= 0 then
		return nil
	end

	return Html.Div{
		classes = {'stats-summary-card'},
		children = {
			Html.Div{
				classes = {'stats-summary-card__subtitle'},
				children = title,
			},
			Html.Div{
				classes = {'stats-summary-card__title'},
				children = (player.displayName or player.pageName or '-') .. ' (' .. formatNumber(value) .. ')',
			},
		},
	}
end

---@param players TournamentPlayerStats.Player[]
---@return Renderable?
local function summaryCards(players)
	if Logic.isEmpty(players) then
		return nil
	end

	local topKills = Array.maxBy(players, function(player)
		return {player.kills or 0, player.assists or 0, player.damage or 0}
	end)
	local topAssists = Array.maxBy(players, function(player)
		return {player.assists or 0, player.kills or 0, player.damage or 0}
	end)
	local topKnocks = Array.maxBy(players, function(player)
		return {player.knocks or 0, player.kills or 0, player.damage or 0}
	end)
	local topDamage = Array.maxBy(players, function(player)
		return {player.damage or 0, player.kills or 0, player.assists or 0}
	end)

	return Html.Div{
		classes = {'stats-summary-cards'},
		css = {['margin-bottom'] = '16px'},
		children = WidgetUtil.collect(
			summaryCard('Top Killer', topKills, 'kills'),
			summaryCard('Top Assists', topAssists, 'assists'),
			summaryCard('Top Damage', topDamage, 'damage'),
			summaryCard('Top Knocks', topKnocks, 'knocks')
		),
	}
end

---@param activeColumns TournamentPlayerStatsTableColumn[]
---@return fun(player: TournamentPlayerStats.Player): Renderable
local function buildRow(activeColumns)
	return function(player)
		return TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.Cell{children = renderTeam(player)},
			TableWidgets.Cell{
				attributes = {['data-sort-value'] = player.pageName or player.displayName},
				children = renderPlayer(player),
			},
			Array.map(activeColumns, function(column)
				return TableWidgets.Cell{
					attributes = {['data-sort-value'] = player[column.key] or -1},
					children = renderStat(column.key, player),
				}
			end)
		)}
	end
end

---@return Renderable?
function TournamentPlayerStatsTable:render()
	local players = self.props.players
	if Logic.isEmpty(players) then
		return nil
	end

	local activeColumns = Array.filter(COLUMNS, function(column)
		return Array.any(players, function(player)
			return player[column.key] ~= nil
		end)
	end)

	return Html.Div{
		css = {
			display = 'inline-block',
			['max-width'] = '100%',
		},
		children = {
			summaryCards(players),
			TableWidgets.Table{
				sortable = true,
				columns = WidgetUtil.collect(
					{align = 'center'},
					{align = 'left'},
					Array.map(activeColumns, function()
						return {
							align = 'right',
							sortType = 'number',
						}
					end)
				),
				children = {
					TableWidgets.TableHeader{children = {
						TableWidgets.Row{children = WidgetUtil.collect(
							TableWidgets.CellHeader{children = 'Team'},
							TableWidgets.CellHeader{children = 'Player'},
							Array.map(activeColumns, function(column)
								return TableWidgets.CellHeader{children = column.label}
							end)
						)}
					}},
					TableWidgets.TableBody{children = Array.map(players, buildRow(activeColumns))},
				},
			},
		},
	}
end

return TournamentPlayerStatsTable
