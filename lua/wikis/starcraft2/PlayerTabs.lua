---
-- @Liquipedia
-- page=Module:PlayerTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local Link = Lua.import('Module:Widget/Basic/Link')

local SPECIAL_SUBPAGES = {
	'Broadcasts',
	'Schedule',
	'Rivalries',
}
local NOW = DateExt.toYmdInUtc(DateExt.getCurrentTimestamp() + DateExt.daysToSeconds(1))
local PAST = DateExt.toYmdInUtc(DateExt.getCurrentTimestamp() - DateExt.daysToSeconds(180))

local PlayerTabs = {}

---@param frame Frame
---@return Widget?
function PlayerTabs.run(frame)
	local args = Arguments.getArgs(frame)

	local pageName = args.player or args.pageName or mw.title.getCurrentTitle().prefixedText
	-- first remove any year range sub sub page stuff
	pageName = string.gsub(pageName, '/[%d%-]+$', '')
	pageName = string.gsub(pageName, '/%d+%-Present$', '')

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local player = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	Page.setDisplayTitle{title = PlayerTabs._getDisplayTitle(args, player, subpageName)}

	return PlayerTabs._display(player, tonumber(args.currentTab))
end

---@private
---@param args table
---@param player string
---@param subpageName string
---@return string?
function PlayerTabs._getDisplayTitle(args, player, subpageName)
	if Logic.isNotEmpty(args.title) then
		return args.title
	end

	if player == subpageName then
		return
	end

	---@return string
	local queryDisplayName = function()
		local data = mw.ext.LiquipediaDB.lpdb('player', {
			conditions = '[[pagename::' .. player:gsub(' ', '_') .. ']]',
			query = 'id',
		})
		return (data[1] or {}).id or player
	end

	local title = args.displayName or queryDisplayName()

	if Table.includes(SPECIAL_SUBPAGES, subpageName) then
		title = title .. ': ' .. subpageName
	end

	return title
end

---@private
---@param player string
---@param currentTab integer?
---@return Widget?
function PlayerTabs._display(player, currentTab)
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
		link1 = player,
		name2 = makeQueryLink{
			form = 'Player Results',
			display = 'Results',
			template = 'Player results',
			queryArgs = {
				player = player,
				tier = '1,2,3',
				edate = NOW,
				limit = '250',
			},
		},
		name3 = makeQueryLink{
			form = 'Player Matches',
			display = 'Matches',
			template = 'Player matches',
			queryArgs = {
				player = player,
				tier = '1,2,3',
				edate = NOW,
				linkSubPage = 'false',
				limit = '250',
			},
		},
		name4 = 'Awards',
		link4 = player .. '/' .. 'Awards',
	}

	local tabCounter = 4

	-- add special sub pages that some might have
	-- only add them if the according sub page actually exists
	Array.forEach(SPECIAL_SUBPAGES, function(item)
		if not Page.exists(player .. '/' .. item) then return end
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = item
		tabArgs['link' .. tabCounter] = player .. '/' .. item
	end)

	-- Head to head query link
	tabCounter = tabCounter + 1
	tabArgs['name' .. tabCounter] = makeQueryLink{
		form = 'Match history',
		display = 'Head to Head',
		template = 'Head_to_head_query',
		queryArgs = {player = player},
	}

	-- Statistics query link
	tabCounter = tabCounter + 1
	tabArgs['name' .. tabCounter] = makeQueryLink{
		form = 'PlayerStats',
		display = 'Statistics',
		template = 'PlayerStatistics',
		queryArgs = {
			player = player,
			tiers = '1,2,3',
			tierTypes = 'Unset,Monthly,Weekly,Biweekly,Showmatch,Daily',
			onlySolo = 'no',
			sdate = PAST,
			edate = NOW,
		},
	}

	tabArgs.This = currentTab

	return Tabs.static(tabArgs)
end

return PlayerTabs
