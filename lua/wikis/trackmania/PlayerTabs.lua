---
-- @Liquipedia
-- page=Module:PlayerTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local SUBPAGES = {
	'Results',
	'Played Matches',
	'Coaching',
	'Talent',
}

local PlayerTabs = {}

---@return Renderable?
function PlayerTabs.run()
	local pageName = mw.title.getCurrentTitle().prefixedText

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local player = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	Page.setDisplayTitle{
		title = PlayerTabs._getDisplayTitle(player, subpageName),
	}

	return PlayerTabs._display(player)
end

---@private
---@param player string
---@param subpageName string
---@return string?
function PlayerTabs._getDisplayTitle(player, subpageName)
	if player == subpageName then
		return
	end

	local data = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. player:gsub(' ', '_') .. ']]',
		query = 'id',
	})
	local title = (data[1] or {}).id or player

	if Table.includes(SUBPAGES, subpageName) then
		title = title .. ': ' .. subpageName
	end

	return title
end

---@private
---@param player string
---@return Renderable?
function PlayerTabs._display(player)
	local tabArgs = {
		name1 = 'Overview',
		link1 = player
	}

	local tabCounter = 1
	Array.forEach(SUBPAGES, function(item)
		if Page.exists(player .. '/' .. item) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = item
			tabArgs['link' .. tabCounter] = player .. '/' .. item
		end
	end)

	return Tabs.static(tabArgs)
end

return PlayerTabs
