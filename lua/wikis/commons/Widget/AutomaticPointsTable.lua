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
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

local QUALIFIED_ICON = IconFa{iconName = 'qualified', color = 'forest-green-text', hover = 'Qualified'}

---@class AutomaticPointsTableWidgetProps
---@field opponents AutomaticPointsTableOpponent
---@field tournaments StandardTournament[]
---@field limit integer
---@field positionBackgrounds string[]

---@class AutomaticPointsTableWidget: Widget
---@operator call(AutomaticPointsTableWidgetProps): AutomaticPointsTableWidget
---@field props AutomaticPointsTableWidgetProps
local AutomaticPointsTableWidget = Class.new(Widget)

---@return Widget
function AutomaticPointsTableWidget:render()
	local numCols = Array.reduce(self.props.tournaments, function (aggregate, tournament)
		if tournament.extradata.includesDeduction then
			return aggregate + 2
		end
		return aggregate + 1
	end, 0)
	return Div{
		classes = {'table-responsive', 'automatic-points-table'},
		children = Div{
			classes = {'fixed-size-table-container', 'border-color-grey'},
			css = {width = (450 + numCols * 50) .. 'px'},
			children = self:createTable()
		}
	}
end

---@protected
---@return Widget
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

---@private
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

---@protected
---@return Widget
function AutomaticPointsTableWidget:createHeader()
	local tournaments = self.props.tournaments

	return Div{
		classes = {'divHeaderRow', 'diagonal'},
		children = WidgetUtil.collect(
			AutomaticPointsTableWidget._createHeaderCell('Ranking','ranking'),
			AutomaticPointsTableWidget._createHeaderCell('Team', 'team'),
			AutomaticPointsTableWidget._createHeaderCell('Total Points'),
			Array.flatMap(tournaments, function (tournament)
				return {
					AutomaticPointsTableWidget._createHeaderCell(TournamentTitle{tournament = tournament}),
					tournament.extradata.includesDeduction and AutomaticPointsTableWidget._createHeaderCell('Deductions') or nil
				}
			end)
		)
	}
end

---@private
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

---@protected
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
				css = {['font-weight'] = 'bold'},
			},
			AutomaticPointsTableWidget._createRowCell{
				additionalClasses = {'name-cell'},
				background = opponent.background,
				children = OpponentDisplay.BlockOpponent{opponent = opponent.opponent, note = opponent.note},
			},
			self:_createTotalPointsCell(opponent),
			Array.flatMap(opponent.results, function (result, resultIndex)
				local resultDisplay
				if result.qualified then
					resultDisplay = QUALIFIED_ICON
				elseif result.amount then
					resultDisplay = result.amount
				elseif self.props.tournaments[resultIndex].phase == 'FINISHED' then
					resultDisplay = '-'
				end
				return {
					AutomaticPointsTableWidget._createRowCell{
						css = result.type == "SECURED" and {
							['font-weight'] = 'lighter',
							['font-style'] = 'italic'
						} or nil,
						children = resultDisplay,
					},
					self.props.tournaments[resultIndex].extradata.includesDeduction and AutomaticPointsTableWidget._createRowCell{
						children = result.deduction and {
							HtmlWidgets.Abbr{
								classes = {'deduction-box'},
								title = result.note,
								children = result.deduction
							}
						} or nil
					} or nil
				}
			end)
		)
	}
end

---@private
---@param opponent AutomaticPointsTableOpponent
---@return Widget
function AutomaticPointsTableWidget:_createTotalPointsCell(opponent)
	return AutomaticPointsTableWidget._createRowCell{
		css = {['font-weight'] = 'bold'},
		children = opponent.qualified and QUALIFIED_ICON or opponent.totalPoints,
	}
end

return AutomaticPointsTableWidget
