---
-- @Liquipedia
-- page=Module:Widget/EmptyPagePreview/Person
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BroadcasterTable = Lua.import('Module:BroadcastTalentTable')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Infobox = Lua.import('Module:Infobox/Person/Player/Custom')
local Logic = Lua.import('Module:Logic')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent/Custom')
local Page = Lua.import('Module:Page')
local ResultsTable = Lua.import('Module:ResultsTable/Custom')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')
local Variables = Lua.import('Module:Variables')

local PlayerAutoTeamNavBox = Lua.import('Module:Widget/NavBox/AutoTeam/Player')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DEFAULT_MAX_PLAYERS_PER_PLACEMENT = Info.config.defaultMaxPlayersPerPlacement or 10

---@class EmptyPersonPagePreview: Widget
---@operator call(table): EmptyPersonPagePreview
local EmptyPersonPagePreview = Class.new(Widget)
EmptyPersonPagePreview.defaultProps = {pageName = mw.title.getCurrentTitle().prefixedText}

---@return Widget?
function EmptyPersonPagePreview:render()
	if not Namespace.isMain() then
		return
	end

	--disable storage ... just to be sure ...
	Variables.varDefine('disable_LPDB_storage', 'true')

	self.person = Page.applyUnderScoresIfEnforced(self.props.pageName)

	return HtmlWidgets.Div{
		children = WidgetUtil.collect(
			self:_infobox(),
			HtmlWidgets.H2{children = {'Overview'}},
			self:_results(),
			self:_matches(),
			HtmlWidgets.Br{},
			PlayerAutoTeamNavBox{}
		),
	}
end

---@private
---@return Widget
function EmptyPersonPagePreview:_infobox()
	local infoboxArgsFromSquadInfo = self:_backfillInformationFromSquadInfo()

	local infoboxArgs = Table.merge(
		{
			default = 'Infobox player NoImage.png',
			defaultDark = 'Infobox player NoImage darkmode.png',
		},
		infoboxArgsFromSquadInfo,
		self:_backfillInformationFromPlacements()
	)
	table.insert(infoboxArgs.idsArray, infoboxArgsFromSquadInfo.id)
	infoboxArgs.idsArray = Array.unique(infoboxArgs.idsArray)
	infoboxArgs.idsArray = Array.filter(infoboxArgs.idsArray, function(id)
		return id ~= infoboxArgs.id
	end)
	infoboxArgs.ids = table.concat(infoboxArgs.idsArray, ', ')
	infoboxArgs.id = infoboxArgs.id or self.props.pageName

	return Infobox.run(infoboxArgs)
end

---@private
---@return (Widget|Html)[]
function EmptyPersonPagePreview:_matches()
	return {
		HtmlWidgets.H3{children = 'Most Recent Matches'},
		MatchTable.results{
			tableMode = 'solo',
			player = self.person,
			showType = true,
			limit = 10,
		}
	}
end

---@private
---@return (Widget|Html)[]
function EmptyPersonPagePreview:_results()
	---@type table<string, string|boolean>
	local tabArgs = {
		suppressHeader = true,
		name1 = 'Achievements',
		content1 = tostring(ResultsTable.results{
			player = self.person,
			showType = true,
			gameIcons = true,
			awards = false,
			achievements = true,
			querytype = 'solo',
		})
	}
	local index = 2

	local awardsAchievements = ResultsTable.awards{
		player = self.person,
		showType = true,
		gameIcons = true,
		awards = true,
		achievements = true,
		querytype = 'solo',
	}
	if Logic.isNotEmpty(awardsAchievements) then
		tabArgs['name' .. index] = 'Awards Achievements'
		tabArgs['content' .. index] = tostring(awardsAchievements)
		index = index + 1
	end

	local talentAchievements = BroadcasterTable.run{
		broadcaster = self.person,
		achievements = true,
		useTickerNames = true,
	}
	if Logic.isNotEmpty(talentAchievements) then
		tabArgs['name' .. index] = 'Talent Achievements'
		tabArgs['content' .. index] = tostring(talentAchievements)
	end

	return {
		HtmlWidgets.H3{children = 'Achievements'},
		Tabs.dynamic(tabArgs)
	}
end

--- checks the last 100 placements for the wanted data
---@private
---@return table
function EmptyPersonPagePreview:_backfillInformationFromPlacements()
	local personConditions = ConditionTree(BooleanOperator.any)
		-- players
		:add(Array.map(Array.range(1, DEFAULT_MAX_PLAYERS_PER_PLACEMENT), function(index)
			return ConditionNode(ColumnName('p' .. index, 'opponentplayers'), Comparator.eq, self.person)
		end))
		-- coaches (etc)
		:add(Array.map(Array.range(1, 5), function(index)
			return ConditionNode(ColumnName('c' .. index, 'opponentplayers'), Comparator.eq, self.person)
		end))

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, ''),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, '[]'),
		ConditionNode(ColumnName('liquipediatier'), Comparator.neq, -1),
		personConditions
	}

	local placements = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		query = 'opponenttype, opponentname, opponenttemplate, opponentplayers',
		order = 'date desc',
		limit = 100,
	})

	local infoboxArgs = {idsArray = {}}

	if #placements == 0 then
		return infoboxArgs
	end

	---@param personData table<string, string>
	---@return standardPlayer?
	local getPerson = function(personData)
		local index = 1
		while personData['p' .. index] or personData['c' .. index] do
			if personData['p' .. index] == self.person then
				return Opponent.playerFromLpdbStruct(personData, index)
			end
			if personData['c' .. index] == self.person then
				return Opponent.staffFromLpdbStruct(personData, index)
			end
			index = index + 1
		end
	end

	Array.forEach(Array.reverse(placements), function(placement)
		local person = getPerson(placement.opponentplayers)
		if not person then
			return
		end

		local id = Logic.nilIfEmpty(person.displayName)
		table.insert(infoboxArgs.idsArray, id)
		Table.mergeInto(infoboxArgs, {
			id = id,
			country = person.flag,
			faction = person.faction,
		})
	end)

	return infoboxArgs
end

---@private
---@return table
function EmptyPersonPagePreview:_backfillInformationFromSquadInfo()
	local squadEntry = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = tostring(ConditionNode(ColumnName('link'), Comparator.eq, self.person)),
		query = 'name, id, nationality, leavedate, inactivedate, pagename, extradata',
		order = 'joindate desc',
		limit = 1,
	})[1]

	if not squadEntry then
		return {}
	end

	local infoboxArgs = {
		id = Logic.nilIfEmpty(squadEntry.id),
		country = Logic.nilIfEmpty(squadEntry.nationality),
		faction = Logic.nilIfEmpty((squadEntry.extradata or {}).faction),
		name = Logic.nilIfEmpty(squadEntry.name),
	}

	if DateExt.isDefaultTimestamp(squadEntry.leavedate) and DateExt.isDefaultTimestamp(squadEntry.inactivedate) then
		infoboxArgs.team = squadEntry.pagename
	end

	return infoboxArgs
end

return EmptyPersonPagePreview
