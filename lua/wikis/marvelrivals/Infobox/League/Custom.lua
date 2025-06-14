---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Link = require('Module:Widget/Basic/Link')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class MarvelrivalsLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local DEFAULT_PLATFORM = 'PC'
local PLATFORM_ALIAS = {
	console = 'Console',
	pc = 'PC',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Platform', content = {caller:_createPlatformCell(args)}}
		)
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.platform = args.platform

	return lpdbData
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local platform = self:_platformLookup(args.platform)

	return {
		platform and (platform .. ' Tournaments') or nil,
	}
end

---@param platform string?
---@return string?
function CustomLeague:_platformLookup(platform)
	platform  = Logic.nilIfEmpty(platform) or DEFAULT_PLATFORM
	return PLATFORM_ALIAS[platform:lower()]
end

---@param args table
---@return string?
function CustomLeague:_createPlatformCell(args)
	local platform = self:_platformLookup(args.platform)

	if not platform then
		return nil
	end

	return Link{
		link = ':Category:' .. platform .. ' Tournaments',
		children = { platform }
	}
end

return CustomLeague
