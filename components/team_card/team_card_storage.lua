---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamCard/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Custom = require('Module:TeamCard/Custom')
local String = require('Module:StringUtils')
-- TODO: Once the Template calls are not needed (when RL has been moved to Module), deprecate Qualifier
local Qualifier = require('Module:TeamCard/Qualifier')
local Variables = require('Module:Variables')

local TeamCardStorage = {}

function TeamCardStorage.saveToLpdb(args, teamObject, players, playerPrize)
	local team, teamTemplateName
	local image, imageDark

	if type(teamObject) == 'table' then
		if teamObject.team2 or teamObject.team3 then
			team = 'TBD'
		else
			teamTemplateName = teamObject.teamtemplate
			team = teamObject.lpdb
			image = args.image1
			imageDark = args.imagedark1
		end
	end

	local smwPrefix = args.smw_prefix or args['smw prefix']
					  or Variables.varDefault('smw prefix', Variables.varDefault('smw_prefix', ''))
	local qualifierText, qualifierPage, qualifierUrl = Qualifier.parseQualifier(args.qualifier)
	local title = mw.title.getCurrentTitle().text
	local date = Variables.varDefault('tournament_date')
	local endDate = Variables.varDefault('tournament_enddate', Variables.varDefault('tournament_edate', date))
	local startDate = Variables.varDefault('tournament_startdate', Variables.varDefault('tournament_sdate', date))

	local lpdbData = {
		tournament = Variables.varDefault('tournament name pp') or Variables.varDefault('tournament_name') or title,
		series = Variables.varDefault('tournament_series'),
		parent = Variables.varDefault('tournament_parent'),
		image = image,
		imagedark = imageDark,
		startdate = startDate,
		date = args.date or Variables.varDefault('enddate_' .. team .. smwPrefix .. '_date') or endDate,
		participant = team,
		participanttemplate = teamTemplateName,
		players = players,
		individualprizemoney = playerPrize,
		mode = Variables.varDefault('tournament_mode', 'team'),
		publishertier = Variables.varDefault('tournament_publisher_tier'),
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		game = Variables.varDefault('tournament_game'),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		qualifier = qualifierText,
		qualifierpage = qualifierPage,
		qualifierurl = qualifierUrl,
		extradata = {},
	}

	-- If a custom override for LPDB exists, use it
	lpdbData = Custom.adjustLPDB and Custom.adjustLPDB(lpdbData, team, args, smwPrefix) or lpdbData

	-- Create jsons on json fields
	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata)
	lpdbData.players = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.players)

	-- Name must match prize pool insertion
	local storageName = Custom.getLPDBObjectName and Custom.getLPDBObjectName(team, smwPrefix)
						or TeamCardStorage._getLPDBObjectName(team, smwPrefix)

	mw.ext.LiquipediaDB.lpdb_placement(storageName, lpdbData)
end

-- Build the standard LPDB "Object Name", which is used as primary key in the DB record
function TeamCardStorage._getLPDBObjectName(team, smwPrefix)
	local storageName = 'ranking'
	if String.isNotEmpty(smwPrefix) then
		storageName = storageName .. '_' .. smwPrefix
	end
	storageName = storageName .. '_' ..  mw.ustring.lower(team)
	if team == 'TBD' then
		local placement = tonumber(Variables.varDefault('TBD_placements', '1'))
		storageName = storageName .. '_' .. placement
		Variables.varDefine('TBD_placements', placement + 1)
	end
	return storageName
end

return TeamCardStorage
