---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local PageLink = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class DeltaforceLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local NONE_BREAKING_SPACE = '&nbsp;'
local DASH = '&ndash;'

local MODES = {
	warfare = 'Warfare[[Category:Warfare Mode Tournaments]]',
	operations = 'Operations[[Category:Operations Mode Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}
MODES.wf = MODES.warfare
MODES.op= MODES.operations

local PLATFORMS = {
	pc = 'PC[[Category:PC Competitions]]',
	mobile = 'Mobile[[Category:Mobile Competitions]]',
	console = 'Console[[Category:Console Competitions]]',
	crossplay = 'Cross-platform[[Category:Cross-platform Competitions]]',
	default = '[[Category:Unknown Platform Competitions]]',
}

---@param frame Frame
---@return Widget
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		return {
			Cell{name = 'Game mode', children = {self.caller:_getGameMode(args)}},
			Cell{name = 'Patch', children = {CustomLeague._getPatchVersion(args)}},
			Cell{name = 'Platform', children = {self.caller:_getPlatform(args)}},
		}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', children = {args.player_number}})
		end

		--teams section
		if args.team_number then
			table.insert(widgets, Title{children = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', children = {args.team_number}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

---@param args table
---@return string?
function CustomLeague:_getGameMode(args)
	if String.isEmpty(args.mode) then
		return nil
	end

	local mode = MODES[string.lower(args.mode or '')] or MODES['default']

	return mode
end

---@param args table
---@return string?
function CustomLeague:_getPlatform(args)
	if String.isEmpty(args.platform) then
		return nil
	end

	return PLATFORMS[string.lower(args.platform)] or PLATFORMS.default
end

---@param args table
---@return string?
function CustomLeague._getPatchVersion(args)
	if String.isEmpty(args.patch) then return nil end
	local content = PageLink.makeInternalLink(args.patch, 'Patch ' .. args.patch)
	if String.isNotEmpty(args.epatch) then
		return content .. NONE_BREAKING_SPACE .. DASH .. NONE_BREAKING_SPACE
			.. PageLink.makeInternalLink(args.epatch, 'Patch ' .. args.epatch)
	end

	return content
end

return CustomLeague
