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
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DetailsPopup = Lua.import('Module:Widget/CharacterStats/DetailsPopup')
local DetailsPopupContainer = Lua.import('Module:Widget/CharacterStats/DetailsPopup/Container')
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
	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = HtmlWidgets.Table{
			classes = {'wikitable', 'table-striped', 'sortable'},
			css = {
				margin = 0,
				['text-align'] = 'center',
			},
			children = WidgetUtil.collect(
				self:_buildHeaderRow(),
				Array.map(data, function (dataEntry, dataIndex)
					return self:_buildCharacterRow(dataEntry, dataIndex)
				end),
				self:_buildFooterRow()
			)
		}
	}
end

---@private
---@return Widget
function CharacterStatsTable:_buildHeaderRow()
	return {
		HtmlWidgets.Tr{children = WidgetUtil.collect(
			HtmlWidgets.Th{attributes = {colspan = 2}},
			HtmlWidgets.Th{attributes = {colspan = 5}, children = 'Picks'},
			Array.map(self.props.sides, function (side)
				return HtmlWidgets.Th{attributes = {colspan = 4}, children = String.upperCaseFirst(side)}
			end),
			self.props.includeBans and {
				HtmlWidgets.Th{attributes = {colspan = 2}, children = 'Bans'},
				HtmlWidgets.Th{
					attributes = {colspan = 2},
					css = {['white-space'] = 'nowrap'},
					children = 'Picks & Bans'
				},
			} or nil,
			HtmlWidgets.Th{
				attributes = {rowspan = 2},
				classes = {'unsortable'},
				children = 'Details'
			}
		)},
		HtmlWidgets.Tr{children = WidgetUtil.collect(
			HtmlWidgets.Th{},
			HtmlWidgets.Th{children = String.upperCaseFirst(self.props.characterType)},
			HtmlWidgets.Th{children = '∑'},
			HtmlWidgets.Th{children = 'W'},
			HtmlWidgets.Th{children = 'L'},
			HtmlWidgets.Th{children = 'WR'},
			HtmlWidgets.Th{children = '%T'},
			Array.flatMap(Array.range(1, 2), function (_)
				return {
					HtmlWidgets.Th{children = '∑'},
					HtmlWidgets.Th{children = 'W'},
					HtmlWidgets.Th{children = 'L'},
					HtmlWidgets.Th{children = 'WR'},
				}
			end),
			self.props.includeBans and {
				HtmlWidgets.Th{children = '∑'},
				HtmlWidgets.Th{children = '%T'},
				HtmlWidgets.Th{children = '∑'},
				HtmlWidgets.Th{children = '%T'},
			} or nil
		)}
	}
end

---@private
---@param characterData CharacterStatistic
---@param characterIndex integer
---@return Widget
function CharacterStatsTable:_buildCharacterRow(characterData, characterIndex)
	return HtmlWidgets.Tr{
		classes = {'dota-stat-row'},
		children = WidgetUtil.collect(
			HtmlWidgets.Td{children = characterIndex},
			HtmlWidgets.Td{
				css = {
					['text-align'] = 'left',
					['white-space'] = 'nowrap'
				},
				children = CharacterIcon.Icon{character = characterData.name, size = self.props.characterSize, addTextLink = true}
			},
			HtmlWidgets.Td{
				css = {['font-weight'] = 'bolder'},
				children = characterData.total.pick
			},
			HtmlWidgets.Td{children = characterData.total.win},
			HtmlWidgets.Td{children = characterData.total.loss},
			HtmlWidgets.Td{children = CharacterStatsTable._calculatePercentage(
				characterData.total.win, characterData.total.pick
			)},
			HtmlWidgets.Td{children = CharacterStatsTable._calculatePercentage(
				characterData.total.pick, self.props.numGames
			)},
			Array.flatMap(self.props.sides, function (side)
				local picks = characterData.side[side].win + characterData.side[side].loss
				return {
					HtmlWidgets.Td{
						css = {['font-weight'] = 'bolder'},
						children = picks
					},
					HtmlWidgets.Td{children = characterData.side[side].win},
					HtmlWidgets.Td{children = characterData.side[side].loss},
					HtmlWidgets.Td{children = CharacterStatsTable._calculatePercentage(characterData.side[side].win, picks)}
				}
			end),
			self.props.includeBans and {
				HtmlWidgets.Td{children = characterData.bans},
				HtmlWidgets.Td{children = CharacterStatsTable._calculatePercentage(characterData.bans, self.props.numGames)},
				HtmlWidgets.Td{children = characterData.total.pick + characterData.bans},
				HtmlWidgets.Td{children = CharacterStatsTable._calculatePercentage(
					characterData.total.pick + characterData.bans, self.props.numGames
				)}
			} or nil,
			HtmlWidgets.Td{children = DetailsPopupContainer{
				children = DetailsPopup{
					header = CharacterIcon.Icon{
						character = characterData.name,
						size = self.props.characterSize,
						addTextLink = true
					},
					children = HtmlWidgets.Div{
						classes = {'dota-stat-popup-info'},
						children = {
							CharacterStatsTable._buildPlayedByTeamTable(characterData.playedBy),
							self:_buildPlayedTable('with', characterData.playedWith),
							self:_buildPlayedTable('against', characterData.playedVs)
						}
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
	return HtmlWidgets.Div{
		css = {flex = 'auto'},
		children = HtmlWidgets.Table{
			classes = {'wikitable', 'wikitable-striped', 'sortable'},
			css = {width = '100%'},
			children = WidgetUtil.collect(
				Logic.isNotEmpty(props.title) and HtmlWidgets.Tr{
					children = HtmlWidgets.Th{
						attributes = {colspan = 6},
						children = props.title
					}
				} or nil,
				HtmlWidgets.Tr{children = {
					HtmlWidgets.Th{},
					HtmlWidgets.Th{children = props.entryType},
					HtmlWidgets.Th{children = '∑'},
					HtmlWidgets.Th{children = 'W'},
					HtmlWidgets.Th{children = 'L'},
					HtmlWidgets.Th{children = 'WR'}
				}},
				Array.map(props.entries, function (entry)
					return HtmlWidgets.Tr{children = Array.map(entry, function (data)
						return HtmlWidgets.Td{children = data}
					end)}
				end)
			)
		}
	}
end

---@private
---@return Widget
function CharacterStatsTable:_buildFooterRow()
	return HtmlWidgets.Tr{children = WidgetUtil.collect(
		HtmlWidgets.Th{
			classes = {'sortbottom'},
			attributes = {colspan = 2}
		},
		HtmlWidgets.Th{
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
			return HtmlWidgets.Th{
				classes = {'sortbottom', 'wikitable--' .. side .. '-bg'},
				attributes = {colspan = 4},
				children = {
					sideWin .. ' W - ' ..  sideLoss .. ' L',
					' ',
					'(' .. CharacterStatsTable._calculatePercentage(sideWin, self.props.numGames) .. ')'
				}
			}
		end),
		HtmlWidgets.Th{
			classes = {'sortbottom'},
			attributes = {colspan = 5}
		}
	)}
end

---@param count integer
---@param total integer
---@return string
function CharacterStatsTable._calculatePercentage(count, total)
	if total == 0 then
		return '-'
	end
	return string.format('%.2f', MathUtil.round(count / total * 100, 2)) .. '%'
end

return CharacterStatsTable
