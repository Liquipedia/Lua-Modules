---
-- @Liquipedia
-- page=Module:ShowRoster
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Page = Lua.import('Module:Page')
local RoleUtil = Lua.import('Module:Role/Util')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ConditionUtil = Condition.Util

local ParticipantsTeamCardsGroup = Lua.import('Module:Widget/Participants/Team/CardsGroup')

local ShowRoster = {}

---@param frame Frame
---@return Renderable?
function ShowRoster.run(frame)
	local args = Arguments.getArgs(frame)

	---@type string[]
	local tournaments = {}
	for _, pageNamesInput in Table.iter.pairsByPrefix(args, 'tournament', {requireIndex = false}) do
		table.insert(tournaments, Page.pageifyLink(pageNamesInput))
	end

	if Table.isEmpty(tournaments) then
		return
	end

	local name = TeamTemplate.getPageName(args.team)
	-- annos expect a string return, so let it error if we get a nil return
	assert(name, 'Invalid team template: ' .. (args.team or ''))

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode('opponenttype', Comparator.eq, Opponent.team),
		ConditionNode('opponentname', Comparator.eq, Page.applyUnderScoresIfEnforced(name)),
		ConditionUtil.anyOf('parent', tournaments),
	}

	local queryResult = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		offset = 0,
		conditions = tostring(conditions),
		query = 'date, placement, opponenttemplate, opponenttype, opponentplayers, parent',
	})

	local rosterData = Array.map(queryResult, function (record, recordIndex)
		local opponentData = Opponent.fromLpdbStruct(record)
		Array.extendWith(
			opponentData.players,
			Array.mapIndexes(function (index)
				return Logic.nilIfEmpty(Opponent.staffFromLpdbStruct(record.opponentplayers, index))
			end)
		)
		Array.forEach(opponentData.players, function (player)
			player.extradata = player.extradata or {}
			local hasStaffRoles = false
			if player.roles then
				player.extradata.roles = Array.map(player.roles, RoleUtil.getRoleForKey)
				if Array.any(player.extradata.roles, function(role) return role.type == RoleUtil.ROLE_TYPE.STAFF end) then
					hasStaffRoles = true
				end
			end
			if player.extradata.type == 'staff' then
				hasStaffRoles = true
			end
			player.extradata.type = hasStaffRoles and 'staff' or 'player'
			player.extradata.played = true
		end)
		return {
			opponent = opponentData,
			notes = {},
			aliases = {},
			qualification = {
				type = 'tournament',
				tournament = Tournament.getTournament(record.parent),
				placement = record.placement,
			},
			date = DateExt.readTimestamp(record.date),
		}
	end)

	Array.sortInPlaceBy(rosterData, function (roster)
		return Array.indexOf(tournaments, function (tournament)
			return tournament == roster.qualification.tournament.pageName
		end)
	end)

	return ParticipantsTeamCardsGroup{
		participants = rosterData,
		showPlayerInfo = false,
		showControls = true,
	}
end

return ShowRoster
