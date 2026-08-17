---
-- @Liquipedia
-- page=Module:Widget/EmptyPagePreview/Person
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BroadcasterTable = Lua.import('Module:BroadcastTalentTable')
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

local AmBox = Lua.import('Module:Widget/ArticleMessageBox')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlayerAutoTeamNavBox = Lua.import('Module:Widget/NavBox/AutoTeam/Player')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DEFAULT_MAX_PLAYERS_PER_PLACEMENT = Info.config.defaultMaxPlayersPerPlacement or 10

local Helpers = {}

---@param props {pageName: string}
---@return VNode?
local EmptyPersonPagePreview = function(props)
	if not Namespace.isMain() then
		return
	end

	--disable storage ... just to be sure ...
	Variables.varDefine('disable_LPDB_storage', 'true')

	local person = Page.applyUnderScoresIfEnforced(props.pageName)

	local infobox = Helpers._infobox(person, props.pageName)
	if not infobox then
		return
	end

	return Html.Div{
		children = WidgetUtil.collect(
			AmBox{
				image = 'Liquipedia logo.png',
				imageSize = '60px',
				tesxt = {
					'You are currently viewing an automatically generated preview page. ',
					'In future, a page may be created for the topic if it meets the ',
					Link{link = 'Liquipedia:Notability_Guidelines', children = 'notability requirements'},
					'.',
				}
			},
			infobox,
			Html.H2{children = {'Overview'}},
			Helpers._results(person),
			Helpers._matches(person),
			Html.Br{},
			PlayerAutoTeamNavBox{}
		),
	}
end

---@private
---@param person string
---@param pageNameInput string
---@return Renderable?
function Helpers._infobox(person, pageNameInput)
	local infoboxArgsFromSquadInfo = Helpers._backfillInformationFromSquadInfo(person)

	local infoboxArgs = Table.merge(
		{
			default = 'Infobox player NoImage.png',
			defaultDark = 'Infobox player NoImage darkmode.png',
		},
		infoboxArgsFromSquadInfo,
		Helpers._backfillInformationFromPlacements(person)
	)
	table.insert(infoboxArgs.idsArray, infoboxArgsFromSquadInfo.id)
	if Logic.isEmpty(infoboxArgs.idsArray) then
		return
	end
	infoboxArgs.idsArray = Array.unique(infoboxArgs.idsArray)
	infoboxArgs.idsArray = Array.filter(infoboxArgs.idsArray, function(id)
		return id ~= infoboxArgs.id
	end)
	infoboxArgs.ids = table.concat(infoboxArgs.idsArray, ', ')
	infoboxArgs.id = infoboxArgs.id or pageNameInput

	return Infobox.run(infoboxArgs)
end

---@private
---@param person string
---@return Renderable[]
function Helpers._matches(person)
	return {
		Html.H3{children = 'Most Recent Matches'},
		MatchTable.results{
			tableMode = 'solo',
			player = person,
			showType = true,
			limit = 10,
		}
	}
end

---@private
---@param person string
---@return (Renderable|Html)[]
function Helpers._results(person)
	---@type table<string, boolean|Renderable>
	local tabArgs = {
		suppressHeader = true,
		name1 = 'Achievements',
		content1 = ResultsTable.results{
			player = person,
			showType = true,
			gameIcons = true,
			awards = false,
			achievements = true,
			querytype = 'solo',
		}
	}
	local index = 2

	local awardsAchievements = ResultsTable.awards{
		player = person,
		showType = true,
		gameIcons = true,
		awards = true,
		achievements = true,
		querytype = 'solo',
	}
	if Logic.isNotEmpty(awardsAchievements) then
		tabArgs['name' .. index] = 'Awards Achievements'
		tabArgs['content' .. index] = awardsAchievements
		index = index + 1
	end

	local talentAchievements = BroadcasterTable.run{
		broadcaster = person,
		achievements = true,
		useTickerNames = true,
	}
	if Logic.isNotEmpty(talentAchievements) then
		tabArgs['name' .. index] = 'Talent Achievements'
		tabArgs['content' .. index] = talentAchievements
	end

	return {
		Html.H3{children = 'Achievements'},
		Tabs.dynamic(tabArgs)
	}
end

--- checks the last 100 placements for the wanted data
---@private
---@param person string
---@return table
function Helpers._backfillInformationFromPlacements(person)
	local personConditions = ConditionTree(BooleanOperator.any)
		-- players
		:add(Array.mapRange(1, DEFAULT_MAX_PLAYERS_PER_PLACEMENT, function(index)
			return ConditionNode(ColumnName('p' .. index, 'opponentplayers'), Comparator.eq, person)
		end))
		-- coaches (etc)
		:add(Array.mapRange(1, 5, function(index)
			return ConditionNode(ColumnName('c' .. index, 'opponentplayers'), Comparator.eq, person)
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
			if personData['p' .. index] == person then
				return Opponent.playerFromLpdbStruct(personData, index)
			end
			if personData['c' .. index] == person then
				return Opponent.staffFromLpdbStruct(personData, index)
			end
			index = index + 1
		end
	end

	Array.forEach(Array.reverse(placements), function(placement)
		local personData = getPerson(placement.opponentplayers)
		if not personData then
			return
		end

		local id = Logic.nilIfEmpty(personData.displayName)
		table.insert(infoboxArgs.idsArray, id)
		Table.mergeInto(infoboxArgs, {
			id = id,
			country = personData.flag,
			faction = personData.faction,
		})
	end)

	return infoboxArgs
end

---@private
---@param person string
---@return table
function Helpers._backfillInformationFromSquadInfo(person)
	local squadEntry = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = tostring(ConditionNode(ColumnName('link'), Comparator.eq, person)),
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

return Component.component(EmptyPersonPagePreview, {pageName = mw.title.getCurrentTitle().prefixedText})
