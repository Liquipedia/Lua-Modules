---
-- @Liquipedia
-- page=Module:TournamentPlayerInfo
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Info = Lua.import('Module:Info', {loadData = true})
local Links = Lua.import('Module:Links')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local RoleUtil = Lua.import('Module:RoleUtil')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')
local CTC = Lua.import('Module:Copy to clipboard')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class EnrichedStandardPlayer: standardPlayer
---@field name string?
---@field image string?
---@field birthDate string?
---@field currentTeam string?
---@field links table?
---@field role string?

---@class TournamentPlayerInfo
---@operator call(table): TournamentPlayerInfo
---@field config {opponenttype: OpponentType?}
---@field tournament StandardTournament
local TournamentPlayerInfo = Class.new(function(self, ...) self:init(...) end)

---@param args {page: string?, mode: string?, opponenttype: OpponentType?}
function TournamentPlayerInfo.create(args)
	local tournamentPlayerInfo = TournamentPlayerInfo(args)

	if not tournamentPlayerInfo:isValidTournament() then
		return 'No conditions set.'
	end
end

---@param args table
---@return self
function TournamentPlayerInfo:init(args)
	self.config = {
		opponenttype = Logic.emptyOr(args.opponenttype, Opponent.team)
	}

	self.tournament = Tournament.getTournament(args.pagename) or {}

	return self
end

---@return boolean
function TournamentPlayerInfo:isValidTournament()
	return Logic.isNotEmpty(self.tournament)
end

---@return standardPlayer[]
function TournamentPlayerInfo:query()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('pagename'), Comparator.eq, self.tournament.pageName),
		ConditionNode(ColumnName('opponenttype'), Comparator.eq, self.config.opponenttype),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, ''),
		ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
	}

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		limit = 5000,
		order = 'opponentname asc',
	})

	return self:parseRecords(data)
end

---@protected
---@param records placement[]
---@return standardPlayer[]
function TournamentPlayerInfo:parseRecords(records)
	local players = Array.flatMap(records, function (record)
		local opponent = Opponent.fromLpdbStruct(record)

		return Array.map(opponent.players, function (player)
			if opponent.type == Opponent.team then
				player.team = opponent.template
			end

			return self:queryPlayerInfo(player)
		end)
	end)

	return Array.sortBy(players, Operator.property('team'))
end

---@protected
---@param player standardPlayer
---@return EnrichedStandardPlayer
function TournamentPlayerInfo:queryPlayerInfo(player)
	local playerData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(player.pageName))),
		query = 'name, image, birthdate, team, links, extradata',
		limit = 1
	})[1]
	if playerData then
		local extradata = playerData.extradata or {}
		return Table.merge(player, {
			name = extradata.firstname and table.concat({extradata.firstname, extradata.lastname}, ' ') or playerData.name,
			image = playerData.image,
			birthDate = playerData.birthdate,
			currentTeam = playerData.currentTeam,
			links = playerData.links,
			currentRole = extradata.role,
		})
	end
	local squadPlayerData = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = tostring(ConditionNode(ColumnName('link'), Comparator.eq, Page.pageifyLink(player.pageName))),
		limit = 1,
		query = 'name',
		order = 'joindate desc'
	})[1]
	---@cast player EnrichedStandardPlayer
	if squadPlayerData then
		player.name = squadPlayerData.name
	end
	return player
end

return Class.export(TournamentPlayerInfo, {exports = {'create'}})
