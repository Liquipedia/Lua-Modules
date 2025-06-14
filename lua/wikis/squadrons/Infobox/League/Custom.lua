---
-- @Liquipedia
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

---@class SquadronsLeagueInfobox: InfoboxLeague
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
		Array.appendWith(widgets,
			Cell{name = 'Teams', content = {args.team_number}},
			Cell{name = 'Players', content = {args.player_number}}
		)
	elseif id == 'customcontent' and String.isNotEmpty(args.map1) then
		local maps = {}

		for _, map in ipairs(self.caller:getAllArgsForBase(args, 'map')) do
			table.insert(maps, tostring(self.caller:_createNoWrappingSpan(
				PageLink.makeInternalLink(map)
			)))
		end

		Array.appendWith(widgets,
			Title{children = 'Maps'},
			Center{children = {table.concat(maps, '&nbsp;• ')}}
		)
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
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
