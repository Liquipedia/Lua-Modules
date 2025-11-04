---
-- @Liquipedia
-- page=Module:TeamParticipants/Repository
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local Lpdb = Lua.import('Module:Lpdb')
local Page = Lua.import('Module:Page')

local Opponent = Lua.import('Module:Opponent/Custom')

---@class TeamParticipantsEntity
---@field pagename string
---@field opponent standardOpponent
---@field qualifierText string?
---@field qualifierPage string?
---@field qualifierUrl string?

local TeamParticipantsRepository = {}

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
