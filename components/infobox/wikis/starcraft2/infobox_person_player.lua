local Player = require('Module:Infobox/Person')
local Variables = require('Module:Variables')
local Achievements = require('Module:Achievements in infoboxes')._player
local RaceIcon = require('Module:RaceIcon').getBigIcon
local String = require('Module:StringUtils')
local CleanRace = require('Module:CleanRace')
local Matches = require('Module:Upcoming ongoing and recent matches player/new')

local _EPT_SEASON = 2021

local _DISCARD_PLACEMENT = '99'
local _ALLKILLICON = '[[File:AllKillIcon.png|link=All-Kill Format]]&nbsp;×&nbsp;'
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
	['commentator'] = 'Commentator', ['caster'] = 'Commentator',
	['expert'] = 'Analyst', ['host'] = 'Host', ['streamer'] = 'Streamer',
	['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
	['manager'] = 'Manager', ['map maker'] = 'Map maker',
	['observer'] = 'Observer', ['photographer'] = 'Photographer',
	['tournament organizer'] = 'Organizer', ['organizer'] = 'Organizer',
}
local _CLEAN_OTHER_ROLES = {
	['blizzard'] = 'Blizzard', ['coach'] = 'Coach', ['staff'] = 'false',
	['content producer'] = 'Content producer', ['streamer'] = 'false',
}

local earningsGlobal = {}
local pagename = mw.title.getCurrentTitle().prefixedText
local currentYear = tonumber(os.date('%Y'))
local shouldStoreData
local hasAchievements
local raceData
local statusStore
local militaryStore

local StarCraft2Player = {}

function StarCraft2Player.run(frame)
	local player = Player(frame)
	player.nameDisplay = StarCraft2Player.nameDisplay
	player.getHistory = StarCraft2Player.getHistory
	player.addCustomCells = StarCraft2Player.addCustomCells
	player.calculateEarnings = StarCraft2Player.calculateEarnings
	player.getAchievements = StarCraft2Player.getAchievements
	player.addCustomContent = StarCraft2Player.addCustomContent
	player.createBottomContent = StarCraft2Player.createBottomContent
	player.shouldStoreData = StarCraft2Player.shouldStoreData
	player.adjustLPDB = StarCraft2Player.adjustLPDB
	player.getStatus = StarCraft2Player.getStatus
	player.getRole = StarCraft2Player.getRole
	return player:createInfobox(frame)
end

function StarCraft2Player:nameDisplay(args)
	StarCraft2Player._getRaceData(args.race or 'unknown')
	local raceIcon = RaceIcon({'alt_' .. raceData.race})
	local name = args.id or self.pagename

	return raceIcon .. '&nbsp;' .. name
end

function StarCraft2Player._getRaceData(race)
	race = string.lower(race)
	race = CleanRace[race] or race
	local display = _RACE_CATEGORY[race]
	if not display and race ~= 'unknown' then
		display = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	end

	raceData = {
		race = race,
		faction = _FACTION1[race] or '',
		faction2 = _FACTION2[race] or '',
		display = display
	}
end

function StarCraft2Player:createBottomContent(infobox)
	if shouldStoreData then
		return tostring(Matches._get_ongoing({})) ..
			tostring(Matches._get_upcoming({})) ..
			tostring(Matches._get_recent({}))
	end
end

function StarCraft2Player:shouldStoreData(args)
	if
		args.disable_smw == 'true' or args.disable_lpdb == 'true' or args.disable_storage == 'true'
		or Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or mw.title.getCurrentTitle().nsText ~= ''
	then
		Variables.varDefine('disable_SMW_storage', 'true')
		return false
	end
	return true
end

function StarCraft2Player:getAchievements(infobox, args)
	local player = args.id or self.pagename
	local achievements = Achievements({}, player)
	if achievements == '' then
		achievements = nil
	else
		hasAchievements = true
	end
	return achievements
end

--kick the default history display
--because we will add it a bit lower again
function StarCraft2Player:getHistory()
	return nil
end

function StarCraft2Player:addCustomContent(infobox, args)
	local retired
	--only display retired if it contains a year
	if string.match(args.retired or '', '%d%d%d%d%') then
		retired = args.retired
	end
	local allkills
	if shouldStoreData then
		allkills = StarCraft2Player._getAllkills()
		if allkills then
			allkills = _ALLKILLICON .. allkills
		end
	end
	infobox:header('Achievements', (not hasAchievements) and allkills or nil)
	infobox:cell('All-kills', allkills)
	infobox:header('History', args.history)
	infobox:centeredCell(args.history)
	infobox:cell('Retired', retired)

	return infobox
end

function StarCraft2Player._getAllkills()
	if shouldStoreData then
		local allkillsData = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[pagename::' .. pagename .. ']] AND [[type::allkills]]',
			query = 'information',
			limit = 1
		})
		if type(allkillsData[1]) == 'table' then
			return allkillsData[1].information
		end
	end
end

function StarCraft2Player:getRole(args)
	local role = args.role or args.occupation or 'player'
	role = string.lower(role)
	local category = _ROLES[role]
	local store = category or _CLEAN_OTHER_ROLES[role] or 'Player'

	return { title = 'Race', display = raceData.display, store = store, category = category or 'Player'}
end

function StarCraft2Player:calculateEarnings(args)
	shouldStoreData = Player.shouldStoreData(args)

	if shouldStoreData then
		local earningsTotal
		earningsTotal, earningsGlobal = StarCraft2Player._getEarningsMedalsData(self.pagename)
		earningsTotal = math.floor( (earningsTotal or 0) * 100 + 0.5) / 100
		return earningsTotal
	end
	return 0
end

function StarCraft2Player._getLPDBrecursive(cond, query, queryType)
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

function StarCraft2Player._getEarningsMedalsData(player)
	local cond = '[[date::!1970-01-01 00:00:00]] AND ([[prizemoney::>0]] OR ' ..
		'([[mode::1v1]] AND ([[placement::1]] OR [[placement::2]] OR [[placement::3]]' ..
		' OR [[placement::4]] OR [[placement::3-4]]))) AND ' ..
		'[[participant::' .. player .. ']]'
	local query = 'liquipediatier, liquipediatiertype, placement, date, prizemoney, mode'

	local data = StarCraft2Player._getLPDBrecursive(cond, query, 'placement')

	local earnings = {}
	local Medals = {}
	earnings['total'] = {}
	Medals['total'] = {}
	local earnings_total = 0

	if type(data[1]) == 'table' then
		for i=1,#data do
			--handle earnings
			local mode = _EARNING_MODES[data[i].mode] or 'other'
			if not earnings[mode] then
				earnings[mode] = {}
			end
			local date = string.sub(data[i].date, 1, 4)
			if not earnings[mode][date] then
				earnings[mode][date] = 0
			end
			if not earnings['total'][date] then
				earnings['total'][date] = 0
			end
			earnings[mode][date] = earnings[mode][date] + data[i].prizemoney
			earnings['total'][date] = earnings['total'][date] + data[i].prizemoney
			earnings_total = earnings_total + data[i].prizemoney

			--handle medals
			if data[i].mode == '1v1' then
				local place = StarCraft2Player._Placements(data[i].placement)
				if place ~= _DISCARD_PLACEMENT then
					local tier = data[i].liquipediatier or 'undefined'
					if data[i].liquipediatiertype ~= 'Qualifier' then
						if not Medals[place] then
							Medals[place] = {}
						end
						if not Medals[place][tier] then
							Medals[place][tier] = 0
						end
						if not Medals[place]['total'] then
							Medals[place]['total'] = 0
						end
						Medals[place][data[i].liquipediatier or ''] = Medals[place][tier] + 1
						Medals[place]['total'] = Medals[place]['total'] + 1
						if not Medals['total'][tier] then
							Medals['total'][tier] = 0
						end
						Medals['total'][tier] = Medals['total'][tier] + 1
					end
				end
			end
		end
	end

	for key1, item1 in pairs(earnings) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine(key1 .. '_' .. key2, item2)
		end
	end

	for key1, item1 in pairs(Medals) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine(key1 .. '_' .. key2, item2)
		end
	end

	return earnings_total, earnings['total']
end

function StarCraft2Player._Placements(value)
	value = (value or '') ~= '' and value or _DISCARD_PLACEMENT
	value = mw.text.split(value, '-')[1]
	if value ~= '1' and value ~= '2' and value ~= '3' then
		value = _DISCARD_PLACEMENT
	elseif value == '3' then
		value = 'sf'
	end
	return value
end

function StarCraft2Player._getRank(player)
	local rank_region = require('Module:EPT player region ' .. _EPT_SEASON)[player]
		or {'noregion'}
	local type_cond = '([[type::EPT ' ..
		table.concat(rank_region, ' ranking ' .. _EPT_SEASON .. ']] OR [[type::EPT ')
		.. ' ranking ' .. _EPT_SEASON .. ']])'

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[name::' .. player .. ']] AND ' .. type_cond,
			query = 'extradata, information, pagename',
			limit = 10
		})

	if type(data[1]) == 'table' then
		local rank1 = {}
		local rank2 = {}
		rank1['name'] = 'EPT ' .. (data[1].information or '') .. ' rank'
		if type(data[1]) == 'table' then
			local extradata = data[1].extradata
			if extradata ~= nil then
				rank1['rank'] = '[[' .. data[1].pagename .. '|#' .. extradata.rank .. ' (' .. extradata.points .. ' points)]]'
			end
		end
		if type(data[2]) == 'table' then
			local extradata = data[2].extradata
			rank2['name'] = 'EPT ' .. (data[2].information or '') .. ' rank'
			if extradata ~= nil then
				rank2['rank'] = '[[' .. data[2].pagename .. '|#' .. extradata.rank .. ' (' .. extradata.points .. ' points)]]'
			end
		end
		return rank1, rank2
	end
	return {}, {}
end

function StarCraft2Player._military(military)
	if military and military ~= 'false' then
		local display = military
		military = string.lower(military)
		local militaryCategory = ''
		if String.Contains(military, 'starting') or String.Contains(military, 'pending') then
			militaryCategory = '[[Category:Players waiting for Military Duty]]'
			militaryStore = 'pending'
		elseif String.Contains(military, 'ending') or String.Contains(military, 'started')
			or String.Contains(military, 'ongoing') then
				militaryCategory = '[[Category:Players on Military Duty]]'
				militaryStore = 'ongoing'
		elseif String.Contains(military, 'fulfilled') then
			militaryCategory = '[[Category:Players expleted Military Duty]]'
			militaryStore = 'fulfilled'
		elseif String.Contains(military, 'exempted') then
			militaryCategory = '[[Category:Players exempted from Military Duty]]'
			militaryStore = 'exempted'
		end

		return display .. militaryCategory
	end
end

function StarCraft2Player:getStatus(args)
	if args.death_date then
		statusStore = 'Deceased'
	elseif args.retired then
		statusStore = 'Retired'
	elseif string.lower(args.role or 'player') ~= 'player' then
		statusStore = 'not player'
	end
	return { store = statusStore }
end

function StarCraft2Player:addCustomCells(infobox, args)
	local rank1, rank2
	local yearsActive, activeCategory
	if shouldStoreData and not statusStore then
		rank1, rank2 = StarCraft2Player._getRank(self.pagename)
		yearsActive, activeCategory = StarCraft2Player._getMatchupData(self.pagename)
		infobox:categories(activeCategory)
	end

	local currentYearEarnings = earningsGlobal[tostring(currentYear)]
	if currentYearEarnings then
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	infobox:cell('Approx. Earnings ' .. currentYear, currentYearEarnings)
	infobox:cell(rank1.name or 'Rank', rank1.rank)
	infobox:cell(rank2.name or 'Rank', rank2.rank)
	infobox:cell('Military Service', StarCraft2Player._military(args.military))
	infobox:cell('Years active', yearsActive)

	return infobox
end

function StarCraft2Player._getMatchupData(player)
	local category = ''
	player = string.gsub(player, '_', ' ')
	local cond = '[[opponent::' .. player .. ']] AND [[walkover::]] AND [[winner::>]]'
	local query = 'match2opponents, date'

	local data = StarCraft2Player._getLPDBrecursive(cond, query, 'match2')

	local yearsActive = ''
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
			local plIndex = 1
			local vsIndex = 2
			if data[1].match2opponents[2].name == player then
				plIndex = 2
				vsIndex = 1
			end
			local plOpp = data[1].match2opponents[plIndex]
			local vsOpp = data[1].match2opponents[vsIndex]

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

			years[tonumber(string.sub(data[i].date, 1, 4))] = string.sub(data[i].date, 1, 4)
		end

		if years[currentYear] ~= nil or years[currentYear - 1] ~= nil or years[currentYear - 2] ~= nil then
			category = 'Active players'
			Variables.varDefine('isActive', 'true')
		else
			category = 'Players with no matches in the last three years'
		end

		local tempYear = nil
		local firstYear = true

		for i = 2010, currentYear do
			if years[i] then
				if (not tempYear) and (i ~= currentYear) then
					if firstYear then
						firstYear = nil
					else
						yearsActive = yearsActive .. '<br/>'
					end
					yearsActive = yearsActive .. years[i]
					tempYear = years[i]
				end

				if i == currentYear then
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

		yearsActive = string.gsub(yearsActive, '<br>', '', 1)

		for key1, item1 in pairs(vs) do
			for key2, item2 in pairs(item1) do
				for key3, item3 in pairs(item2) do
					Variables.varDefine(key1 .. '_vs_' .. key2 .. '_' .. key3, item3)
				end
			end
		end
	end
	return yearsActive, category
end

function StarCraft2Player:adjustLPDB(lpdbData, args, role, _)
	local extradata = {
		race = raceData.race,
		faction = raceData.faction,
		faction2 = raceData.faction2,
		lc_id = string.lower(self.pagename),
		teamname = args.team,
		role = role.store,
		role2 = args.role2,
		militaryservice = militaryStore,
		activeplayer = (not statusStore) and Variables.varDefault('isActive', '') or '',
	}
	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	for key, item in pairs(earningsGlobal or {}) do
		extradata['earningsin' .. key] = item
	end

	lpdbData.extradata = extradata

	return lpdbData
end

return StarCraft2Player
