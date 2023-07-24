---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Date = require('Module:DateExt')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Template = require('Module:Template')

--- Liquipedia Ratings (LPR) Display
local RatingsDisplay = {}

-- static conditions for LPDB
local STATIC_CONDITIONS_LPR_SNAPSHOT = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]]'

-- Settings
local LIMIT_RANKS = 100
local LIMIT_LPR_SNAPSHOT = 24

function RatingsDisplay._getSnapshot(name, offset)
	return mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'extradata, date',
			limit = 1,
			offset = offset,
			order = 'date DESC',
			conditions = STATIC_CONDITIONS_LPR_SNAPSHOT .. ' AND [[name::' .. name .. ']]'
		}
	)[1]
end

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
		mw.log('Cannot find teampage for ' .. name)
		return {}
	end
	return res[1]
end

function RatingsDisplay._createProgressionEntry(timestamp, rating)
	return {
		date = os.date('%Y-%m-%d', timestamp),
		rating = rating and math.floor(rating + 0.5) or '',
	}
end

function RatingsDisplay._getTeamRankings(id)
	local snapshot = RatingsDisplay._getSnapshot(id)
	if not snapshot then
		error('Could not find a Rating with this ID')
	end
	local teamRanking = {}
	teamRanking.date = os.time(Date.parseIsoDate(snapshot.date))

	for rank, teamName in ipairs(snapshot.extradata.ranks) do
		local team = snapshot.extradata.table[teamName] or {}
		team.name = teamName
		table.insert(teamRanking, team)
		if rank > LIMIT_RANKS then
			break
		end
	end

	return teamRanking
end

function RatingsDisplay.display(frame)
	local args = Arguments.getArgs(frame)

	local teamRankings = RatingsDisplay._getTeamRankings(args.id)

	Array.forEach(teamRankings, function(team)
		-- TODO: Future functionality: Latest Matches details per team
		team.progression = {
			RatingsDisplay._createProgressionEntry(teamRankings.date, team.rating)
		}
	end)

	-- Build rating progression with older snapshots
	for i = 1, LIMIT_LPR_SNAPSHOT do
		local snapshot = RatingsDisplay._getSnapshot(args.id, i)
		if not snapshot then
			break
		end
		local snapshotTime = os.time(Date.parseIsoDate(snapshot.date))

		Array.forEach(teamRankings, function(team)
			local rating = (snapshot.extradata.table[team.name] or {}).rating

			table.insert(team.progression, RatingsDisplay._createProgressionEntry(snapshotTime, rating))
		end)
	end

	--- Update team information
	Array.forEach(teamRankings, function(team)
		--- Information from team page
		local teamInfo = RatingsDisplay._getTeamInfo(team.name)

		team.region = teamInfo.region or '???'
		team.shortName = mw.ext.TeamTemplate.teamexists(teamInfo.template or '')
				and mw.ext.TeamTemplate.raw(teamInfo.template).shortname or team.name
		--- Reverse the order of progression
		team.progression = Array.reverse(team.progression)
	end)

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
				axisTick = {
					interval = 50
				}
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

	local topTeams = Array.sub(teamRankings, 1, 10)

	local topTeamChart = mw.ext.Charts.chart({
		xAxis = {
			type = 'category',
			data =  Array.map(topTeams[1].progression or {}, Operator.property('date'))
		},
		yAxis = {
			name = 'Rating',
			type = 'value',
			min = 1000,
			max = 3500,
			axisTick = {
				interval = 50
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
			selected = Table.map(topTeams, function(rank, team)
				return team.shortName, rank <= 5 and true or false
			end)
		},
		series = Array.map(topTeams, function(team)
			return {
				data =  Array.map(team.progression, Operator.property('rating')),
				type = 'line',
				name = team.shortName
			}
		end)
	})

	return topTeamChart .. tostring(mw.html.create('div'):addClass('table-responsive'):node(htmlTable))
end

return RatingsDisplay
