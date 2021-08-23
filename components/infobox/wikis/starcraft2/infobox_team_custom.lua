local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Links = require('Module:Links')
local Achievements = require('Module:Achievements in infoboxes')
local RaceIcon = require('Module:RaceIcon').getSmallIcon
local Matches = require('Module:Upcoming ongoing and recent matches team/new')

local doStore = true
local earningsGlobal = 0
local pagename = mw.title.getCurrentTitle().prefixedText

local StarCraft2Team = {}

function StarCraft2Team.run(frame)
	local team = Team(frame)
	team.addCustomCells = StarCraft2Team.addCustomCells
	team.calculateEarnings = StarCraft2Team.calculateEarnings
	team.getAchievements = StarCraft2Team.getAchievements
	team.getHistory = StarCraft2Team.getHistory
	team.addCustomContent = StarCraft2Team.addCustomContent
	team.createBottomContent = StarCraft2Team.createBottomContent
	return team:createInfobox(frame)
end

function StarCraft2Team.addCustomCells(team, infobox, args)
	infobox	:cell('Gaming Director', args['gaming director'])
	return infobox
end

function StarCraft2Team:createBottomContent()
	if doStore then
		return tostring(Matches._get_ongoing({})) ..
			tostring(Matches._get_upcoming({})) ..
			tostring(Matches._get_recent({}))
	end
end

function StarCraft2Team.addCustomContent(team, infobox, args)
	local achievements, soloAchievements = StarCraft2Team.getAutomatedAchievements(pagename)
	local playerBreakDown = StarCraft2Team.playerBreakDown(args)

	infobox	:header('Achievements', achievements)
			:centeredCell(achievements)
			:header('Solo Achievements', soloAchievements)
			:centeredCell(soloAchievements)
			:header('Player Breakdown', playerBreakDown.playernumber)
			:cell('Number of players', playerBreakDown.playernumber)
			:fcell(StarCraft2Team.playerBreakDownDisplay(playerBreakDown.display))
			:header('History', args.created)
			:cell('Created', args.created)
			:cell('Disbanded', args.disbanded)
			:cell(args.history1title or '', StarCraft2Team.customHistory(args, 1))
			:cell(args.history2title or '', StarCraft2Team.customHistory(args, 2))
			:cell(args.history3title or '', StarCraft2Team.customHistory(args, 3))
			:cell(args.history4title or '', StarCraft2Team.customHistory(args, 4))
			:cell(args.history5title or '', StarCraft2Team.customHistory(args, 5))

	if doStore then
		StarCraft2Team.storeToLPDB(args)
	end

	return infobox
end

function StarCraft2Team.playerBreakDownDisplay(contents)
    if type(contents) ~= 'table' or contents == {} then
        return nil
    end

    local div = mw.html.create('div')
    local number = #contents
    for _, content in ipairs(contents) do
        local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number
			.. ' infobox-center')
        infoboxCustomCell:wikitext(content)
        div:node(infoboxCustomCell)
    end

    return div
end

function StarCraft2Team.storeToLPDB(args)
	local name = args.romanized_name or args.name or pagename
	Variables.varDefine('team_name', name)
	local links = Links.transform(args)
	for key, item in pairs(links) do
		if key == 'aligulac' then
			links[key] = 'http://aligulac.com/teams/' .. item
		elseif key == 'esl' then
			links[key] = 'https://play.eslgaming.com/team/' .. item
		else
			links[key] = Links.makeFullLink(key, item)
		end
	end

	mw.ext.LiquipediaDB.lpdb_team('team_' .. name, {
		name = name,
		location = args.location or '',
		location2 = args.location2 or '',
		logo = args.image or '',
		createdate = args.created or '',
		disbanddate = args.disbanded or '',
		earnings = earningsGlobal,
		coach = args.coaches or '',
		manager = args.manager or '',
		sponsors = args.sponsor or '',
		links = mw.ext.LiquipediaDB.lpdb_create_json(links),
		})
end

function StarCraft2Team.playerBreakDown(args)
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

function StarCraft2Team.getAutomatedAchievements(team)
	local achievements = Achievements.team({team=team})
	local achievementsSolo = Achievements.team_solo({team=team})
	if achievements == '' then achievements = nil end
	if achievementsSolo == '' then achievementsSolo = nil end

	return achievements, achievementsSolo
end

function StarCraft2Team.customHistory(args, number)
	if args['history' .. number .. 'title'] then
		return args['history' .. number]
	end
end

function StarCraft2Team.calculateEarnings(_, args)
	if args.disable_smw == 'true' or args.disable_lpdb == 'true' or args.disable_storage == 'true'
		or Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or mw.title.getCurrentTitle().nsText ~= '' then
			doStore = false
			Variables.varDefine('disable_SMW_storage', 'true')
	else
		earningsGlobal = StarCraft2Team.get_earnings_and_medals_data(pagename) or 0
		Variables.varDefine('earnings', earningsGlobal)
		return earningsGlobal
	end
	return 0
end

--kick the default achievements display
function StarCraft2Team:getAchievements(infobox, args)
	return nil
end

--kick the default history display
function StarCraft2Team:getHistory(infobox, args)
	return {}
end

function StarCraft2Team.get_earnings_and_medals_data(team)
	local AllowedPlaces = { '1', '2', '3', '4', '3-4' }
	local cond = '[[date::!1970-01-01 00:00:00]] AND ([[prizemoney::>0]] OR [[placement::' ..
		table.concat(AllowedPlaces, ']] OR [[placement::') .. ']]) AND(' .. '[[participant::' ..
		team .. ']] OR ([[mode::!team_individual]] AND ([[extradata_participantteamclean::' ..
		string.lower(team) .. ']] OR [[extradata_participantteamclean::' .. team .. ']] OR ' ..
		'[[extradata_participantteam::' .. team .. ']])))'
	local count
	local data = {} -- get LPDB results in here
	local offset = 0
	repeat
		local additional_data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = cond,
			query = 'liquipediatier, placement, date, prizemoney, mode',
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

	local EarningModes = { ['team'] = 'team' }

	local earnings = {}
	local Medals = {}
	local TeamMedals = {}
	local player_earnings = 0
	earnings['total'] = {}
	Medals['total'] = {}
	TeamMedals['total'] = {}

	if type(data[1]) == 'table' then
		for i=1,#data do
			--handle earnings
			if data[i].mode ~= 'team' then
				player_earnings = player_earnings + data[i].prizemoney
			end
			local earningsMode = EarningModes[data[i].mode] or 'other'
			if not earnings[earningsMode] then
				earnings[earningsMode] = {}
			end
			if not earnings[earningsMode][string.sub(data[i].date, 1, 4)] then
				earnings[earningsMode][string.sub(data[i].date, 1, 4)] = 0
			end
			if not earnings[earningsMode]['total'] then
				earnings[earningsMode]['total'] = 0
			end
			if not earnings['total'][string.sub(data[i].date, 1, 4)] then
				earnings['total'][string.sub(data[i].date, 1, 4)] = 0
			end
			earnings[earningsMode]['total'] = earnings[earningsMode]['total']
				+ data[i].prizemoney
			earnings[earningsMode][string.sub(data[i].date, 1, 4)] =
				earnings[earningsMode][string.sub(data[i].date, 1, 4)] + data[i].prizemoney
			earnings['total'][string.sub(data[i].date, 1, 4)] =
				earnings['total'][string.sub(data[i].date, 1, 4)] + data[i].prizemoney

			--handle medals
			if data[i].mode == '1v1' then
				data[i].placement = StarCraft2Team._Placements(data[i].placement)
				if data[i].placement ~= '99' then
					if not data[i].liquipediatiertype == 'Qualifier' then
						if not Medals[data[i].placement] then
							Medals[data[i].placement] = {}
						end
						local tier = data[i].liquipediatier or 'undefined'
						if not Medals[data[i].placement][tier] then
							Medals[data[i].placement][tier] = 0
						end
						if not Medals[data[i].placement]['total'] then
							Medals[data[i].placement]['total'] = 0
						end
						Medals[data[i].placement][tier] = Medals[data[i].placement][tier] + 1
						Medals[data[i].placement]['total'] = Medals[data[i].placement]['total'] + 1
						if not Medals['total'][tier] then
							Medals['total'][tier] = 0
						end
						Medals['total'][tier] = Medals['total'][tier] + 1
					end
				end
			elseif data[i].mode == 'team' then
				data[i].placement = StarCraft2Team._Placements(data[i].placement)
				if data[i].placement ~= '99' then
					if not data[i].liquipediatiertype == 'Qualifier' then
						if not TeamMedals[data[i].placement] then
							TeamMedals[data[i].placement] = {}
						end
						local tier = data[i].liquipediatier or 'undefined'
						if not TeamMedals[data[i].placement][tier] then
							TeamMedals[data[i].placement][tier] = 0
						end
						if not TeamMedals[data[i].placement]['total'] then
							TeamMedals[data[i].placement]['total'] = 0
						end
						TeamMedals[data[i].placement][tier] = TeamMedals[data[i].placement][tier] + 1
						TeamMedals[data[i].placement]['total'] = TeamMedals[data[i].placement]['total'] + 1
						if not TeamMedals['total'][tier] then
							TeamMedals['total'][tier] = 0
						end
						TeamMedals['total'][tier] = TeamMedals['total'][tier] + 1
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

	for key1, item1 in pairs(TeamMedals) do
		for key2, item2 in pairs(item1) do
			Variables.varDefine('team_' .. key1 .. '_' .. key2, item2)
		end
	end

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

function StarCraft2Team._Placements(value)
	value = (value or '') ~= '' and value or '99'
	local temp = mw.text.split(value, '-')[1]
	if temp ~= '1' and temp ~= '2' and temp ~= '3' then
		temp = '99'
	elseif temp == '3' then
		temp = 'sf'
	end
	return temp
end

return StarCraft2Team
