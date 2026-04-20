---
-- @Liquipedia
-- page=Module:TeamTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local Link = Lua.import('Module:Widget/Basic/Link')

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

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local team = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	TeamTabs._setDisplayTitle(args, team, subpageName)

	return TeamTabs._display(team, not Logic.readBool(args.hidePlayerSpecific), tonumber(args.currentTab))
end

---@private
---@param args table
---@param team string
---@param subpageName string
function TeamTabs._setDisplayTitle(args, team, subpageName)
	---@param title string
	local setDisplayTitle = function(title)
		mw.getCurrentFrame():callParserFunction('DISPLAYTITLE', title)
	end

	if Logic.isNotEmpty(args.title) then
		setDisplayTitle(args.title)
		return
	end

	if team == subpageName then
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

	setDisplayTitle(title)
end

---@private
---@param team string
---@param showPlayerSubTabs boolean
---@param currentTab integer?
---@return Widget?
function TeamTabs._display(team, showPlayerSubTabs, currentTab)
	---@param args {form: string, template: string, display: string, queryArgs: table}
	---@return Widget
	local makeQueryLink = function(args)
		return Link{
			linktype = 'external',
			children = args.display,
			link = Page.makeFormQueryLink(Table.merge(args, {execute = true}))
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
				team = team,
				tier = '1,2,3',
				edate = NOW,
				limit = '250',
			},
		},
		name3 = makeQueryLink{
			form = 'Team Matches',
			display = 'Team Matches',
			template = 'Team matches',
			queryArgs = {
				team = team,
				tier = '1,2,3',
				edate = NOW,
				linkSubPage = 'false',
				limit = '250',
			},
		},
	}

	if showPlayerSubTabs then
		tabArgs.name4 = makeQueryLink{
			form = 'Team Player Results',
			display = 'Player Results',
			template = 'Team player results',
			queryArgs = {
				team = team,
				tier = '1,2,3',
				edate = NOW,
				limit = '250',
			},
		}
	end

	tabArgs.This = currentTab

	return Tabs.static(tabArgs)
end

return TeamTabs
