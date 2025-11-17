---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local PageLink = Lua.import('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class HeroesLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

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
	local args = self.caller.args

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Teams', children = {(args.team_number)}})
	elseif id == 'gamesettings' then
		local server = args.server
		if server then
			return {Cell{name = 'Server', children = {
				Flags.Icon{flag = server} .. '&nbsp;' .. Flags.CountryName{flag = server}
			}}}
		end
	elseif id == 'customcontent' then
		local maps = Array.map(self.caller:getAllArgsForBase(args, 'bg'), function(map)
			return tostring(self.caller:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
		end)

		if #maps > 0 then
			table.insert(widgets, Title{children = 'Battlegrounds'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	end

	return widgets
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
