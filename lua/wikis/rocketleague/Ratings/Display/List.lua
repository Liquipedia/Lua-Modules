---
-- @Liquipedia
-- page=Module:Ratings/Display/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Operator = require('Module:Operator')
local Template = require('Module:Template')

---@class RatingsDisplayList: RatingsDisplayInterface
local RatingsDisplayList = {}

local LIMIT_TEAMS = 100 -- How many teams to show in the list/table

---@param teamRankings RatingsEntryOld[]
---@return string
function RatingsDisplayList.build(teamRankings)
	local teams = Array.sub(teamRankings, 1, LIMIT_TEAMS)

	local htmlTable = mw.html.create('table'):addClass('wikitable'):css('text-align', 'center')
		:tag('tr'):css('font-weight', 'bold')
			:tag('td'):wikitext('#'):done()
			:tag('td'):wikitext('Team'):done()
			:tag('td'):wikitext('Rating'):done()
			:tag('td'):wikitext('Region'):done()
			:tag('td'):wikitext('Played'):done()
			:tag('td'):wikitext('Streak'):done()
			:tag('td'):wikitext('History'):done()
		:allDone()

	Array.forEach(teams, function(team, rank)
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
			title = 'Details for ' .. mw.ext.TeamTemplate.team(team.name),
			content = chart,
		})

		local streakText = team.streak > 1 and team.streak .. 'W' or (team.streak < -1 and (-team.streak) .. 'L') or '-'
		local streakClass = (team.streak > 1 and 'group-table-rank-change-up')
				or (team.streak < -1 and 'group-table-rank-change-down')
				or nil

		htmlTable:tag('tr')
			:tag('td'):css('font-weight', 'bold'):wikitext(rank):done()
			:tag('td'):css('text-align', 'left'):wikitext(mw.ext.TeamTemplate.team(team.name)):done()
			:tag('td'):wikitext(math.floor(team.rating + 0.5)):done()
			:tag('td'):wikitext(string.upper(team.region or '')):done()
			:tag('td'):wikitext(team.matches):done()
			:tag('td'):css('font-weight', 'bold'):addClass(streakClass):wikitext(streakText):done()
			:tag('td'):wikitext(popup):done()
	end)
	return tostring(mw.html.create('div'):addClass('table-responsive'):node(htmlTable))
end

return RatingsDisplayList
