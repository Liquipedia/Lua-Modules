---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local RatingsDisplay = {}

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

-- static conditions for LPDB
local STATIC_CONDITIONS_LPR_SNAPSHOT = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]]'

-- Settings
local LIMIT_RANKS = 100
local LIMIT_LPR_SNAPSHOT = 24

local function getSnapshot(name, offset)
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

---@param str string
---@return osdate
---@overload fun():nil
local function parseDate(str)
	if not str then
		return
	end
	local y, m, d = str:match('^(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)')
	-- default to month and day = 1 if not set
	if String.isEmpty(m) then
		m = 1
	end
	if String.isEmpty(d) then
		d = 1
	end
	-- create time
	return {year = y, month = m, day = d}
end

local function getRegionOfTeam(name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'team',
		{
			query = 'region',
			limit = 1,
			conditions = '[[pagename::' .. string.gsub(name, ' ', '_') .. ']]'
		}
	)
	if not res[1] then
		mw.log('Cannot find teampage for ' .. name)
	end
	return (res[1] or {}).region or '???'
end

local function createProgressionEntry(timestamp, rating)
	return {
		date = os.date('%Y-%m-%d', timestamp),
		rating = math.floor(rating + 0.5),
	}
end

function RatingsDisplay.display(frame)
	local args = Arguments.getArgs(frame)

	local latestSnapshot = getSnapshot(args.id)
	if not latestSnapshot then
		error('Could not find a Rating with this ID')
	end
	local latestSnapshotTime = os.time(parseDate(latestSnapshot.date))

	-- apply limit to first rating table
	local teamRanking = {}
	for rank, teamName in ipairs(latestSnapshot.extradata.ranks) do
		local team = latestSnapshot.extradata.table[teamName] or {}
		team.name = teamName
		table.insert(teamRanking, team)
		if rank > LIMIT_RANKS then
			break
		end
	end

	latestSnapshot = nil

	Array.forEach(teamRanking, function(team)
		-- Future functionality: Latest Matches details per team
		--[[
		local match2ids = {}
		local rcByMatch2id = {}
		for _, item in ipairs(data.lastmatches) do
			local match2id = item.id
			table.insert(match2ids, match2id)
			rcByMatch2id[match2id] = item.ratingChange
		end
		local lm = {}
		for _, match in ipairs(getMatches(match2ids)) do
			local ratingChange = rcByMatch2id[match.match2id]
			local winner = tonumber(match.winner) or 1
			local opponent = ratingChange and match.match2opponents[ratingChange > 0 and ((winner % 2) + 1) or winner] or {}
			local historyMatch = {
				id = match.match2id,
				rc = ratingChange,
				op = (opponent or {}).name or 'Error',
				pn = match.pagename,
				dt = match.date
			}
			table.insert(lm, historyMatch)
		end
		data.lastmatches = lm
		--]]
		team.progression = {
			createProgressionEntry(latestSnapshotTime, team.rating)
		}
	end)

	-- Build rating progression with older snapshots
	for i = 1, LIMIT_LPR_SNAPSHOT do
		local snapshot = getSnapshot(args.id, i)
		if not snapshot then
			break
		end
		local snapshotTime = os.time(parseDate(snapshot.date))

		Array.forEach(teamRanking, function(team)
			local rating = (snapshot.extradata.table[team.name] or {}).rating
			if not rating then
				return
			end

			table.insert(team.progression, createProgressionEntry(snapshotTime, rating))
		end)
	end

	--- Update team information
	Array.forEach(teamRanking, function(team)
		--- Fetch the region
		team.region = getRegionOfTeam(team.name)
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

	Array.forEach(teamRanking, function(team, rank)
		local chart = mw.ext.Charts.chart({
			xAxis = {
				type = 'category',
				data = Array.map(team.progression, Operator.property('date'))
			},
			yAxis = {
				type = 'value',
				min = 1250,
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
			label = 'Hist',
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

return RatingsDisplay
