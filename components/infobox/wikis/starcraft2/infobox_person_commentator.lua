---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Commentator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Commentator = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local Class = require('Module:Class')
local Variables = require('Module:Variables')
local RaceIcon = require('Module:RaceIcon').getBigIcon
local CleanRace = require('Module:CleanRace')
local Matches = require('Module:Upcoming ongoing and recent matches player/new')

local _PAGENAME = mw.title.getCurrentTitle().prefixedText
local _DISCARD_PLACEMENT = '99'
local _EARNING_MODES = { ['1v1'] = '1v1', ['team_individual'] = 'team' }

--race stuff tables
local _AVAILABLE_RACES = { 'p', 't', 'z', 'r', 'total' }
local _FACTION1 = {
	['p'] = 'Protoss', ['pt'] = 'Protoss', ['pz'] = 'Protoss',
	['t'] = 'Terran', ['tp'] = 'Terran', ['tz'] = 'Terran',
	['z'] = 'Zerg', ['zt'] = 'Zerg', ['zp'] = 'Zerg',
	['r'] = 'Random', ['a'] = 'All'
}
local _FACTION2 = {
	['pt'] = 'Terran', ['pz'] = 'Zerg',
	['tp'] = 'Protoss', ['tz'] = 'Zerg',
	['zt'] = 'Terran', ['zp'] = 'Protoss'
}
local _RACE_CATEGORY = {
	['p'] = '[[:Category:Protoss Players|Protoss]][[Category:Protoss Players]]',
	['pt'] = '[[:Category:Protoss Players|Protoss]][[Category:Protoss Players]],' ..
		'&nbsp;[[:Category:Terran Players|Terran]][[Category:Terran Players]]' ..
		'[[Category:Players with multiple races]]',
	['pz'] = '[[:Category:Protoss Players|Protoss]][[Category:Protoss Players]],' ..
		'&nbsp;[[:Category:Zerg Players|Zerg]][[Category:Zerg Players]]' ..
		'[[Category:Players with multiple races]]',
	['t'] = '[[:Category:Terran Players|Terran]][[Category:Terran Players]]',
	['tp'] = '[[:Category:Terran Players|Terran]][[Category:Terran Players]],' ..
		'&nbsp;[[:Category:Protoss Players|Protoss]][[Category:Protoss Players]]' ..
		'[[Category:Players with multiple races]]',
	['tz'] = '[[:Category:Terran Players|Terran]][[Category:Terran Players]],' ..
		'&nbsp;[[:Category:Zerg Players|Zerg]][[Category:Zerg Players]]' ..
		'[[Category:Players with multiple races]]',
	['z'] = '[[:Category:Zerg Players|Zerg]][[Category:Zerg Players]]',
	['zt'] = '[[:Category:Zerg Players|Zerg]][[Category:Zerg Players]],' ..
		'&nbsp;[[:Category:Terran Players|Terran]][[Category:Terran Players]]' ..
		'[[Category:Players with multiple races]]',
	['zp'] = '[[:Category:Zerg Players|Zerg]][[Category:Zerg Players]],' ..
		'&nbsp;[[:Category:Protoss Players|Protoss]][[Category:Protoss Players]]' ..
		'[[Category:Players with multiple races]]',
	['r'] = '[[:Category:Random Players|Random]][[Category:Random Players]]',
	['a'] = '[[:Category:Protoss Players|Protoss]],&nbsp;' ..
		'[[:Category:Terran Players|Terran]],&nbsp;[[:Category:Zerg Players|Zerg]]' ..
		'[[Category:Protoss Players]][[Category:Terran Players]]' ..
		'[[Category:Zerg Players]][[Category:Players with multiple races]]'
}

--role stuff tables
local _ROLES = {
	['admin'] = 'Admin', ['analyst'] = 'Analyst', ['coach'] = 'Coach',
	['player'] = 'Player', ['expert'] = 'Analyst', ['streamer'] = 'Streamer',
	['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
	['manager'] = 'Manager', ['map maker'] = 'Map maker', ['host'] = 'Host',
	['observer'] = 'Observer', ['photographer'] = 'Photographer',
	['tournament organizer'] = 'Organizer', ['organizer'] = 'Organizer',
}
local _CLEAN_OTHER_ROLES = {
	['blizzard'] = 'Blizzard', ['coach'] = 'Coach', ['staff'] = 'false',
	['content producer'] = 'Content producer', ['streamer'] = 'false',
}

local _earningsGlobal = {}
local _CURRENT_YEAR = tonumber(os.date('%Y'))
local _shouldQueryData
local _raceData
local _statusStore
local _militaryStore

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomCommentator = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomCommentator.run(frame)
	local commentator = Commentator(frame)
	_args = commentator.args

	commentator.shouldStoreData = CustomCommentator.shouldStoreData
	commentator.getStatusToStore = CustomCommentator.getStatusToStore
	commentator.adjustLPDB = CustomCommentator.adjustLPDB
	commentator.getPersonType = CustomCommentator.getPersonType

	commentator.nameDisplay = CustomCommentator.nameDisplay
	commentator.calculateEarnings = CustomCommentator.calculateEarnings
	commentator.createBottomContent = CustomCommentator.createBottomContent
	commentator.createWidgetInjector = CustomCommentator.createWidgetInjector

	_shouldQueryData = CustomCommentator:shouldStoreData()

	return commentator:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return { Cell{ name = 'Race', content = { _raceData.display }
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then return {}
	elseif
		id == 'history' and
		string.match(_args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {_args.retired}
			})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local yearsActive
	if _shouldQueryData and not _statusStore then
		yearsActive = CustomCommentator._getMatchupData(_PAGENAME)
	end

	local currentYearEarnings = _earningsGlobal[tostring(_CURRENT_YEAR)]
	if currentYearEarnings then
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Earnings ' .. _CURRENT_YEAR,
			content = { currentYearEarnings }
		},
		Cell{name = 'Military Service', content = { CustomCommentator._military(_args.military) }},
		Cell{name = 'Years active', content = { yearsActive }}
	}
end

function CustomCommentator:createWidgetInjector()
	return CustomInjector()
end

function CustomCommentator:nameDisplay()
	CustomCommentator._getRaceData(_args.race or 'unknown')
	local raceIcon = RaceIcon({'alt_' .. _raceData.race})
	local name = _args.id or self.pagename

	return raceIcon .. '&nbsp;' .. name
end

function CustomCommentator._getRaceData(race)
	race = string.lower(race)
	race = CleanRace[race] or race
	local display = _RACE_CATEGORY[race]
	if not display and race ~= 'unknown' then
		display = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	end

	_raceData = {
		race = race,
		faction = _FACTION1[race] or '',
		faction2 = _FACTION2[race] or '',
		display = display
	}
end

function CustomCommentator:createBottomContent(infobox)
	if _shouldQueryData then
		return tostring(Matches._get_ongoing({})) ..
			tostring(Matches._get_upcoming({})) ..
			tostring(Matches._get_recent({}))
	end
end

function CustomCommentator:shouldStoreData()
	if
		_args.disable_smw == 'true' or _args.disable_lpdb == 'true' or _args.disable_storage == 'true'
		or Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or mw.title.getCurrentTitle().nsText ~= ''
	then
		Variables.varDefine('disable_SMW_storage', 'true')
		return false
	end
	return true
end

function CustomCommentator._getMatchupData(commentator)
	local yearsActive
	commentator = string.gsub(commentator, '_', ' ')
	local cond = '[[opponent::' .. commentator .. ']] AND [[walkover::]] AND [[winner::>]]'
	local query = 'match2opponents, date'

	local data = CustomCommentator._getLPDBrecursive(cond, query, 'match2')

	local years = {}
	local vs = {}
	for _, item1 in pairs(_AVAILABLE_RACES) do
		vs[item1] = {}
		for _, item2 in pairs(_AVAILABLE_RACES) do
			vs[item1][item2] = { ['win'] = 0, ['loss'] = 0 }
		end
	end

	if type(data[1]) == 'table' then
		for i=1, #data do
			vs = CustomCommentator._addScoresToVS(vs, data[i].match2opponents, commentator)
			years[tonumber(string.sub(data[i].date, 1, 4))] = string.sub(data[i].date, 1, 4)
		end

		local category
		if years[_CURRENT_YEAR] or years[_CURRENT_YEAR - 1] or years[_CURRENT_YEAR - 2] then
			category = 'Active commentators'
			Variables.varDefine('isActive', 'true')
		else
			category = 'Commentators with no matches in the last three years'
		end

		yearsActive = CustomCommentator._getYearsActive(years)

		yearsActive = string.gsub(yearsActive, '<br>', '', 1)

		if not (String.isEmpty(category) or String.isEmpty(yearsActive)) then
			yearsActive = yearsActive .. '[[Category:' .. category .. ']]'
		end

		CustomCommentator._setVarsForVS(vs)
	end
	return yearsActive
end

function CustomCommentator._getYearsActive(years)
	local yearsActive = ''
	local tempYear = nil
	local firstYear = true

	for i = 2010, _CURRENT_YEAR do
		if years[i] then
			if (not tempYear) and (i ~= _CURRENT_YEAR) then
				if firstYear then
					firstYear = nil
				else
					yearsActive = yearsActive .. '<br/>'
				end
				yearsActive = yearsActive .. years[i]
				tempYear = years[i]
			end
			if i == _CURRENT_YEAR then
				if tempYear then
					yearsActive = yearsActive .. '&nbsp;-&nbsp;<b>Present</b>'
				else
					yearsActive = yearsActive .. '<br/><b>Present</b>'
				end
			elseif not years[i + 1] then
				if tempYear ~= years[i] then
					yearsActive = yearsActive .. '&nbsp;-&nbsp;' .. years[i]
				end
				tempYear = nil
			end
		end
	end

	return yearsActive
end

function CustomCommentator._setVarsForVS(table)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			for key3, item3 in pairs(item2) do
				Variables.varDefine(key1 .. '_vs_' .. key2 .. '_' .. key3, item3)
			end
		end
	end
end

function CustomCommentator._addScoresToVS(vs, opponents, commentator)
	local plIndex = 1
	local vsIndex = 2
	if opponents[2].name == commentator then
		plIndex = 2
		vsIndex = 1
	end
	local plOpp = opponents[plIndex]
	local vsOpp = opponents[vsIndex]

	local prace = CleanRace[plOpp.match2players[1].extradata.faction] or 'r'
	local orace = CleanRace[vsOpp.match2players[1].extradata.faction] or 'r'

	vs[prace][orace].win = vs[prace][orace].win + (tonumber(plOpp.score or 0) or 0)
	vs[prace][orace].loss = vs[prace][orace].loss + (tonumber(vsOpp.score or 0) or 0)

	vs['total'][orace].win = vs['total'][orace].win + (tonumber(plOpp.score or 0) or 0)
	vs['total'][orace].loss = vs['total'][orace].loss + (tonumber(vsOpp.score or 0) or 0)

	vs[prace]['total'].win = vs[prace]['total'].win + (tonumber(plOpp.score or 0) or 0)
	vs[prace]['total'].loss = vs[prace]['total'].loss + (tonumber(vsOpp.score or 0) or 0)

	vs['total']['total'].win = vs['total']['total'].win + (tonumber(plOpp.score or 0) or 0)
	vs['total']['total'].loss = vs['total']['total'].loss + (tonumber(vsOpp.score or 0) or 0)

	return vs
end

function CustomCommentator:adjustLPDB(lpdbData, _, personType)
	local extradata = {
		race = _raceData.race,
		faction = _raceData.faction,
		faction2 = _raceData.faction2,
		lc_id = string.lower(self.pagename),
		teamname = _args.team,
		role = personType.store,
		role2 = _args.role2,
		militaryservice = _militaryStore,
	}
	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	for key, item in pairs(_earningsGlobal or {}) do
		extradata['earningsin' .. key] = item
	end

	lpdbData.extradata = extradata

	return lpdbData
end

function CustomCommentator:calculateEarnings()
	local earningsTotal
	earningsTotal, _earningsGlobal = CustomCommentator._getEarningsMedalsData(self.pagename)
	earningsTotal = math.floor( (earningsTotal or 0) * 100 + 0.5) / 100
	return earningsTotal
end

function CustomCommentator._getLPDBrecursive(cond, query, queryType)
	local data = {} -- get LPDB results in here
	local count
	local offset = 0
	repeat
		local additionalData = mw.ext.LiquipediaDB.lpdb(queryType, {
			conditions = cond,
			query = query,
			offset = offset,
			limit = 5000
		})
		count = #additionalData
		-- Merging
		for i, item in ipairs(additionalData) do
			data[offset + i] = item
		end
		offset = offset + count
	until count ~= 5000

	return data
end

function CustomCommentator._getEarningsMedalsData(commentator)
	local cond = '[[date::!1970-01-01 00:00:00]] AND ([[prizemoney::>0]] OR ' ..
		'([[mode::1v1]] AND ([[placement::1]] OR [[placement::2]] OR [[placement::3]]' ..
		' OR [[placement::4]] OR [[placement::3-4]]))) AND ' ..
		'[[participant::' .. commentator .. ']]'
	local query = 'liquipediatier, liquipediatiertype, placement, date, prizemoney, mode'

	local data = CustomCommentator._getLPDBrecursive(cond, query, 'placement')

	local earnings = {}
	local medals = {}
	earnings['total'] = {}
	medals['total'] = {}
	local earnings_total = 0

	if type(data[1]) == 'table' then
		for _, item in pairs(data) do
			--handle earnings
			earnings, earnings_total = CustomCommentator._addPlacementToEarnings(earnings, earnings_total, item)

			--handle medals
			medals = CustomCommentator._addPlacementToMedals(medals, item)
		end
	end

	CustomCommentator._setVarsFromTable(earnings)
	CustomCommentator._setVarsFromTable(medals)

	return earnings_total, earnings['total']
end

function CustomCommentator._addPlacementToEarnings(earnings, earnings_total, data)
	local mode = _EARNING_MODES[data.mode] or 'other'
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local date = string.sub(data.date, 1, 4)
	earnings[mode][date] = (earnings[mode][date] or 0) + data.prizemoney
	earnings['total'][date] = (earnings['total'][date] or 0) + data.prizemoney
	earnings_total = (earnings_total or 0) + data.prizemoney

	return earnings, earnings_total
end

function CustomCommentator._addPlacementToMedals(medals, data)
	if data.mode == '1v1' then
		local place = CustomCommentator._Placements(data.placement)
		if place ~= _DISCARD_PLACEMENT then
			local tier = data.liquipediatier or 'undefined'
			if data.liquipediatiertype ~= 'Qualifier' then
				if not medals[place] then
					medals[place] = {}
				end
				medals[place][tier] = (medals[place][tier] or 0) + 1
				medals[place]['total'] = (medals[place]['total'] or 0) + 1
				medals['total'][tier] = (medals['total'][tier] or 0) + 1
			end
		end
	end

	return medals
end

function CustomCommentator._setVarsFromTable(table)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine(key1 .. '_' .. key2, item2)
		end
	end
end

function CustomCommentator._Placements(value)
	value = (value or '') ~= '' and value or _DISCARD_PLACEMENT
	value = mw.text.split(value, '-')[1]
	if value ~= '1' and value ~= '2' and value ~= '3' then
		value = _DISCARD_PLACEMENT
	elseif value == '3' then
		value = 'sf'
	end
	return value
end

function CustomCommentator._getRankDisplay(data)
	local rank = {}
	if type(data) == 'table' then
		rank.name = 'EPT ' .. (data.information or '') .. ' rank'
		local extradata = data.extradata
		if extradata ~= nil and extradata.rank ~= nil then
			rank.rank = '[[' .. data.pagename .. '|#' .. extradata.rank .. ' (' .. extradata.points .. ' points)]]'
		end
	end
	return rank
end

function CustomCommentator._military(military)
	if military and military ~= 'false' then
		local display = military
		military = string.lower(military)
		local militaryCategory = ''
		if String.Contains(military, 'starting') or String.Contains(military, 'pending') then
			militaryCategory = '[[Category:Commentators waiting for Military Duty]]'
			_militaryStore = 'pending'
		elseif
			String.Contains(military, 'ending') or String.Contains(military, 'started')
			or String.Contains(military, 'ongoing')
		then
			militaryCategory = '[[Category:Commentators on Military Duty]]'
			_militaryStore = 'ongoing'
		elseif String.Contains(military, 'fulfilled') then
			militaryCategory = '[[Category:Commentators expleted Military Duty]]'
			_militaryStore = 'fulfilled'
		elseif String.Contains(military, 'exempted') then
			militaryCategory = '[[Category:Commentators exempted from Military Duty]]'
			_militaryStore = 'exempted'
		end

		return display .. militaryCategory
	end
end

function CustomCommentator:getStatusToStore()
	if _args.death_date then
		_statusStore = 'Deceased'
	elseif _args.retired then
		_statusStore = 'Retired'
	elseif
		(not Logic.readBool(_args.isplayer)) and
		string.lower(_args.role or _args.occupation or 'commentator') ~= 'player'
	then
		_statusStore = 'not player'
	end
	return _statusStore
end

function CustomCommentator:getPersonType()
	local role = _args.role or _args.occupation or 'commentator'
	role = string.lower(role)
	local category = _ROLES[role]
	local store = category or _CLEAN_OTHER_ROLES[role] or 'Commentator'

	return { store = store, category = category or 'Commentator' }
end

return CustomCommentator
