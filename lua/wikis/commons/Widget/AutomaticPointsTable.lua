---
-- @Liquipedia
-- page=Module:Widget/AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

local QUALIFIED_ICON = IconFa{iconName = 'qualified', color = 'forest-green-text', hover = 'Qualified'}

---@class AutomaticPointsTableWidgetProps
---@field opponents AutomaticPointsTableOpponent[]
---@field tournaments StandardTournament[]
---@field limit integer
---@field positionBackgrounds string[]

local AutomaticPointsTableWidget = {}

---@param props AutomaticPointsTableWidgetProps
---@return VNode
function AutomaticPointsTableWidget.renderFn(props)
	local numCols = Array.reduce(props.tournaments, function (aggregate, tournament)
		if tournament.extradata.includesDeduction then
			return aggregate + 2
		end
		return aggregate + 1
	end, 0)
	return Div{
		classes = {'table-responsive', 'automatic-points-table'},
		children = Div{
			classes = {'fixed-size-table-container', 'border-color-grey'},
			css = {['--num-columns'] = numCols},
			children = AutomaticPointsTableWidget.createTable(props)
		}
	}
end

---@param props AutomaticPointsTableWidgetProps
---@return VNode
function AutomaticPointsTableWidget.createTable(props)
	return Div{
		classes = {'divTable', 'border-color-grey', 'border-bottom'},
		children = WidgetUtil.collect(
			AutomaticPointsTableWidget.createHeader(props),
			Array.map(props.opponents, FnUtil.curry(AutomaticPointsTableWidget.createRow, props))
		)
	}
end

---@private
---@param child Renderable
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

---@param props AutomaticPointsTableWidgetProps
---@return Widget
function AutomaticPointsTableWidget.createHeader(props)
	local tournaments = props.tournaments

	return Div{
		classes = {'divHeaderRow', 'diagonal'},
		children = WidgetUtil.collect(
			AutomaticPointsTableWidget._createHeaderCell('Ranking','ranking'),
			AutomaticPointsTableWidget._createHeaderCell('Participant', 'participant'),
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
---@param props {children: Renderable|Renderable[]?,
---additionalClasses: string[]?, background: string?, bold: boolean?, css: table?}
---@return VNode
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

---@param props AutomaticPointsTableWidgetProps
---@param opponent AutomaticPointsTableOpponent
---@param opponentIndex integer
---@return VNode
function AutomaticPointsTableWidget.createRow(props, opponent, opponentIndex)
	return Div{
		classes = {'divRow', opponent.background and ('bg-' .. opponent.background) or nil},
		children = WidgetUtil.collect(
			AutomaticPointsTableWidget._createRowCell{
				background = props.positionBackgrounds[opponentIndex],
				children = opponent.placement,
				css = {['font-weight'] = 'bold'},
			},
			AutomaticPointsTableWidget._createRowCell{
				additionalClasses = {'name-cell'},
				background = opponent.background,
				children = OpponentDisplay.BlockOpponent{
					opponent = opponent.opponent,
					note = opponent.note,
					showPlayerTeam = true
				},
			},
			AutomaticPointsTableWidget._createTotalPointsCell(opponent),
			Array.flatMap(opponent.results, function (result, resultIndex)
				local resultDisplay
				if result.qualified then
					resultDisplay = QUALIFIED_ICON
				elseif result.amount then
					resultDisplay = result.amount
				elseif props.tournaments[resultIndex].phase == 'FINISHED' then
					resultDisplay = '-'
				end
				return {
					AutomaticPointsTableWidget._createRowCell{
						css = result.type == 'SECURED' and {
							['font-weight'] = 'lighter',
							['font-style'] = 'italic'
						} or nil,
						children = resultDisplay,
					},
					props.tournaments[resultIndex].extradata.includesDeduction and AutomaticPointsTableWidget._createRowCell{
						children = result.deduction and {
							Html.Abbr{
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
---@return VNode
function AutomaticPointsTableWidget._createTotalPointsCell(opponent)
	return AutomaticPointsTableWidget._createRowCell{
		css = {['font-weight'] = 'bold'},
		children = opponent.qualified and QUALIFIED_ICON or opponent.totalPoints,
	}
end

return Component.component(AutomaticPointsTableWidget.renderFn)
