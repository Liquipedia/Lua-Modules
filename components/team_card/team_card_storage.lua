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
	local team, teamTemplate
	local image, imageDark

	if type(teamObject) == 'table' then
		if teamObject.team2 or teamObject.team3 then
			team = 'TBD'
		else
			teamTemplate = teamObject.teamtemplate
			team = teamObject.lpdb
			image = args.image1
			imageDark = args.imagedark1
		end
	end

	local smwPrefix = args.smw_prefix or args['smw prefix']
					  or Variables.varDefault('smw prefix', Variables.varDefault('smw_prefix', ''))
	local qualifierText, qualifierPage, qualifierUrl = Qualifier.parseQualifier(args.qualifier)
	local title = mw.title.getCurrentTitle().text
	local endDate = Variables.varDefault('tournament_edate', Variables.varDefault('tournament_date'))

	local lpdbData = {
		tournament = Variables.varDefault('tournament name pp', Variables.varDefault('tournament_name', title)),
		series = Variables.varDefault('tournament_series'),
		parent = Variables.varDefault('tournament_parent'),
		image = image,
		imagedark = imageDark,
		startdate = Variables.varDefault('tournament_sdate', Variables.varDefault('tournament_date')),
		date = args.date or Variables.varDefault('enddate_' .. team .. smwPrefix .. '_date', endDate),
		participant = team,
		participanttemplate = teamTemplate,
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
	local storageName = Custom.getLPDBStorageName and Custom.getLPDBStorageName(team, smwPrefix)
						or TeamCardStorage._getDefaultStorageName(team, smwPrefix)

	mw.ext.LiquipediaDB.lpdb_placement(storageName, lpdbData)

	if team == 'TBD' then
		-- Increase the wiki-variable TBD_placements by 1
		Variables.varDefine('TBD_placements', tonumber(Variables.varDefault('TBD_placements', '1')) + 1)
	end
end

-- Default storage (object) name format
function TeamCardStorage.getDefaultStorageName(team, smwPrefix)
	local storageName = 'ranking'
	if String.isNotEmpty(smwPrefix) then
		storageName = storageName .. '_' .. smwPrefix
	end
	storageName = storageName .. '_' ..  mw.ustring.lower(team)
	if team == 'TBD' then
		storageName = storageName .. '_' .. Variables.varDefault('TBD_placements', '1')
	end
	return storageName
end

return TeamCardStorage
