---
-- @Liquipedia
-- page=Module:Widget/AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class AutomaticPointsTableWidgetProps
---@field opponents AutomaticPointsTableOpponent
---@field tournaments StandardTournament[]
---@field limit integer
---@field positionBackgrounds string[]

---@class AutomaticPointsTableWidget: Widget
---@operator call(AutomaticPointsTableWidgetProps): AutomaticPointsTableWidget
---@field props AutomaticPointsTableWidgetProps
local AutomaticPointsTableWidget = Class.new(Widget)

function AutomaticPointsTableWidget:render()
	return Div{
		classes = {'table-responsive', 'automatic-points-table'},
		children = Div{
			classes = {'fixed-size-table-container', 'border-color-grey'},
			css = {width = (450 + #self.props.tournaments * 50) .. 'px'},
			children = self:createTable()
		}
	}
end

function AutomaticPointsTableWidget:createTable()
	return Div{
		classes = {'divTable', 'border-color-grey', 'border-bottom'},
		children = WidgetUtil.collect(
			self:createHeader(),
			Array.map(self.props.opponents, function (opponent, opponentIndex)
				return self:createRow(opponent, opponentIndex)
			end)
		)
	}
end

---@param child string|Widget
---@param additionalClass string?
---@return Widget
function AutomaticPointsTableWidget._createHeaderCell(child, additionalClass)
	return Div{
		classes = {'divCell', 'diagonal-header-div-cell', additionalClass},
		children = Div{
			classes = {'border-color-grey', 'content'},
			children = child
		}
	}
end

function AutomaticPointsTableWidget:createHeader()
	local tournaments = self.props.tournaments

	return Div{
		classes = {'divHeaderRow', 'diagonal'},
		children = WidgetUtil.collect(
			AutomaticPointsTableWidget._createHeaderCell('Ranking','ranking'),
			AutomaticPointsTableWidget._createHeaderCell('Team', 'team'),
			AutomaticPointsTableWidget._createHeaderCell('Total Points'),
			Array.map(tournaments, function (tournament)
				return AutomaticPointsTableWidget._createHeaderCell(TournamentTitle{tournament = tournament})
			end)
		)
	}
end

---@param props {children: string|number|Widget|Html|(string|number|Widget|Html)[]?,
---additionalClasses: string[]?, background: string?, bold: boolean?, css: table?}
---@return Widget
function AutomaticPointsTableWidget._createRowCell(props)
	return Div{
		classes = Array.extend(
			'divCell',
			'va-middle',
			'centered-cell',
			'border-color-grey',
			'border-top-right',
			props.background and ('bg-' .. props.background) or nil,
			props.additionalClasses
		),
		css = props.css,
		children = Div{
			classes = {'border-color-grey', 'content'},
			children = props.children
		}
	}
end

---@param opponent AutomaticPointsTableOpponent
---@param opponentIndex integer
---@return Widget
function AutomaticPointsTableWidget:createRow(opponent, opponentIndex)
	return Div{
		classes = {'divRow', opponent.background and ('bg-' .. opponent.background) or nil},
		children = WidgetUtil.collect(
			AutomaticPointsTableWidget._createRowCell{
				background = self.props.positionBackgrounds[opponentIndex],
				children = opponent.placement,
				bold = true,
			},
			AutomaticPointsTableWidget._createRowCell{
				additionalClasses = {'name-cell'},
				background = opponent.background,
				children = OpponentDisplay.InlineOpponent{opponent = opponent.opponent},
			},
			AutomaticPointsTableWidget._createRowCell{
				bold = true,
				children = opponent.totalPoints,
			},
			Array.map(opponent.results, function (result, resultIndex)
				return AutomaticPointsTableWidget._createRowCell{
					css = result.type == "SECURED" and {
						['font-weight'] = 'lighter',
						['font-style'] = 'italic'
					} or nil,
					children = result.amount or (self.props.tournaments[resultIndex].phase == "FINISHED" and '-' or nil),
				}
			end)
		)
	}
end

return AutomaticPointsTableWidget
