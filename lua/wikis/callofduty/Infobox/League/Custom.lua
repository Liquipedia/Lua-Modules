---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
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

---@class CallofdutyLeagueInfobox: InfoboxLeague
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
		return {
			Cell{name = 'Number of teams', content = {args.team_number}},
			Cell{name = 'Number of players', content = {args.player_number}},
		}
	elseif id == 'gamesettings' then
		return {Cell{name = 'Game', content = {Game.name{game = args.game}}}}
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local maps = Array.map(self.caller:getAllArgsForBase(args, 'map'), function(map)
				return tostring(self.caller:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
			end)
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.individual = not String.isEmpty(args.player_number)

	return lpdbData
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = args.player_number and 'solo' or self.data.mode
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy Vars:
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_edate', self.data.endDate)
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
