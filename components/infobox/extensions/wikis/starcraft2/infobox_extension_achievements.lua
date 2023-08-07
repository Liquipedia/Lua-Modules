---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Extension/Achievements
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local LeagueIcon = require('Module:LeagueIcon')
local String = require('Module:StringUtils')
local Team = require('Module:Team')

local Opponent = require('Module:OpponentLibraries').Opponent

local BASE_CONDITIONS = {
	'[[liquipediatiertype::!Qualifier]]',
	'[[liquipediatiertype::!Charity]]',
	'[[liquipediatier::1]]',
	'[[placement::1]]',
	'[[prizepoolindex::1]]',
}
local GSL_ICON = 'GSLLogo_small.png'
local GSL_CODE_A_ICON = 'GSL_CodeA.png'
local CODE_A = 'Code A'

local Achievements = {}

function Achievements.team()
	local pageName = mw.title.getCurrentTitle().text
	local historicalPages = Team.queryHistoricalNames(pageName)
	assert(historicalPages, 'No team template exists for "' .. pageName .. '"')
	historicalPages = Array.extend(
		Array.map(historicalPages, function(team) return (team:gsub(' ', '_')) end),
		Array.map(historicalPages, function(team) return (team:gsub('_', ' ')) end)
	)

	return Achievements.display(Achievements._fetchDataForTeam(historicalPages, Opponent.team)),
		Achievements.display(Achievements._fetchDataForTeam(historicalPages, Opponent.solo))
end

function Achievements._fetchDataForTeam(historicalPages, opponentType)
	local lpdbKey = opponentType == Opponent.team and 'opponentname' or 'opponentplayers_p1team'

	local conditions = table.concat(Array.extend(
		BASE_CONDITIONS,
		'[[opponenttype::' .. opponentType .. ']]',
		'(' .. table.concat(Array.map(historicalPages, function(team)
			return '[[' .. lpdbKey .. '::' .. team .. ']]'
		end), ' OR ') .. ')'
	), ' AND ')

	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'icon, icondark, pagename, shortname, objectname, date, prizepoolindex',
		order = 'date asc',
		limit = 5000,
	})
end

function Achievements.display(data)
	if not data or type(data[1]) ~= 'table' then
		return nil
	end

	table.sort(data, Achievements._sortByDate)

	return String.nilIfEmpty(table.concat(Array.map(data, Achievements._displayIcon)))
end

function Achievements._sortByDate(a,b)
	return a.date < b.date
end

function Achievements._displayIcon(item)
	--in case we get passed data from outside this module make sure we are having data
	--with prizepoolindex 1
	if tonumber(item.prizepoolindex) ~= 1 then
		--can not return nil else Array.map breaks off
		return ''
	end

	Achievements._adjustIcon(item)

	return LeagueIcon.display{
		icon = item.icon,
		iconDark = item.icondark,
		link = item.pagename,
		name = item.shortname,
		options = {noTemplate = true},
	}
end

--sc2 specific icon adjustments for GSL Code A
function Achievements._adjustIcon(item)
	item.icon = string.gsub(item.icon or '', 'File:', '') --just to be safe
	if item.icon == GSL_ICON and string.match(item.shortname, CODE_A) then
		item.icon = GSL_CODE_A_ICON
		item.icondark = GSL_CODE_A_ICON
	end
end

return Achievements
