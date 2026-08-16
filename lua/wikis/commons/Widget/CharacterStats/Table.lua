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
local Dialog = Lua.import('Module:Widget/Basic/Dialog')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
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
	return TableWidgets.Table{
		css = {
			margin = 0,
			['text-align'] = 'center',
		},
		sortable = true,
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{
				children = self:_buildHeaderRow()
			},
			TableWidgets.TableBody{
				children = WidgetUtil.collect(
					Array.map(data, function (dataEntry, dataIndex)
						return self:_buildCharacterRow(dataEntry, dataIndex)
					end),
					self:_buildFooterRow()
				)
			}
		)
	}
end

---@private
---@return Widget[]
function CharacterStatsTable:_buildHeaderRow()
	return {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{colspan = 2},
			TableWidgets.CellHeader{colspan = 5, children = 'Picks'},
			Array.map(self.props.sides, function (side)
				return TableWidgets.CellHeader{colspan = 4, children = String.upperCaseFirst(side)}
			end),
			self.props.includeBans and {
				TableWidgets.CellHeader{
					colspan = self.props.includeGlobalBans and 4 or 2,
					children = 'Bans'
				},
				TableWidgets.CellHeader{
					colspan = 2,
					css = {['white-space'] = 'nowrap'},
					children = 'Picks & Bans'
				},
			} or nil,
			TableWidgets.CellHeader{
				rowspan = 2,
				children = 'Details'
			}
		)},
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{},
			TableWidgets.CellHeader{children = String.upperCaseFirst(self.props.characterType)},
			TableWidgets.CellHeader{children = '∑'},
			TableWidgets.CellHeader{children = 'W'},
			TableWidgets.CellHeader{children = 'L'},
			TableWidgets.CellHeader{children = 'WR'},
			TableWidgets.CellHeader{children = '%T'},
			Array.flatMap(self.props.sides, function (_)
				return {
					TableWidgets.CellHeader{children = '∑'},
					TableWidgets.CellHeader{children = 'W'},
					TableWidgets.CellHeader{children = 'L'},
					TableWidgets.CellHeader{children = 'WR'},
				}
			end),
			self.props.includeBans and WidgetUtil.collect(
				self.props.includeGlobalBans and {
					TableWidgets.CellHeader{children = '∑'},
					TableWidgets.CellHeader{children = Html.Abbr{title = 'Ban', children = 'B'}},
					TableWidgets.CellHeader{children = Html.Abbr{title = 'Global Ban', children = 'GB'}},
					TableWidgets.CellHeader{children = '%T'},
				} or {
					TableWidgets.CellHeader{children = '∑'},
					TableWidgets.CellHeader{children = '%T'},
				},
				TableWidgets.CellHeader{children = '∑'},
				TableWidgets.CellHeader{children = '%T'}
			) or nil
		)}
	}
end

---@private
---@param characterData CharacterStatistic
---@param characterIndex integer
---@return Widget
function CharacterStatsTable:_buildCharacterRow(characterData, characterIndex)
	return TableWidgets.Row{
		classes = {'character-stats-row'},
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = characterIndex},
			TableWidgets.Cell{
				css = {
					['text-align'] = 'left',
					['white-space'] = 'nowrap'
				},
				children = CharacterIcon.Icon{character = characterData.name, size = self.props.characterSize, addTextLink = true}
			},
			TableWidgets.Cell{
				css = {['font-weight'] = 'bolder'},
				children = characterData.total.pick
			},
			TableWidgets.Cell{children = characterData.total.win},
			TableWidgets.Cell{children = characterData.total.loss},
			TableWidgets.Cell{children = CharacterStatsTable._calculatePercentage(
				characterData.total.win, characterData.total.pick
			)},
			TableWidgets.Cell{children = CharacterStatsTable._calculatePercentage(
				characterData.total.pick, self.props.numGames
			)},
			Array.flatMap(self.props.sides, function (side)
				local picks = characterData.side[side].win + characterData.side[side].loss
				return {
					TableWidgets.Cell{
						css = {['font-weight'] = 'bolder'},
						children = picks
					},
					TableWidgets.Cell{children = characterData.side[side].win},
					TableWidgets.Cell{children = characterData.side[side].loss},
					TableWidgets.Cell{children = CharacterStatsTable._calculatePercentage(characterData.side[side].win, picks)}
				}
			end),
			self.props.includeBans and WidgetUtil.collect(
				self.props.includeGlobalBans and {
					TableWidgets.Cell{children = characterData.bans + characterData.globalBans},
					TableWidgets.Cell{children = characterData.bans},
					TableWidgets.Cell{children = characterData.globalBans},
					TableWidgets.Cell{children = CharacterStatsTable._calculatePercentage(
						characterData.bans + characterData.globalBans, self.props.numGames
					)},
				} or {
					TableWidgets.Cell{children = characterData.bans},
					TableWidgets.Cell{children = CharacterStatsTable._calculatePercentage(characterData.bans, self.props.numGames)},
				},
				TableWidgets.Cell{children = characterData.total.pick + characterData.bans + characterData.globalBans},
				TableWidgets.Cell{children = CharacterStatsTable._calculatePercentage(
					characterData.total.pick + characterData.bans, self.props.numGames
				)}
			) or nil,
			TableWidgets.Cell{children = Dialog{
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
	return TableWidgets.Table{
		sortable = true,
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{
				children = WidgetUtil.collect(
					Logic.isNotEmpty(props.title) and TableWidgets.Row{
						children = TableWidgets.CellHeader{
							colspan = 6,
							children = props.title
						}
					} or nil,
					TableWidgets.Row{children = {
						TableWidgets.CellHeader{},
						TableWidgets.CellHeader{children = props.entryType},
						TableWidgets.CellHeader{children = '∑'},
						TableWidgets.CellHeader{children = 'W'},
						TableWidgets.CellHeader{children = 'L'},
						TableWidgets.CellHeader{children = 'WR'}
					}}
				)
			},
			TableWidgets.TableBody{
				children = Array.map(props.entries, function (entry)
					return TableWidgets.Row{children = Array.map(entry, function (data)
						return TableWidgets.Cell{children = data}
					end)}
				end)
			}
		)
	}
end

---@private
---@return Widget[]
function CharacterStatsTable:_buildFooterRow()
	return WidgetUtil.collect(
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{
				classes = {'sortbottom'},
				colspan = 2
			},
			TableWidgets.CellHeader{
				classes = {'sortbottom'},
				colspan = 5,
				children = {
					self.props.numGames,
					' games played'
				}
			},
			Array.map(self.props.sides, function (side)
				local sideWin = self.props.sideWins[side]
				local sideLoss = self.props.numGames - sideWin
				return TableWidgets.CellHeader{
					classes = {'sortbottom', 'wikitable--' .. side .. '-bg'},
					colspan = 4,
					children = {
						sideWin .. ' W - ' .. sideLoss .. ' L',
						' ',
						'(' .. CharacterStatsTable._calculatePercentage(sideWin, self.props.numGames) .. ')'
					}
				}
			end),
			TableWidgets.CellHeader{
				classes = {'sortbottom'},
				colspan = self.props.includeBans and (self.props.includeGlobalBans and 7 or 5) or 1
			}
		)},
		self.props.statspage ~= mw.title.getCurrentTitle().prefixedText and TableWidgets.Row{
			children = TableWidgets.CellHeader{
				colspan = 22,
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
