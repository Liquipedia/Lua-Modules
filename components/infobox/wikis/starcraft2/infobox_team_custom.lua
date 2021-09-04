---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Achievements = require('Module:Achievements in infoboxes')
local RaceIcon = require('Module:RaceIcon').getSmallIcon
local Matches = require('Module:Upcoming ongoing and recent matches team/new')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Builder = require('Module:Infobox/Widget/Builder')
local Center = require('Module:Infobox/Widget/Center')
local Breakdown = require('Module:Infobox/Widget/Breakdown')

local doStore = true
local pagename = mw.title.getCurrentTitle().prefixedText

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)
local Language = mw.language.new('en')

local _team

local _EARNINGS = 0
local _ALLOWED_PLACES = { '1', '2', '3', '4', '3-4' }
local _EARNINGS_MODES = { ['team'] = 'team' }
local _DISCARD_PLACEMENT = 99

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Gaming Director',
		content = {_team.args['gaming director']}
	}))
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		if _EARNINGS == 0 then
			_EARNINGS = nil
		else
			_EARNINGS = '$' .. Language:formatNum(earnings)
		end
		return {
			Cell{
				name = 'Earnings',
				content = {_EARNINGS}
			}
		}
	elseif id == 'achievements' then
		local achievements, soloAchievements = CustomTeam.getAutomatedAchievements(pagename)
		return {
			Builder{
				builder = function()
					if achievements then
						return {
							Title{name = 'Achievements'},
							Center{content = {achievements}},
						}
					end
				end
			},
			Builder{
				builder = function()
					if soloAchievements then
						return {
							Title{name = 'Solo Achievements'},
							Center{content = {soloAchievements}},
						}
					end
				end
			},
			--yes i know this doesn't seem suitable for this id,
			--but i need this ABOVE the history display
			Builder{
				builder = function()
					local playerBreakDown = CustomTeam.playerBreakDown(_team.args)
					if playerBreakDown.playernumber then
						return {
							Title{name = 'Player Breakdown'},
							Cell{name = 'Number of players', content = {playerBreakDown.playernumber}},
							Breakdown{content = playerBreakDown.display}
						}
					end
				end
			}
		}
	elseif id == 'history' then
		for i=1, 5 do
			table.insert(widgets, Cell{
				name = _team.args['history' .. i .. 'title'] or '-',
				content = {CustomTeam.customHistory(_team.args, i)}
			})
		end
	end
	return widgets
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:createBottomContent()
	if doStore then
		return tostring(Matches._get_ongoing({})) ..
			tostring(Matches._get_upcoming({})) ..
			tostring(Matches._get_recent({}))
	end
end

function CustomTeam:addToLpdb(lpdbData)
	_EARNINGS = CustomTeam.calculateEarnings(_team.args)
	lpdbData.earnings = _EARNINGS
	Variables.varDefine('team_name', lpdbData.name)
	return lpdbData
end

function CustomTeam.playerBreakDown(args)
	local playerBreakDown = {}
	local playernumber = tonumber(args.player_number or 0) or 0
	local zergnumber = tonumber(args.zerg_number or 0) or 0
	local terrannumbner = tonumber(args.terran_number or 0) or 0
	local protossnumber = tonumber(args.protoss_number or 0) or 0
	local randomnumber = tonumber(args.random_number or 0) or 0
	if playernumber == 0 then
		playernumber = zergnumber + terrannumbner + protossnumber + randomnumber
	end

	if playernumber > 0 then
		playerBreakDown.playernumber = playernumber
		if zergnumber + terrannumbner + protossnumber + randomnumber > 0 then
			playerBreakDown.display = {}
			if protossnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon({'p'}) .. ' ' .. protossnumber
			end
			if terrannumbner > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon({'t'}) .. ' ' .. terrannumbner
			end
			if zergnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon({'z'}) .. ' ' .. zergnumber
			end
			if randomnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1] = RaceIcon({'r'}) .. ' ' .. randomnumber
			end
		end
	end
	return playerBreakDown
end

function CustomTeam.getAutomatedAchievements(team)
	local achievements = Achievements.team({team=team})
	local achievementsSolo = Achievements.team_solo({team=team})
	if achievements == '' then achievements = nil end
	if achievementsSolo == '' then achievementsSolo = nil end

	return achievements, achievementsSolo
end

function CustomTeam.customHistory(args, number)
	if args['history' .. number .. 'title'] then
		return args['history' .. number]
	end
end

function CustomTeam.calculateEarnings(args)
	if args.disable_smw == 'true' or args.disable_lpdb == 'true' or args.disable_storage == 'true'
		or Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or mw.title.getCurrentTitle().nsText ~= '' then
			doStore = false
			Variables.varDefine('disable_SMW_storage', 'true')
	else
		local earnings = CustomTeam.getEarningsAndMedalsData(pagename) or 0
		Variables.varDefine('earnings', earnings)
		return earnings
	end
	return 0
end

function CustomTeam._getLPDBrecursive(cond, query, queryType)
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

function CustomTeam.getEarningsAndMedalsData(team)
	local cond = '[[date::!1970-01-01 00:00:00]] AND ([[prizemoney::>0]] OR [[placement::' ..
		table.concat(_ALLOWED_PLACES, ']] OR [[placement::')
		.. ']]) AND(' .. '[[participant::' .. team .. ']] OR ' ..
		'([[mode::!team_individual]] AND ([[extradata_participantteamclean::' ..
		string.lower(team) .. ']] OR [[extradata_participantteamclean::' .. team .. ']] OR ' ..
		'[[extradata_participantteam::' .. team .. ']])))'
	local query = 'liquipediatier, placement, date, prizemoney, mode'

	local data = CustomTeam._getLPDBrecursive(cond, query, 'placement')

	local earnings = {}
	local medals = {}
	local teamMedals = {}
	local player_earnings = 0
	earnings['total'] = {}
	medals['total'] = {}
	teamMedals['total'] = {}

	if type(data[1]) == 'table' then
		for _, item in pairs(data) do
			--handle earnings
			earnings, player_earnings = CustomTeam._addPlacementToEarnings(earnings, player_earnings, item)

			--handle medals
			if item.mode == '1v1' then
				medals = CustomTeam._addPlacementToMedals(medals, item)
			elseif item.mode == 'team' then
				teamMedals = CustomTeam._addPlacementToMedals(teamMedals, item)
			end
		end
	end

	CustomTeam._setVarsFromTable(earnings)
	CustomTeam._setVarsFromTable(medals)
	CustomTeam._setVarsFromTable(teamMedals, 'team_')

	if earnings.team == nil then
		earnings.team = {}
	end

	if doStore then
		mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
				type = 'total_earnings_players_while_on_team',
				name = pagename,
				information = player_earnings,
		})
	end

	return math.floor((earnings.team.total or 0) * 100 + 0.5) / 100
end

function CustomTeam._addPlacementToEarnings(earnings, player_earnings, data)
	local mode = _EARNINGS_MODES[data.mode] or 'other'
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local date = string.sub(data.date, 1, 4)
	earnings[mode][date] = (earnings[mode][date] or 0) + data.prizemoney
	earnings[mode]['total'] = (earnings[mode]['total'] or 0) + data.prizemoney
	earnings['total'][date] = (earnings['total'][date] or 0) + data.prizemoney
	if data.mode ~= 'team' then
		player_earnings = player_earnings + data.prizemoney
	end

	return earnings, player_earnings
end

function CustomTeam._addPlacementToMedals(medals, data)
	local place = CustomTeam._Placements(data.placement)
	if place ~= _DISCARD_PLACEMENT then
		if data.liquipediatiertype ~= 'Qualifier' then
			local tier = data.liquipediatier or 'undefined'
			if not medals[place] then
				medals[place] = {}
			end
			medals[place][tier] = (medals[place][tier] or 0) + 1
			medals[place]['total'] = (medals[place]['total'] or 0) + 1
			medals['total'][tier] = (medals['total'][tier] or 0) + 1
		end
	end

	return medals
end

function CustomTeam._setVarsFromTable(table, prefix)
	for key1, item1 in pairs(table) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine((prefix or '') .. key1 .. '_' .. key2, item2)
		end
	end
end

function CustomTeam._Placements(value)
	value = (value or '') ~= '' and value or _DISCARD_PLACEMENT
	value = mw.text.split(value, '-')[1]
	if value ~= '1' and value ~= '2' and value ~= '3' then
		value = _DISCARD_PLACEMENT
	elseif value == '3' then
		value = 'sf'
	end
	return value
end

return CustomTeam
