---
-- @Liquipedia
-- page=Module:Widget/CharacterStats/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local Dialog = Lua.import('Module:Widget/Basic/Dialog')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CharacterStatsTable: Widget
---@operator call(CharacterStatsWidgetProps): CharacterStatsTable
---@field props CharacterStatsWidgetProps
local CharacterStatsTable = Class.new(Widget)

---@return Widget?
function CharacterStatsTable:render()
	local data = self.props.data
	if Logic.isEmpty(data) then
		return
	end
	if self.props.statspage ~= mw.title.getCurrentTitle().prefixedText then
		data = Array.sub(data, 1, 5)
	end
	return DataTable{
		classes = {'table-striped'},
		tableCss = {
			margin = 0,
			['text-align'] = 'center',
		},
		children = WidgetUtil.collect(
			self:_buildHeaderRow(),
			Array.map(data, function (dataEntry, dataIndex)
				return self:_buildCharacterRow(dataEntry, dataIndex)
			end),
			self:_buildFooterRow()
		),
		sortable = true
	}
end

---@private
---@return Widget
function CharacterStatsTable:_buildHeaderRow()
	return {
		Html.Tr{children = WidgetUtil.collect(
			Html.Th{attributes = {colspan = 2}},
			Html.Th{attributes = {colspan = 5}, children = 'Picks'},
			Array.map(self.props.sides, function (side)
				return Html.Th{attributes = {colspan = 4}, children = String.upperCaseFirst(side)}
			end),
			self.props.includeBans and {
				Html.Th{attributes = {colspan = 2}, children = 'Bans'},
				Html.Th{
					attributes = {colspan = 2},
					css = {['white-space'] = 'nowrap'},
					children = 'Picks & Bans'
				},
			} or nil,
			Html.Th{
				attributes = {rowspan = 2},
				classes = {'unsortable'},
				children = 'Details'
			}
		)},
		Html.Tr{children = WidgetUtil.collect(
			Html.Th{},
			Html.Th{children = String.upperCaseFirst(self.props.characterType)},
			Html.Th{children = '∑'},
			Html.Th{children = 'W'},
			Html.Th{children = 'L'},
			Html.Th{children = 'WR'},
			Html.Th{children = '%T'},
			Array.flatMap(Array.range(1, 2), function (_)
				return {
					Html.Th{children = '∑'},
					Html.Th{children = 'W'},
					Html.Th{children = 'L'},
					Html.Th{children = 'WR'},
				}
			end),
			self.props.includeBans and {
				Html.Th{children = '∑'},
				Html.Th{children = '%T'},
				Html.Th{children = '∑'},
				Html.Th{children = '%T'},
			} or nil
		)}
	}
end

---@private
---@param characterData CharacterStatistic
---@param characterIndex integer
---@return Widget
function CharacterStatsTable:_buildCharacterRow(characterData, characterIndex)
	return Html.Tr{
		classes = {'character-stats-row'},
		children = WidgetUtil.collect(
			Html.Td{children = characterIndex},
			Html.Td{
				css = {
					['text-align'] = 'left',
					['white-space'] = 'nowrap'
				},
				children = CharacterIcon.Icon{character = characterData.name, size = self.props.characterSize, addTextLink = true}
			},
			Html.Td{
				css = {['font-weight'] = 'bolder'},
				children = characterData.total.pick
			},
			Html.Td{children = characterData.total.win},
			Html.Td{children = characterData.total.loss},
			Html.Td{children = CharacterStatsTable._calculatePercentage(
				characterData.total.win, characterData.total.pick
			)},
			Html.Td{children = CharacterStatsTable._calculatePercentage(
				characterData.total.pick, self.props.numGames
			)},
			Array.flatMap(self.props.sides, function (side)
				local picks = characterData.side[side].win + characterData.side[side].loss
				return {
					Html.Td{
						css = {['font-weight'] = 'bolder'},
						children = picks
					},
					Html.Td{children = characterData.side[side].win},
					Html.Td{children = characterData.side[side].loss},
					Html.Td{children = CharacterStatsTable._calculatePercentage(characterData.side[side].win, picks)}
				}
			end),
			self.props.includeBans and {
				Html.Td{children = characterData.bans},
				Html.Td{children = CharacterStatsTable._calculatePercentage(characterData.bans, self.props.numGames)},
				Html.Td{children = characterData.total.pick + characterData.bans},
				Html.Td{children = CharacterStatsTable._calculatePercentage(
					characterData.total.pick + characterData.bans, self.props.numGames
				)}
			} or nil,
			Html.Td{children = Dialog{
				trigger = Button{
					children = 'Show',
					variant = 'secondary',
					size = 'xs',
				},
				title = CharacterIcon.Icon{
					character = characterData.name,
					size = self.props.characterSize,
					addTextLink = true
				} .. ' Detailed Statistics',
				children = Html.Div{
					classes = {'character-stats-popup-info'},
					children = {
						CharacterStatsTable._buildPlayedByTeamTable(characterData.playedBy),
						self:_buildPlayedTable('with', characterData.playedWith),
						self:_buildPlayedTable('against', characterData.playedVs)
					}
				}
			}}
		)
	}
end

---@param a CharacterAppearanceStats
---@param b CharacterAppearanceStats
---@return boolean
local function characterAppearanceStatsComparator(a, b)
	if a.pick ~= b.pick then
		return a.pick < b.pick
	elseif a.win ~= b.win then
		return a.win < b.win
	end
	return a.loss < b.loss
end

---@param data table<string, CharacterAppearanceStats>
function CharacterStatsTable._buildPlayedByTeamTable(data)
	local sortedTeamData = Array.sortBy(
		Table.entries(data), Operator.property(2), characterAppearanceStatsComparator
	)
	return CharacterStatsTable._buildDetailsTable{
		title = 'Played by Teams',
		entryType = 'Team',
		entries = Array.map(Array.sub(Array.reverse(sortedTeamData), 1, 5), function (teamData, index)
			return {
				index,
				OpponentDisplay.InlineTeamContainer{
					template = teamData[1],
					date = DateExt.getContextualDateOrNow(),
					style = 'short'
				},
				teamData[2].pick,
				teamData[2].win,
				teamData[2].loss,
				CharacterStatsTable._calculatePercentage(teamData[2].win, teamData[2].pick)
			}
		end)
	}
end

---@param data table<string, CharacterAppearanceStats>
function CharacterStatsTable:_buildPlayedTable(playedType, data)
	local sortedCharacterData = Array.sortBy(
		Table.entries(data), Operator.property(2), characterAppearanceStatsComparator
	)
	return CharacterStatsTable._buildDetailsTable{
		title = 'Played ' .. playedType,
		entryType = String.upperCaseFirst(self.props.characterType),
		entries = Array.map(Array.sub(Array.reverse(sortedCharacterData), 1, 5), function (characterData, index)
			return {
				index,
				CharacterIcon.Icon{
					character = characterData[1],
					size = self.props.characterSize,
					addTextLink = true
				},
				characterData[2].pick,
				characterData[2].win,
				characterData[2].loss,
				CharacterStatsTable._calculatePercentage(characterData[2].win, characterData[2].pick)
			}
		end)
	}
end

---@private
---@param props table
---@return Widget
function CharacterStatsTable._buildDetailsTable(props)
	return Html.Div{children = Html.Table{
		classes = {'wikitable', 'wikitable-striped', 'sortable'},
		css = {width = '100%'},
		children = WidgetUtil.collect(
			Logic.isNotEmpty(props.title) and Html.Tr{
				children = Html.Th{
					attributes = {colspan = 6},
					children = props.title
				}
			} or nil,
			Html.Tr{children = {
				Html.Th{},
				Html.Th{children = props.entryType},
				Html.Th{children = '∑'},
				Html.Th{children = 'W'},
				Html.Th{children = 'L'},
				Html.Th{children = 'WR'}
			}},
			Array.map(props.entries, function (entry)
				return Html.Tr{children = Array.map(entry, function (data)
					return Html.Td{children = data}
				end)}
			end)
		)
	}}
end

---@private
---@return Widget
function CharacterStatsTable:_buildFooterRow()
	return WidgetUtil.collect(
		Html.Tr{children = WidgetUtil.collect(
			Html.Th{
				classes = {'sortbottom'},
				attributes = {colspan = 2}
			},
			Html.Th{
				classes = {'sortbottom'},
				attributes = {colspan = 5},
				children = {
					self.props.numGames,
					' games played'
				}
			},
			Array.map(self.props.sides, function (side)
				local sideWin = self.props.sideWins[side]
				local sideLoss = self.props.numGames - sideWin
				return Html.Th{
					classes = {'sortbottom', 'wikitable--' .. side .. '-bg'},
					attributes = {colspan = 4},
					children = {
						sideWin .. ' W - ' .. sideLoss .. ' L',
						' ',
						'(' .. CharacterStatsTable._calculatePercentage(sideWin, self.props.numGames) .. ')'
					}
				}
			end),
			Html.Th{
				classes = {'sortbottom'},
				attributes = {colspan = 5}
			}
		)},
		self.props.statspage ~= mw.title.getCurrentTitle().prefixedText and Html.Tr{
			children = Html.Th{
				attributes = {colspan = 22},
				children = Link{
					link = self.props.statspage,
					children = Html.Small{children = 'Click here for complete statistics table'}
				}
			}
		}
	)
end

---@param count integer
---@param total integer
---@return string
function CharacterStatsTable._calculatePercentage(count, total)
	if total == 0 then
		return '-'
	end
	return MathUtil.formatPercentage(count / total, 2)
end

return CharacterStatsTable
