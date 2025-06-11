---
-- @Liquipedia
-- page=Module:TeamCard/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Custom = Lua.import('Module:TeamCard/Custom')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local TeamCardStorage = {}

---@param args table
---@param teamObject {teamtemplate: string?, lpdb: string, team2: string?, team3: string?, aliases: string[]?}
---@param players table
---@param playerPrize number
function TeamCardStorage.saveToLpdb(args, teamObject, players, playerPrize)
	local team, teamTemplateName

	if type(teamObject) == 'table' then
		if teamObject.team2 or teamObject.team3 then
			team = 'TBD'
		else
			teamTemplateName = teamObject.teamtemplate
			team = teamObject.lpdb
		end
	end

	local lpdbPrefix = args.lpdb_prefix or Variables.varDefault('lpdb_prefix') or ''

	-- Setup LPDB Data
	local lpdbData = {}
	lpdbData = TeamCardStorage._addStandardLpdbFields(lpdbData, team, args, lpdbPrefix)
	lpdbData.participanttemplate = teamTemplateName
	lpdbData.players = players
	lpdbData.individualprizemoney = playerPrize

	-- If a custom override for LPDB exists, use it
	lpdbData = Custom.adjustLpdb and Custom.adjustLpdb(lpdbData, team, args, lpdbPrefix) or lpdbData

	-- Store aliases (page names) for opponenets for setting page vars
	if Table.isNotEmpty(teamObject.aliases) then
		lpdbData.extradata.opponentaliases = teamObject.aliases
	end

	-- Store into the standardized lpdb fields
	lpdbData = Table.mergeInto(lpdbData, Opponent.toLpdbStruct(Opponent.resolve(
		Opponent.readOpponentArgs{type = Opponent.team, template = teamTemplateName} or Opponent.tbd(Opponent.team),
		lpdbData.date
	)))
	lpdbData = Json.stringifySubTables(lpdbData)
	lpdbData.opponentplayers = lpdbData.players -- Until this is included in Opponent

	mw.ext.LiquipediaDB.lpdb_placement(lpdbData.objectName, lpdbData)
end

-- Adds basic lpdb fields
---@param lpdbData table
---@param team string
---@param args table
---@param lpdbPrefix string
---@return table
function TeamCardStorage._addStandardLpdbFields(lpdbData, team, args, lpdbPrefix)
	-- Name must match prize pool insertion
	lpdbData.objectName = TeamCardStorage._getLpdbObjectName(team, lpdbPrefix)

	local title = mw.title.getCurrentTitle().text
	local tournamentName = Variables.varDefault('tournament name pp') or Variables.varDefault('tournament_name')
	local date = Variables.varDefault('tournament_date')
	local startDate = Variables.varDefault('tournament_startdate', date)
	local endDate = Variables.varDefault('tournament_enddate', date)

	lpdbData.participant = team
	lpdbData.tournament = tournamentName or title
	lpdbData.series = Variables.varDefault('tournament_series')
	lpdbData.parent = Variables.varDefault('tournament_parent')
	lpdbData.startdate = startDate
	lpdbData.date = args.date
		or Variables.varDefault(lpdbData.objectName .. '_placementdate')
		or endDate
	lpdbData.qualifier, lpdbData.qualifierpage, lpdbData.qualifierurl = TeamCardStorage._parseQualifier(args.qualifier)

	if team ~= 'TBD' then
		lpdbData.image = args.image1
		lpdbData.imagedark = args.imagedark1
	end

	lpdbData.mode = Variables.varDefault('tournament_mode', 'team')
	lpdbData.publishertier = Variables.varDefault('tournament_publishertier')
	lpdbData.icon = Variables.varDefault('tournament_icon')
	lpdbData.icondark = Variables.varDefault('tournament_icondark')
	lpdbData.game = Variables.varDefault('tournament_game')
	lpdbData.liquipediatier = Variables.varDefault('tournament_liquipediatier')
	lpdbData.liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype')
	lpdbData.extradata = {}

	return lpdbData
end

-- Build the standard LPDB "Object Name", which is used as primary key in the DB record
---@param team string
---@param lpdbPrefix string?
---@return string
function TeamCardStorage._getLpdbObjectName(team, lpdbPrefix)
	local storageName = (team == 'TBD' and 'participant') or 'ranking'
	if String.isNotEmpty(lpdbPrefix) then
		storageName = storageName .. '_' .. lpdbPrefix
	end
	storageName = storageName .. '_' .. mw.ustring.lower(team)
	if team == 'TBD' then
		local placement = tonumber(Variables.varDefault('TBD_placements', '1'))
		storageName = storageName .. '_' .. placement
		Variables.varDefine('TBD_placements', placement + 1)
	end
	return storageName
end

--- Link internal and link external is mutually exclusive
---@param rawQualifier string?
---@return string? #link text
---@return string? #internal link
---@return string? #external link
function TeamCardStorage._parseQualifier(rawQualifier)
	if not rawQualifier then
		return nil, nil, nil
	end

	local cleanQualifier = rawQualifier:gsub('%[', ''):gsub('%]', '')
	if cleanQualifier:find('|') then
		-- Internal link
		local qualifier = mw.text.split(cleanQualifier, '|', true)
		local qualifierLink, qualifierText = qualifier[1], qualifier[2]

		if qualifierLink:sub(1, 1) == '/' then
			-- Relative link
			qualifierLink = mw.title.getCurrentTitle().fullText .. qualifierLink
		end
		qualifierLink = qualifierLink:gsub(' ', '_')
		return qualifierText, qualifierLink, nil

	elseif rawQualifier:sub(1, 1) == '[' then
		-- Not internal link, but a link -> must be external link
		local qualifier = mw.text.split(cleanQualifier, ' ', true)
		local qualifierLink = qualifier[1]

		table.remove(qualifier, 1)
		local qualifierText = table.concat(qualifier, ' ')

		return qualifierText, nil, qualifierLink

	else
		-- Just text
		return rawQualifier, nil, nil
	end
end


return TeamCardStorage
