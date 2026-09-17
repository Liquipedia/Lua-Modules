---
-- @Liquipedia
-- page=Module:Ratings/Display/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Operator = Lua.import('Module:Operator')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Template = Lua.import('Module:Template')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

---@class RatingsDisplayList: RatingsDisplayInterface
local RatingsDisplayList = {}

local LIMIT_TEAMS = 100 -- How many teams to show in the list/table

---@param teamRankings RatingsEntryOld[]
---@return Renderable
function RatingsDisplayList.build(teamRankings)
	local teams = Array.sub(teamRankings, 1, LIMIT_TEAMS)

	local tableRow = {
		TableWidgets.TableHeader{children =
			TableWidgets.Row{
				css = {['font-weight'] = 'bold'},
				children = {
					TableWidgets.CellHeader{children = '#'},
					TableWidgets.CellHeader{children = 'Team'},
					TableWidgets.CellHeader{children = 'Rating'},
					TableWidgets.CellHeader{children = 'Region'},
					TableWidgets.CellHeader{children = 'Played'},
					TableWidgets.CellHeader{children = 'Streak'},
					TableWidgets.CellHeader{children = 'History'}
				}
			}
		}
	}

	Array.forEach(teams, function(team, rank)
		if (team.streak == nil) or (team.rating == nil) then
			return
		end

		local chart = mw.ext.Charts.chart({
			xAxis = {
				type = 'category',
				data = Array.map(team.progression, Operator.property('date'))
			},
			yAxis = {
				type = 'value',
				min = 1000,
				max = 3500,
			},
			tooltip = {
				trigger = 'axis'
			},
			grid = {
				show = true
			},
			size = {
				height = 300,
				width = 500
			},
			series = {
				{
					data = Array.map(team.progression, Operator.property('rating')),
					type = 'line'
				}
			}
		})

		local popup = Template.expandTemplate(mw.getCurrentFrame(), 'Popup', {
			label = 'show',
			title = 'Details for ' .. tostring(OpponentDisplay.InlineTeamContainer{template = team.name}),
			content = chart,
		})

		local streakText = team.streak > 1 and team.streak .. 'W' or (team.streak < -1 and (-team.streak) .. 'L') or '-'
		local streakClass = (team.streak > 1 and 'group-table-rank-change-up')
				or (team.streak < -1 and 'group-table-rank-change-down')
				or nil

		table.insert(tableRow, TableWidgets.TableBody{children =
			TableWidgets.Row{
				children = {
					TableWidgets.Cell{css = {['font-weight'] = 'bold'}, children = rank},
					TableWidgets.Cell{children = OpponentDisplay.InlineTeamContainer{template = team.name}},
					TableWidgets.Cell{children = math.floor(team.rating + 0.5)},
					TableWidgets.Cell{children = string.upper(team.region or '')},
					TableWidgets.Cell{children = team.matches},
					TableWidgets.Cell{
						css = {['font-weight'] = 'bold'},
						classes = {streakClass},
						children = streakText
					},
					TableWidgets.Cell{children = popup}
				}
			}
		})

	end)
	return TableWidgets.Table{
		children = {
			tableRow
		}
	}
end

return RatingsDisplayList
