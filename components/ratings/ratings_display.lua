---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Operator = require('Module:Operator')
local RatingsStorageLpdb = require('Module:Ratings/Storage/Lpdb')
local Table = require('Module:Table')
local Template = require('Module:Template')

--- Liquipedia Ratings (LPR) Display
local RatingsDisplay = {}

-- Settings
local LIMIT_TEAMS_LIST = 100 -- How many teams to show in the list/table
local LIMIT_TEAMS_GRAPH = 10 -- How many teams to show in the combined graph
local LIMIT_TEAMS_GRAPH_SELECTED = 5 -- How many teams are preselected in the graph
local LIMIT_LPR_SNAPSHOT = 24 -- How many historic entries is fetched for graphs (graph mode and team rating history)

--- Entry point for the ratings display in graph display mode
---@param frame Frame
---@return string
function RatingsDisplay.graph(frame)
	local args = Arguments.getArgs(frame)

	local teamRankings = RatingsDisplay._getTeamRankings(args.id, LIMIT_TEAMS_GRAPH, LIMIT_LPR_SNAPSHOT)

	return RatingsDisplay._toGraph(teamRankings)
end

--- Entry point for the ratings display in table list display mode
---@param frame Frame
---@return string
function RatingsDisplay.list(frame)
	local args = Arguments.getArgs(frame)

	local teamRankings = RatingsDisplay._getTeamRankings(args.id, LIMIT_TEAMS_LIST, LIMIT_LPR_SNAPSHOT)

	return RatingsDisplay._toList(teamRankings)
end

---@param id string
---@param limit integer
---@param progressionLimit integer
---@return table
function RatingsDisplay._getTeamRankings(id, limit, progressionLimit)
	local teams = RatingsStorageLpdb.getRankings(id, limit, progressionLimit)

	teams = RatingsDisplay._enrichTeamInformation(teams)

	return teams
end

---@param teams table
---@return table
function RatingsDisplay._enrichTeamInformation(teams)
	-- Update team information from Team Tempalte and Team Page
	Array.forEach(teams, function(team)
		local teamInfo = RatingsDisplay._getTeamInfo(team.name)

		team.region = teamInfo.region or '???'
		team.shortName = mw.ext.TeamTemplate.teamexists(teamInfo.template or '')
				and mw.ext.TeamTemplate.raw(teamInfo.template).shortname or team.name
	end)

	return teams
end

---@param name string
---@return {template: string?, region: string?}
function RatingsDisplay._getTeamInfo(name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'team',
		{
			query = 'region, template',
			limit = 1,
			conditions = '[[pagename::' .. string.gsub(name, ' ', '_') .. ']]'
		}
	)
	if not res[1] then
		mw.log('Warning: Cannot find teampage for ' .. name)
	end

	return res[1] or {}
end

---@param teamRankings table
---@return string
function RatingsDisplay._toList(teamRankings)
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

	Array.forEach(teamRankings, function(team, rank)
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

---@param teamRankings table
---@return string
function RatingsDisplay._toGraph(teamRankings)
	return mw.ext.Charts.chart({
		xAxis = {
			type = 'category',
			data =  Array.map(teamRankings[1].progression or {}, Operator.property('date'))
		},
		yAxis = {
			name = 'Rating',
			type = 'value',
			min = 1500,
			max = 3500,
			axisTick = {
				interval = 500
			}
		},
		tooltip = {
			trigger = 'axis'
		},
		grid = {
			show = true
		},
		size = {
			height = 500,
			width = 700
		},
		legend = {
			show = true,
			selected = Table.map(teamRankings, function(rank, team)
				return team.shortName, rank <= LIMIT_TEAMS_GRAPH_SELECTED and true or false
			end)
		},
		series = Array.map(teamRankings, function(team)
			return {
				data =  Array.map(team.progression, Operator.property('rating')),
				type = 'line',
				name = team.shortName
			}
		end)
	})
end

return RatingsDisplay
