---
-- @Liquipedia
-- page=Module:TeamTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Link = Lua.import('Module:Widget/Basic/Link')

local SPECIAL_SUBPAGES = {
	'Transfers',
	'Team Record',
	'History',
	'Teamkills',
	'League Rosters',
	'Clan Wars',
}
local NOW = DateExt.toYmdInUtc(DateExt.getCurrentTimestamp() + DateExt.daysToSeconds(1))

local TeamTabs = {}

---@param frame Frame
---@return Widget?
function TeamTabs.run(frame)
	local args = Arguments.getArgs(frame)

	local pageName = args.team or args.pageName or mw.title.getCurrentTitle().prefixedText
	-- first remove any year range sub sub page stuff
	pageName = string.gsub(pageName, '/[%d%-]+$', '')
	pageName = string.gsub(pageName, '/%d+%-Present$', '')

	local subTeams = Array.mapIndexes(function(subTeamIndex)
		return args['sub' .. subTeamIndex] or args['subTeam' .. subTeamIndex]
	end)

	local mainTeam, currentSubTeam = TeamTabs._getTeam(pageName, subTeams)
	local subpageName = pageName:gsub(mainTeam, '')
	if currentSubTeam then
		subpageName = subpageName:gsub('^/currentSubTeam', '')
	end
	subpageName = subpageName:gsub('.*/([^/]+)$', '%1')

	TeamTabs._setDisplayTitle(args, currentSubTeam or mainTeam, Logic.nilIfEmpty(subpageName))

	return TeamTabs._display(
		mainTeam,
		subTeams,
		not Logic.readBool(args.hidePlayerSpecific),
		currentSubTeam,
		tonumber(args.currentTab)
	)
end

---@param pageName string
---@param subTeams string[]
---@return string, string?
function TeamTabs._getTeam(pageName, subTeams)
	local mainTeam = pageName:gsub('(.*)/[^/]-$', '%1')

	local subpageName = pageName:gsub(mainTeam, ''):gsub('.*/([^/]+)$', '%1')

	if Table.includes(subTeams, subpageName) then
		return mainTeam, mainTeam .. '/' .. subpageName
	end

	return mainTeam
end

---@private
---@param args table
---@param team string
---@param subpageName string?
function TeamTabs._setDisplayTitle(args, team, subpageName)
	if Logic.isNotEmpty(args.title) then
		Page.setDisplayTitle(args.title)
		return
	end

	---@return string
	local queryDisplayName = function()
		local data = mw.ext.LiquipediaDB.lpdb('team', {
			conditions = '[[pagename::' .. team:gsub(' ', '_') .. ']]',
			query = 'name',
		})
		return (data[1] or {}).name or team
	end

	local title = (args.displayName or queryDisplayName()) .. (subpageName and (': ' .. subpageName) or '')

	Page.setDisplayTitle(title)
end

---@private
---@param mainTeam string
---@param subTeams string[]
---@param showPlayerSubTabs boolean
---@param currentSubTeam string?
---@param currentSubTab integer?
---@param displayName string?
---@return Widget?
function TeamTabs._display(mainTeam, subTeams, showPlayerSubTabs, currentSubTeam, currentSubTab, displayName)
	if Logic.isEmpty(subTeams) then
		return TeamTabs._getTabsForSubTeam(mainTeam, showPlayerSubTabs, currentSubTab)
	end

	mw.ext.TeamLiquidIntegration.add_category('Teams with subTeam pages')

	---@type table<string, Renderable>
	local tabArgs = {}
	local currentTab

	---@param subTeam string?
	---@param subTeamIndex integer
	local buildArgsForTeam = function(subTeam, subTeamIndex)
		local tabIndex = subTeamIndex + 1
		local link = mainTeam .. (subTeam and ('/' .. subTeam) or '')

		local teamTemplateDisplay = TeamTemplate.exists(link) and OpponentDisplay.InlineTeamContainer{template = link} or nil
		if not teamTemplateDisplay then
			tabArgs['link' .. tabIndex] = link
		end

		tabArgs['name' .. tabIndex] = teamTemplateDisplay or displayName or (mainTeam .. ': ' .. subTeam)

		if link == currentSubTeam or (not currentSubTeam and link == mainTeam) then
			currentTab = tabIndex
			tabArgs['tabs' .. tabIndex] = TeamTabs._getTabsForSubTeam(link, showPlayerSubTabs, currentSubTab)
		end
	end

	buildArgsForTeam(nil, 0)
	Array.forEach(subTeams, buildArgsForTeam)
	tabArgs.This = currentTab

	return Tabs.static(tabArgs)
end

---@private
---@param team string
---@param showPlayerSubTabs boolean
---@param currentTab integer?
---@return Widget?
function TeamTabs._getTabsForSubTeam(team, showPlayerSubTabs, currentTab)
	---@param args {form: string, template: string, display: string, queryArgs: table}
	---@return string
	local makeQueryLink = function(args)
		local prefix = args.template
		local queryArgs = Table.map(args.queryArgs, function(key, item)
			return prefix .. key, item
		end)
		return Link{
			linktype = 'external',
			children = args.display,
			link = tostring(mw.uri.fullUrl(
				'Special:RunQuery/' .. args.form,
				mw.uri.buildQueryString(queryArgs) .. '&_run'
			))
		}
	end

	local tabArgs = {
		name1 = 'Overview',
		link1 = team,
		name2 = makeQueryLink{
			form = 'Team Results',
			display = 'Team Results',
			template = 'Team results',
			queryArgs = {
				['[team]'] = team,
				['[tier]'] = '1,2,3',
				['[edate]'] = NOW,
				['[limit]'] = '250',
			},
		},
		name3 = makeQueryLink{
			form = 'Team Matches',
			display = 'Team Matches',
			template = 'Team matches',
			queryArgs = {
				['[team]'] = team,
				['[tier]'] = '1,2,3',
				['[edate]'] = NOW,
				['[linkSubPage]'] = 'false',
				['[limit]'] = '250',
			},
		},
	}

	local tabCounter = 3
	if showPlayerSubTabs then
		tabArgs.name4 = makeQueryLink{
			form = 'Team Player Results',
			display = 'Player Results',
			template = 'Team player results',
			queryArgs = {
				['[team]'] = team,
				['[tier]'] = '1,2,3',
				['[edate]'] = NOW,
				['[limit]'] = '250',
			},
		}

		tabArgs.name5 = 'Player Matches'
		tabArgs.link5 = team .. '/Player Matches'

		tabCounter = 5
	end

	-- add special sub pages that some might have
	-- only add them if the according sub page actually exists
	Array.forEach(SPECIAL_SUBPAGES, function(item)
		if not Page.exists(team .. '/' .. item) then return end
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = item
		tabArgs['link' .. tabCounter] = team .. '/' .. item
	end)

	tabArgs.This = currentTab

	return Tabs.static(tabArgs)
end

return TeamTabs
