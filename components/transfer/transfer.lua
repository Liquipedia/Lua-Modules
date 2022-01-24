local Flag = require('Module:Flags')
local Arguments = require('Module:Arguments')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local Transfer = {}

local _SECONDS_24_HOURS = 86400

---
-- These strings are "reserved" keywords, e.g. so that we can set a player to Retired
local _SPECIAL_TEAMS = {
    'inactive',
    'active',
    'retired',
    'none'
}

-- Provide for backwards compatibility
function Transfer.row(frame)
	return Transfer.create(frame)
end

function Transfer.create(frame)
	local args = Arguments.getArgs(frame)

	local date = args.date_est or args.date
	local parsedArgs, refTable = Transfer._parseArgs(args)

	local row = mw.html.create('div')
	row:attr('class', 'divRow mainpage-transfer-' ..
		Transfer._getStatus(parsedArgs.team1, parsedArgs.team2))
	row:node(Transfer._createDate(parsedArgs.date))
	if (parsedArgs.platformIcons or '') == 'true' then
		row:node(Transfer._createPlatform(parsedArgs))
	end
	row:node(Transfer._createName(parsedArgs))
	row:node(Transfer._createTeam(
		parsedArgs.team1, parsedArgs.team1_2, parsedArgs.role1, parsedArgs.role1_2, true, parsedArgs.from_date))
	row:node(Transfer._createIcon(parsedArgs.transferIcon))
	row:node(Transfer._createTeam(
		parsedArgs.team2, parsedArgs.team2_2, parsedArgs.role2, parsedArgs.role2_2, false, date))
	row:node(Transfer._createReferences(parsedArgs.ref, refTable))

	local shouldDisableLpdbStorage = Logic.readBool(
		mw.ext.VariablesLua.var('disable_LPDB_storage'))
	local shouldDisableSmwStorage = Logic.readBool(
		mw.ext.VariablesLua.var('disable_SMW_storage'))
	if not shouldDisableLpdbStorage and not shouldDisableSmwStorage and (
		parsedArgs.disable_storage or 'false') ~= 'true' and
		mw.title.getCurrentTitle():inNamespaces(0) then
		local transferSortIndex = mw.ext.VariablesLua.var('transfer_sort_index')
		if transferSortIndex == nil then
			mw.ext.VariablesLua.vardefine('transfer_sort_index', 0)
		end
		Transfer._saveToLpdb(parsedArgs, date, refTable)
	end
	return row
end

function Transfer._parseArgs(args)
	args.from_date = Transfer.adjustDate(args.date_est or args.date)

	Transfer._parseRole(args)
	Transfer._parsePosition(args)

	local nameIndex = 2
	while (args['name' .. nameIndex] ~= nil) do
		args['posIcon' .. nameIndex] = args[(args.iconParam or 'pos') .. nameIndex] and
		(args[(args.iconParam or 'pos') .. nameIndex] .. (args['sub' .. nameIndex] and
		'_Substitute' or '')) or (args['sub' .. nameIndex] and 'Substitute' or '')
		nameIndex = nameIndex + 1
	end

	local refTable, refIndex = {}, 0
	args.allRef = true -- Enter all references for all players into LPDB
	if args.refType == 'table' and args.ref then
		local references = mw.text.split(args.ref, ';;;', true)
		for index, fullRef in pairs(references) do
			if fullRef ~= '' then
				refTable['reference' .. index] = fullRef
				refIndex = refIndex + 1
			end
		end

		-- same amount of players and references? individually allocate them later for LPDB storage
		-- special case: 2 refs/players (often times this will be a reference from both teams)
		if nameIndex == refIndex and (refIndex > 2 or not(args.team1) or not(args.team2)) then
			args.allRef = false
		end
	end

	return args, refTable
end

function Transfer._parseRole(args)
	for i= 1, 2 do
		local roleIndex = 'role' .. i
		local role = args[roleIndex]
		local role2Index = 'role' .. i .. '_2'
		local role2= args[role2Index]
		args[roleIndex] = role and Transfer._firstToUpper(role)
		args[role2Index] = role2 and Transfer._firstToUpper(role2)

		-- for " multi transfers" move inactive part to secondary
		local isFirstRoleInactive = (args[role2Index] and
			args[role2Index] ~= 'Inactive') and
			(args[roleIndex] and args[roleIndex] == 'Inactive')
		if isFirstRoleInactive then
			-- swap
			args[roleIndex] = args[role2Index]
			args[role2Index] = args[roleIndex]
			args['team' .. i] = args['team' .. i .. '_2']
			args['team' .. i .. '_2'] = args['team' .. i]
		end
	end
end

function Transfer._parsePosition(args)
	local nameIndex = 2
	if args.positionConvert then
		local getPositionName = mw.loadData(args.positionConvert)
		args[(args.iconParam or 'pos')] =
			getPositionName[string.lower(args[(args.iconParam or 'pos')] or '')] or
			args[(args.iconParam or 'pos')]
		while (args['name' .. nameIndex] ~= nil) do
			args[(args.iconParam or 'pos') .. nameIndex] =
				getPositionName[string.lower(args[(args.iconParam or 'pos') .. nameIndex] or '')] or
				args[(args.iconParam or 'pos') .. nameIndex]
			nameIndex = nameIndex + 1
		end
	end
	args.posIcon = args[(args.iconParam or 'pos')] and
		(args[(args.iconParam or 'pos')] .. (args.sub and '_Substitute' or '')) or
		(args.sub and 'Substitute' or '')
end

function Transfer._firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

---
-- Returns true if the team string denotes a reserved string, see specialTeams
--
function Transfer._isSpecialTeam(team)
    for _, value in ipairs(_SPECIAL_TEAMS) do
        if value == string.lower(team) then
            return true
        end
    end

    return false
end

function Transfer._getStatus(team1, team2)
    if team1 ~= nil and not Transfer._isSpecialTeam(team1) then
        if team2 ~= nil and not Transfer._isSpecialTeam(team2) then
            return 'neutral'
        end

        return 'from-team'
    end

    if team2 ~= nil and Transfer._isSpecialTeam(team2) then
        return 'from-team'
    end

    return 'to-team'
end

function Transfer._createDate(date)
	local div = mw.html.create('div')
	div:attr('class', 'divCell Date')
	div:wikitext(date)

	return div
end

function Transfer._createPlatform(args)
	local getPlatform = require('Module:Platform')
	args.platform = getPlatform._getName(args.platform)

	local div = mw.html.create('div')
	div:attr('class', 'divCell GameIcon')
	div:wikitext(getPlatform._getIcon(args.platform))

	return div
end

function Transfer._createName(args)
	local getIcon
	if args.iconModule then
		getIcon = mw.loadData(args.iconModule)
	end

	local div = mw.html.create('div')
	div:attr('class', 'divCell Name')
	div:wikitext(Transfer._createNameRow(
		args.name, args.flag, args.link, args.posIcon, getIcon))

	local nameIndex = 2
	while (args['name' .. nameIndex] ~= nil) do
		div:wikitext('<br/>')
		div:wikitext(Transfer._createNameRow(
			args['name' .. nameIndex],
			args['flag' .. nameIndex],
			args['link' .. nameIndex],
			args['posIcon' .. nameIndex],
			getIcon
		))
		nameIndex = nameIndex + 1
	end

	return div
end

function Transfer._createNameRow(name, flag, link, icon, iconModule)
	local row = ''

	if flag ~= nil then
		row = row .. Flag.Icon({flag = flag, shouldLink = true}) .. ' '
	else
		row = row .. '<span class=flag>[[File:Space filler flag.png|link=]]</span> '
	end

	if icon and iconModule then
		local iconTemp = iconModule[ string.lower(icon) ]
		if iconTemp then
			row = row .. iconTemp .. ' '
		else
			mw.log( 'No entry found in Module:PositionIcon/data: ' .. icon .. ' (' .. name .. ')')
			row = row .. '[[File:Logo filler event.png|16px|link=]][[Category:Pages with transfer errors]] '
		end
	end

	row = row .. '[[' .. (link or name) .. '|' .. name .. ']]'

	return row
end

function Transfer._createTeam(team, teamsec, role, rolesec, isOldTeam, date)
	local teamCell = mw.html.create('div')
	teamCell:attr('class', 'divCell Team ' .. (isOldTeam and 'OldTeam' or 'NewTeam'))

	if team == nil and role == nil then
		teamCell:css('font-style', 'italic')
		teamCell:wikitext('None')
		return teamCell
	end

	if team then
		teamCell:node(mw.ext.TeamTemplate.teamicon(team, date))
	end
	if teamsec then
		teamCell:node('/' .. mw.ext.TeamTemplate.teamicon(teamsec, date))
	end
	teamCell:node(Transfer._createRole(role, rolesec, team))

	return teamCell
end

function Transfer._createRole(role, rolesec, hasTeam)
	if role == nil then
		return nil
	end

	local span = mw.html.create('span')
	if hasTeam then
		span:wikitext('<br/>')
		span:css('font-size', '85%')
		span:css('font-style', 'italic')
		span:wikitext('(' .. role .. (rolesec and '/' .. rolesec or '') .. ')')
	else
		span:css('font-style', 'italic')
		span:wikitext(role .. (rolesec and '/' .. rolesec or ''))
	end

	return span
end

function Transfer._createIcon(icon)
	local div = mw.html.create('div'):attr('class', 'divCell Icon'):css('font-size','larger')

	if icon == nil then
		div:wikitext('&#x21d2;')
	else
		div:wikitext(icon)
	end

	return div
end

function Transfer._createReferences(reference, refTable)
	local div = mw.html.create('div'):attr('class', 'divCell Ref')

	if not(refTable['reference1']) then
		div:wikitext(reference)
	else
		local refPrint = ''
		for _, fullRef in Table.iter.pairsByPrefix(refTable, 'reference') do
			local refTemp = mw.text.split(fullRef, ',,,', true)
			if (refTemp[1] or '') == 'web source' and (refTemp[2] or '') ~= '' then
				refPrint = refPrint .. '[' .. refTemp[2] .. '<i class="fad fa-external-link-alt wiki-color-dark"></i>]' .. '<br>'
			elseif (refTemp[1] or '') == 'tournament source' then
				refPrint = refPrint .. '[[' .. refTemp[2] .. '|' .. 
					mw.getCurrentFrame():callParserFunction{ name = '#tag:abbr', args = {
						'<i class="fad fa-link wiki-color-dark"></i>',
						title = 'Transfer wasn\'t formally announced, but individual represented team starting with this tournament'
					} } .. ']]<br>'
			elseif (refTemp[1] or '') == 'inside source' then
				refPrint = refPrint ..
					mw.getCurrentFrame():callParserFunction{ name = '#tag:abbr', args = {
						'<i class="fad fa-user-secret wiki-color-dark"></i>',
						title = 'Liquipedia has gained this information from a trusted inside source'
					} } .. '<br>'
			end
		end
		div:wikitext(refPrint)
	end

	return div
end

---
-- Saves all players to LPDB
--
function Transfer._saveToLpdb(args, date, refTable)
	Transfer._savePlayerToLpdb(args, date, refTable, 1)

	local index = 2
	while (args['name' .. index]  ~= nil) do
		Transfer._savePlayerToLpdb(args, date, refTable, index)
		index = index + 1
	end
end

---
-- Saves an individual player to LPDB
--
function Transfer._savePlayerToLpdb(args, date, refTable, index)
	local references
	if refTable['reference1'] and args.allRef then
		references = refTable
	else
		references = { reference1 = refTable['reference' .. index] or args.ref or '' }
	end
	local name, flag, link, pos, icon, sub
	if index == 1 then
		name = args.name
		flag = args.flag
		link = args.link or args.name
		pos = args[(args.iconParam or 'pos')]
		icon = args.posIcon
		sub = args.sub
	else
		name = args['name' .. index]
		flag = args['flag' .. index]
		link = args['link' .. index] or args['name' .. index]
		pos = args[(args.iconParam or 'pos') .. index]
		icon = args['posIcon' .. index]
		sub = args['sub' .. index]
	end

	local transferSortIndex = tonumber(mw.ext.VariablesLua.var('transfer_sort_index')) or 0
	-- note: playername is currently not part of the objectname due to LPDB issues with pending edits
	mw.ext.LiquipediaDB.lpdb_transfer('transfer_' .. date .. '_' .. transferSortIndex, {
			player = mw.ext.TeamLiquidIntegration.resolve_redirect(link),
			nationality = flag and Flags.CountryName(flag),
			fromteam = args.team1 and mw.ext.TeamTemplate.teampage(args.team1, args.from_date),
			toteam = args.team2 and mw.ext.TeamTemplate.teampage(args.team2, date),
			role1 = args.role1 or args.team1 and sub and 'Substitute',
			role2 = args.role2 or args.team2 and sub and 'Substitute',
			reference = references,
			date = date,
			wholeteam = Logic.readBool(args.wholeteam) and 1 or 0,
			extradata = mw.ext.LiquipediaDB.lpdb_create_json({
				displaydate = args.date or '',
				position = pos,
				icon = icon or '',
				icontype = sub and 'Substitute' or '',
				displayname = name or '',
				fromteamsec = args.team1_2 and mw.ext.TeamTemplate.teampage(args.team1_2, date) or '',
				toteamsec = args.team2_2 and mw.ext.TeamTemplate.teampage(args.team2_2, date) or '',
				role1sec = args.role1_2 or '',
				role2sec = args.role2_2 or '',
				sortindex = transferSortIndex,
				platform = args.platform or ''
			})
	})

	mw.ext.VariablesLua.vardefine('transfer_sort_index', transferSortIndex + 1)
end

-- earlier date for fromteam to account for rebrands
function Transfer.adjustDate(date)
	if type(date) == 'string' then
		local year, month, day = date:match('(%d+)-(%d+)-(%d+)')
		date = os.time({day=day, month=month, year=year})
		date = date - _SECONDS_24_HOURS
		date = os.date( "%Y-%m-%d", date)
	end
	return date
end


return Transfer
