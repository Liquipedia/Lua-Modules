local Player = require('Module:Infobox/Player')
local Variables = require('Module:Variables')
local Achievements = require('Module:Achievements in infoboxes')._player
local RaceIcon = require('Module:RaceIcon').getBigIcon
local String = require('Module:StringUtils')
local Matches = require('Module:Upcoming ongoing and recent matches player/new')

local _EPT_SEASON = 2021
local _ALLKILLICON = '[[File:AllKillIcon.png|link=All-Kill Format]]&nbsp;×&nbsp;'

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
	Player.nameDisplay = StarCraft2Player.nameDisplay
	Player.getHistory = StarCraft2Player.getHistory
	Player.addCustomCells = StarCraft2Player.addCustomCells
	Player.calculateEarnings = StarCraft2Player.calculateEarnings
	Player.getAchievements = StarCraft2Player.getAchievements
	Player.addCustomContent = StarCraft2Player.addCustomContent
	Player.createBottomContent = StarCraft2Player.createBottomContent
	Player.shouldStoreData = StarCraft2Player.shouldStoreData
	Player.getExtradata = StarCraft2Player.getExtradata
	Player.getStatus = StarCraft2Player.getStatus
	Player.getRole = StarCraft2Player.getRole
	return player:createInfobox(frame)
end

function StarCraft2Player.nameDisplay(_, args)
	StarCraft2Player._getRaceData(args.race or 'unknown')
	local raceIcon = RaceIcon({'alt_' .. raceData.race})
    local name = args.id or pagename

    return raceIcon .. '&nbsp;' .. name
end

function StarCraft2Player._getRaceData(race)
	local cleanRace = {
		['protoss'] = 'p',
		['terran'] = 't',
		['zerg'] = 'z',
		['random'] = 'r',
		['all'] = 'a',
		['tzp'] = 'a',
		['tpz'] = 'a',
		['ptz'] = 'a',
		['pzt'] = 'a',
		['ztp'] = 'a',
		['zpt'] = 'a',
	}
	local FACTION1 = {
		['p'] = 'Protoss', ['pt'] = 'Protoss', ['pz'] = 'Protoss',
		['t'] = 'Terran', ['tp'] = 'Terran', ['tz'] = 'Terran',
		['z'] = 'Zerg', ['zt'] = 'Zerg', ['zp'] = 'Zerg',
		['r'] = 'Random', ['a'] = 'All'
	}
	local FACTION2 = {
		['pt'] = 'Terran', ['pz'] = 'Zerg',
		['tp'] = 'Protoss', ['tz'] = 'Zerg',
		['zt'] = 'Terran', ['zp'] = 'Protoss'
	}
	local raceCategory = {
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

	race = string.lower(race)
	race = cleanRace[race] or race
	local display = raceCategory[race]
	if not display and race ~= 'unknown' then
		display = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	end

	raceData = {
		race = race,
		faction = FACTION1[race] or '',
		faction2 = FACTION2[race] or '',
		display = display
	}
end

function StarCraft2Player.createBottomContent(infobox)
	if shouldStoreData then
		return tostring(Matches._get_ongoing({})) ..
			tostring(Matches._get_upcoming({})) ..
			tostring(Matches._get_recent({}))
	end
end

function StarCraft2Player.shouldStoreData(args)
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

function StarCraft2Player.getAchievements(args)
	local player = args.id or pagename
	local achievements = Achievements({}, player)
	if achievements == '' then
		achievements = nil
	else
		hasAchievements = true
	end
	return achievements
end

--kick the default history display
function StarCraft2Player.getHistory() return nil end

function StarCraft2Player.addCustomContent(player, infobox, args)
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
	infobox	:header('Achievements', (not hasAchievements) and allkills or nil)
            :cell('All-kills', allkills)
			:header('History', args.history)
            :centeredCell(args.history)
			:cell('Retired', retired)

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

function StarCraft2Player.getRole(_, args)
	local role = args.role or args.occupation or 'player'
	role = string.lower(role)
	local ROLES = {
		['admin'] = 'Admin', ['analyst'] = 'Analyst', ['coach'] = 'Coach',
		['commentator'] = 'Commentator', ['caster'] = 'Commentator',
		['expert'] = 'Analyst', ['host'] = 'Host', ['streamer'] = 'Streamer',
		['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
		['manager'] = 'Manager', ['map maker'] = 'Map maker',
		['observer'] = 'Observer', ['photographer'] = 'Photographer',
		['tournament organizer'] = 'Organizer', ['organizer'] = 'Organizer',
	}
	local cleanOther = {
		['blizzard'] = 'Blizzard', ['coach'] = 'Coach', ['staff'] = 'false',
		['content producer'] = 'Content producer', ['streamer'] = 'false',
	}
	local category = ROLES[role]
	local store = category or cleanOther[role] or 'Player'

    return { title = 'Race', display = raceData.display, store = store, category = category or 'Player'}
end

function StarCraft2Player.calculateEarnings(_, args)
	shouldStoreData = Player.shouldStoreData(args)

	if shouldStoreData then
		local earningsTotal
		earningsTotal, earningsGlobal = StarCraft2Player._get_earnings_and_medals_data(pagename)
		earningsTotal = math.floor( (earningsTotal or 0) * 100 + 0.5) / 100
		return earningsTotal
	end
	return 0
end

function StarCraft2Player._get_earnings_and_medals_data(player)
	local count
	local data = {} -- get LPDB results in here
	local offset = 0
	local cond = '[[date::!1970-01-01 00:00:00]] AND ([[prizemoney::>0]] OR ' ..
		'([[mode::1v1]] AND ([[placement::1]] OR [[placement::2]] OR [[placement::3]]' ..
		' OR [[placement::4]] OR [[placement::3-4]]))) AND ' ..
		'[[participant::' .. player .. ']]'
	repeat
		local additional_data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = cond,
			query = 'liquipediatier, liquipediatiertype, placement, date, prizemoney, mode',
			offset = offset,
			limit = 5000
		})
		count = 0
		-- Merging
		for i, item in ipairs(additional_data) do
			data[offset + i] = item
			count = count + 1
		end
		offset = offset + count
	until count ~= 5000

	local EarningModes = { ['1v1'] = '1v1', ['team_individual'] = 'team' }

	local earnings = {}
	local Medals = {}
	earnings['total'] = {}
	Medals['total'] = {}
	local earnings_total = 0

	if type(data[1]) == 'table' then
		for i=1,#data do
			--handle earnings
			local mode = EarningModes[data[i].mode] or 'other'
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
				if place ~= '99' then
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
	value = (value or '') ~= '' and value or '99'
	value = mw.text.split(value, '-')[1]
	if value ~= '1' and value ~= '2' and value ~= '3' then
		value = '99'
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

function StarCraft2Player.getStatus(args)
	if args.death_date then
		statusStore = 'Deceased'
	elseif args.retired then
		statusStore = 'Retired'
	elseif string.lower(args.role or 'player') ~= 'player' then
		statusStore = 'not player'
	end
    return { store = statusStore }
end

function StarCraft2Player.addCustomCells(_, infobox, args)
	local rank1, rank2
	local yearsActive, activeCategory
	if shouldStoreData and not statusStore then
		rank1, rank2 = StarCraft2Player._getRank(pagename)
		yearsActive, activeCategory = StarCraft2Player._get_matchup_data(pagename)
		infobox:categories(activeCategory)
	end

	local currentYearEarnings = earningsGlobal[tostring(currentYear)]
	if currentYearEarnings then
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	infobox	:cell('Approx. Earnings ' .. currentYear, currentYearEarnings)
			:cell(rank1.name or 'Rank', rank1.rank)
			:cell(rank2.name or 'Rank', rank2.rank)
			:cell('Military Service', StarCraft2Player._military(args.military))
			:cell('Years active', yearsActive)

	return infobox
end

function StarCraft2Player._get_matchup_data(player)
	local count
	local category = ''
	player = string.gsub(player, '_', ' ')
	local conditions = '[[opponent::' .. player .. ']] AND [[walkover::]] AND [[winner::>]]'

	local data = {} -- get LPDB results in here
	local offset = 0
	repeat
		local additional_data = mw.ext.LiquipediaDB.lpdb('match2', {
			conditions = conditions,
			query = 'match2opponents, date',
			offset = offset,
			limit = 5000
		})
		count = 0
		-- Merging
		for i, item in ipairs(additional_data) do
			data[offset + i] = item
			count = count + 1
		end
		offset = offset + count
	until count ~= 5000

	local yearsActive = ''
	local years = {}
	local vs = {}
	local races = { 'p', 't', 'z', 'r', 'total' }
	for _, item1 in pairs(races) do
		vs[item1] = {}
		for _, item2 in pairs(races) do
			vs[item1][item2] = { ['win'] = 0, ['loss'] = 0 }
		end
	end

	if type(data[1]) == 'table' then
		local CleanRace = { ['t'] = 't', ['z'] = 'z', ['p'] = 'p'}
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

function StarCraft2Player.getExtradata(args, role, _)
	local extradata = {
		race = raceData.race,
		faction = raceData.faction,
		faction2 = raceData.faction2,
		lc_id = string.lower(pagename),
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

    return extradata
end

return StarCraft2Player
