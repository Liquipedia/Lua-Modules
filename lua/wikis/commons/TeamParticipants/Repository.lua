---
-- @Liquipedia
-- page=Module:TeamParticipants/Repository
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local Json = Lua.import('Module:Json')
local Lpdb = Lua.import('Module:Lpdb')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent/Custom')

---@class TeamParticipantsEntity
---@field pagename string
---@field opponent standardOpponent
---@field qualifierText string?
---@field qualifierPage string?
---@field qualifierUrl string?

local TeamParticipantsRepository = {}

---@param TeamParticipant table
function TeamParticipantsRepository.save(TeamParticipant)
	local lpdbData = {
		objectName = '', -- TODO

		tournament = Variables.varDefault('tournament_name'),
		parent = Variables.varDefault('tournament_parent'),
		series = Variables.varDefault('tournament_series'),
		shortname = Variables.varDefault('tournament_tickername'),
		mode = Variables.varDefault('tournament_mode'),
		type = Variables.varDefault('tournament_type'),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		publishertier = Variables.varDefault('tournament_publishertier'),
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		game = Variables.varDefault('tournament_game'),
		startdate = Variables.varDefault('tournament_startdate'),

		date = TeamParticipant.finalDate or Variables.varDefault('tournament_enddate'),

		opponentname = Variables.varDefault('tournament_opponentname'),
		opponenttemplate = Variables.varDefault('tournament_opponenttemplate'),
		opponenttype = Variables.varDefault('tournament_opponenttype'),
		opponentplayers = Variables.varDefault('tournament_opponentplayers'),
		qualifier = Variables.varDefault('tournament_qualifier'),
		qualifierpage = Variables.varDefault('tournament_qualifierpage'),
		qualifierurl = Variables.varDefault('tournament_qualifierurl'),
		extradata = {},
	}

	lpdbData = Table.mergeInto(lpdbData, Opponent.toLegacyParticipantData(TeamParticipant.opponentData))
	lpdbData = Table.mergeInto(lpdbData, Opponent.toLpdbStruct(TeamParticipant.opponentData))

	-- TODO: individual prize money

	-- TODO: If a custom override for LPDB exists, use it

	-- TODO: Store aliases (page names) for opponents for setting page vars

	-- TODO: Qualifier storing
	lpdbData = Json.stringifySubTables(lpdbData)
	lpdbData.opponentplayers = lpdbData.players -- TODO: Until this is included in Opponent

	mw.ext.LiquipediaDB.lpdb_placement(lpdbData.objectName, lpdbData)
end

---@param pageName string
---@return TeamParticipantsEntity[]
function TeamParticipantsRepository.getAllByPageName(pageName)
	---@type placement[]
	local records = {}
	Lpdb.executeMassQuery(
		'placement',
		{
			conditions = tostring(
				Condition.Node(Condition.ColumnName('pagename'), Condition.Comparator.eq, Page.pageifyLink(pageName))
			),
		},
		function(record)
			table.insert(records, record)
		end
	)
	return Array.map(records, TeamParticipantsRepository.entityFromRecord)
end

---@param record placement
---@return TeamParticipantsEntity
function TeamParticipantsRepository.entityFromRecord(record)
	---@type TeamParticipantsEntity
	local entity = {
		pagename = record.pagename,
		opponent = Opponent.fromLpdbStruct(record),
		qualifierText = record.qualifier,
		qualifierPage = record.qualifierpage,
		qualifierUrl = record.qualifierurl,
	}
	return entity
end

return TeamParticipantsRepository
