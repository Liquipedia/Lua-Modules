---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- This module is used for both the Player and Commentator infoboxes

local PersonSc2 = require('Module:Infobox/Person/Custom/Shared')
local Person = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Variables = require('Module:Variables')
local Achievements = require('Module:Achievements in infoboxes')._player
local CleanRace = require('Module:CleanRace')
local Math = require('Module:Math')
local Matches = require('Module:Upcoming ongoing and recent matches player/new')

local _EPT_SEASON = 2021

local _PAGENAME = mw.title.getCurrentTitle().prefixedText
local _DISCARD_PLACEMENT = '99'
local _ALL_KILL_ICON = '[[File:AllKillIcon.png|link=All-Kill Format]]&nbsp;×&nbsp;'
local _EARNING_MODES = {['1v1'] = '1v1', ['team_individual'] = 'team'}

--race stuff
local _AVAILABLE_RACES = {'p', 't', 'z', 'r', 'total'}
local _RACE_FIELD_AS_CATEGORY_LINK = true

local _earningsGlobal = {}
local _CURRENT_YEAR = tonumber(os.date('%Y'))
local _shouldQueryData

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Person(frame)
	_args = player.args
	PersonSc2.setArgs(_args)

	player.shouldStoreData = PersonSc2.shouldStoreData
	player.getStatusToStore = PersonSc2.getStatusToStore
	player.adjustLPDB = PersonSc2.adjustLPDB
	player.getPersonType = PersonSc2.getPersonType
	player.nameDisplay = PersonSc2.nameDisplay

	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	_shouldQueryData = PersonSc2.shouldStoreData()

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {PersonSc2.getRaceData(_args.race or 'unknown', _RACE_FIELD_AS_CATEGORY_LINK)}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		local achievementCells = {}
		if _shouldQueryData then
			local achievements = Achievements({}, _PAGENAME)
			if not String.isEmpty(achievements) then
				table.insert(achievementCells, Center{content = {achievements}})
			end

			local allkills = CustomPlayer._getAllkills()
			if not String.isEmpty(allkills) and allkills ~= '0' then
				table.insert(achievementCells, Cell{
						name = 'All-kills',
						content = {_ALL_KILL_ICON .. allkills}
					})
			end

			if next(achievementCells) then
				table.insert(achievementCells, 1, Title{name = 'Achievements'})
			end
		end
		return achievementCells
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
	local rank1, rank2 = {}, {}
	local yearsActive
	if _shouldQueryData then
		rank1, rank2 = CustomPlayer._getRank(_PAGENAME)
		yearsActive = CustomPlayer._getMatchupData(_PAGENAME)
	end

	local currentYearEarnings = _earningsGlobal[tostring(_CURRENT_YEAR)]
	if currentYearEarnings then
		currentYearEarnings = Math.round{currentYearEarnings}
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Winnings ' .. _CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		Cell{name = rank1.name or 'Rank', content = {rank1.rank}},
		Cell{name = rank2.name or 'Rank', content = {rank2.rank}},
		Cell{name = 'Military Service', content = {PersonSc2.military(_args.military)}},
		Cell{name = 'Years active', content = {yearsActive}}
	}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:createBottomContent(infobox)
	if _shouldQueryData then
		return tostring(Matches._get_ongoing({})) ..
			tostring(Matches._get_upcoming({})) ..
			tostring(Matches._get_recent({}))
	end
end

function CustomPlayer._getMatchupData(player)
	local yearsActive
	player = string.gsub(player, '_', ' ')
	local cond = '[[opponent::' .. player .. ']] AND [[walkover::]] AND [[winner::>]]'
	local query = 'match2opponents, date'

	local data = CustomPlayer._getLPDBrecursive(cond, query, 'match2')

	local years = {}
	local vs = {}
	for _, item1 in pairs(_AVAILABLE_RACES) do
		vs[item1] = {}
		for _, item2 in pairs(_AVAILABLE_RACES) do
			vs[item1][item2] = {['win'] = 0, ['loss'] = 0}
		end
	end

	if type(data[1]) == 'table' then
		for i=1, #data do
			vs = CustomPlayer._addScoresToVS(vs, data[i].match2opponents, player)
			years[tonumber(string.sub(data[i].date, 1, 4))] = string.sub(data[i].date, 1, 4)
		end

		local category
		if years[_CURRENT_YEAR] or years[_CURRENT_YEAR - 1] or years[_CURRENT_YEAR - 2] then
			category = 'Active players'
			Variables.varDefine('isActive', 'true')
		else
			category = 'Players with no matches in the last three years'
		end

		yearsActive = CustomPlayer._getYearsActive(years)

		yearsActive = string.gsub(yearsActive, '<br>', '', 1)

		if not (String.isEmpty(category) or String.isEmpty(yearsActive)) then
			yearsActive = yearsActive .. '[[Category:' .. category .. ']]'
		end

		CustomPlayer._setVarsForVS(vs)
	end
	return yearsActive
end

function CustomPlayer._getYearsActive(years)
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

function CustomPlayer._setVarsForVS(table)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			for key3, item3 in pairs(item2) do
				Variables.varDefine(key1 .. '_vs_' .. key2 .. '_' .. key3, item3)
			end
		end
	end
end

function CustomPlayer._addScoresToVS(vs, opponents, player)
	local plIndex = 1
	local vsIndex = 2
	--catch matches vs empty opponents
	if opponents[1] and opponents[2] then
		if opponents[2].name == player then
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
	end

	return vs
end

function CustomPlayer:calculateEarnings()
	local earningsTotal
	earningsTotal, _earningsGlobal = CustomPlayer._getEarningsMedalsData(self.pagename)
	earningsTotal = Math.round{earningsTotal}
	return earningsTotal, _earningsGlobal
end

function CustomPlayer._getLPDBrecursive(cond, query, queryType)
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

function CustomPlayer._getEarningsMedalsData(player)
	local cond = '[[date::!1970-01-01 00:00:00]] AND ([[prizemoney::>0]] OR ' ..
		'([[mode::1v1]] AND ([[placement::1]] OR [[placement::2]] OR [[placement::3]]' ..
		' OR [[placement::4]] OR [[placement::3-4]]))) AND ' ..
		'[[participant::' .. player .. ']]'
	local query = 'liquipediatier, liquipediatiertype, placement, date, prizemoney, mode'

	local data = CustomPlayer._getLPDBrecursive(cond, query, 'placement')

	local earnings = {}
	local medals = {}
	earnings['total'] = {}
	medals['total'] = {}
	local earnings_total = 0

	if type(data[1]) == 'table' then
		for _, item in pairs(data) do
			--handle earnings
			earnings, earnings_total = CustomPlayer._addPlacementToEarnings(earnings, earnings_total, item)

			--handle medals
			medals = CustomPlayer._addPlacementToMedals(medals, item)
		end
	end

	CustomPlayer._setVarsFromTable(earnings)
	CustomPlayer._setVarsFromTable(medals)

	return earnings_total, earnings['total']
end

function CustomPlayer._addPlacementToEarnings(earnings, earnings_total, data)
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

function CustomPlayer._addPlacementToMedals(medals, data)
	if data.mode == '1v1' then
		local place = CustomPlayer._Placements(data.placement)
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

function CustomPlayer._setVarsFromTable(table)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine(key1 .. '_' .. key2, item2)
		end
	end
end

function CustomPlayer._Placements(value)
	value = (value or '') ~= '' and value or _DISCARD_PLACEMENT
	value = mw.text.split(value, '-')[1]
	if value ~= '1' and value ~= '2' and value ~= '3' then
		value = _DISCARD_PLACEMENT
	elseif value == '3' then
		value = 'sf'
	end
	return value
end

function CustomPlayer._getRank(player)
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

	local rank1 = CustomPlayer._getRankDisplay(data[1])
	local rank2 = CustomPlayer._getRankDisplay(data[2])

	return rank1, rank2
end

function CustomPlayer._getRankDisplay(data)
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

function CustomPlayer._getAllkills()
	if _shouldQueryData then
		local allkillsData = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[pagename::' .. _PAGENAME .. ']] AND [[type::allkills]]',
			query = 'information',
			limit = 1
		})
		if type(allkillsData[1]) == 'table' then
			return allkillsData[1].information
		end
	end
end

return CustomPlayer
