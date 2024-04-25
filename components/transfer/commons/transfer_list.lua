---
-- @Liquipedia
-- wiki=commons
-- page=Module:TransferList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Team = require('Module:Team')

local TransferRow = Lua.import('Module:Transfer')

local DEFAULT_VALUES = {
	sort = 'date',
	oder = 'desc',
	limit = 20,
}

---@class TransferListConfig
---@field limit integer
---@field sortOrder string
---@field title string?
---@field shown boolean
---@field platformIcons boolean
---@field class string?
---@field showNoResultsMessage boolean
---@field iconModule string?
---@field iconFunction string?
---@field iconTransfers boolean?
---@field refType string?
---@field displayTeamName boolean
---@field conditions TransferListConditionConfig

---@class TransferListConditionConfig
---@field nationality string[]?
---@field players string[]?
---@field roles1 string[]?
---@field roles2 string[]?
---@field teams string[]?
---@field startDate string?
---@field endDate string?
---@field tournament string?
---@field fromTeam string?
---@field toTeam string?
---@field position string?
---@field platform string?
---@field onlyNotableTransfers boolean

---@class TransferList: BaseClass
---@field config TransferListConfig
local TransferList = Class.new(
	---@param frame Frame
	---@return self
	function(self, frame)
		local args = Arguments.getArgs(frame)
		self.config = self:parseArgs(args)
	end
)

---@param frame Frame
---@return Html
function TransferList.run(frame)
	return TransferList(frame):query():create()
end

---@param args table
---@return TransferListConfig
function TransferList:parseArgs(args)
	local players = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.players)) or {args.player} --[[@as string[] ]]
	local roles = Array.parseCommaSeparatedString(args.role)


	local teams = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.teams)) --[[@as string[]?]]
	if not teams then
		teams = Array.extractValues(Table.filterByKey(args, function(key)
			return key:find('^team%d*$') ~= nil
		end))
	end

	local teamList = {}
	Array.forEach(teams, function(team)
		if not mw.ext.TeamTemplate.teamexists(team) then
			mw.log('Missing team teamplate: ' .. team)
		end
		Array.extendWith(teamList, Team.queryHistoricalNames(team) or {team})
	end)

	return {
		limit = tonumber(args.limit) or DEFAULT_VALUES.limit,
		sortOrder = (args.sort or DEFAULT_VALUES.sort) .. ' ' .. (args.order or DEFAULT_VALUES.order) .. ', objectname asc',
		title = Logic.nilIfEmpty(args.title),
		shown = Logic.readBool(args.shown),
		platformIcons = Logic.readBool(args.platformIcons),
		class = Logic.nilIfEmpty(args.class),
		showNoResultsMessage = Logic.readBool(args.form),
		iconModule = Logic.nilIfEmpty(args.iconModule),
		iconFunction = Logic.nilIfEmpty(args.iconFunction),
		iconTransfers = Logic.readBoolOrNil(args.iconTransfers),
		refType = args.refType,
		displayTeamName = Logic.nilOr(Logic.readBoolOrNil(args.displayTeamName), Logic.readBoolOrNil(args.showteamname)),
		conditions = {
			nationality = Logic.nilIfEmpty(Array.parseCommaSeparatedString(args.nationality)),
			players = Logic.nilIfEmpty(Array.map(players, mw.ext.TeamLiquidIntegration.resolve_redirect)),
			startDate = Logic.emptyOr(args.sdate, args.date),
			endDate = Logic.emptyOr(args.edate, args.date),
			tournament = Logic.nilIfEmpty((args.page or ''):gsub(' ', '_')),
			fromTeam = Logic.nilIfEmpty(args.fromteam),
			toTeam = Logic.nilIfEmpty(args.toteam),
			roles1 = Logic.nilIfEmpty(Array.append(roles, Array.parseCommaSeparatedString(args.role1))),
			roles2 = Logic.nilIfEmpty(Array.append(roles, Array.parseCommaSeparatedString(args.role2))),
			position = Logic.nilIfEmpty(args.position),
			platform = Logic.nilIfEmpty(args.platform),
			onlyNotableTransfers = Logic.readBool(args.onlyNotableTransfers),
			teams = Logic.nilIfEmpty(teamList),
		}
	}
end




return TransferList