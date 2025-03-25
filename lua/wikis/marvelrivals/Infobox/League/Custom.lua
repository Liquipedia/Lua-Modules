---
-- @Liquipedia
-- wiki=marvelrivals
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

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

---@param platform string?
---@return string?
function CustomLeague:_platformLookup(platform)
	if String.isEmpty(platform) then
		platform = DEFAULT_PLATFORM
	end
	---@cast platform -nil

	return PLATFORM_ALIAS[platform:lower()]
end

---@param args table
---@return string?
function CustomLeague:_createPlatformCell(args)
	local platform = self:_platformLookup(args.platform)

	if String.isNotEmpty(platform) then
		return PageLink.makeInternalLink({}, platform, ':Category:' .. platform .. ' Tournaments')
	else
		return nil
	end
end

return CustomLeague
