---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local PageLink = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class EvaLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Players', children = {args.player_number}},
			Cell{name = 'Teams', children = {args.team_number}}
    )
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local maps = Array.map(caller:getAllArgsForBase(args, 'map'), function(map)
				return PageLink.makeInternalLink(map)
			end)
			Array.appendWith(widgets,
				Logic.isNotEmpty(maps) and table.insert(widgets, Title{children = 'Maps'}) or nil,
				Center{children = table.concat(maps, '&nbsp;• ')}
		)
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
