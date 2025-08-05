---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class HaloLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.liquipediatiertype = league.args.liquipediatiertype or league.args.tiertype

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
		return {
			Cell{name = 'Game version', content = {Game.name{game = args.game}}},
		}
	elseif id == 'customcontent' and String.isNotEmpty(args.map1) then
		Array.appendWith(widgets,
			Title{children = 'Maps'},
			Center{children = self.caller:_makeMapList()}
		)
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	local maps = {}
	local index = 1
	while not String.isEmpty(args['map' .. index]) do
		local modes = {}
		if not String.isEmpty(args['map' .. index .. 'modes']) then
			local tempModesList = mw.text.split(args['map' .. index .. 'modes'], ',')
			for _, item in ipairs(tempModesList) do
				local currentMode = MapModes.clean({mode = item or ''})
				if not String.isEmpty(currentMode) then
					table.insert(modes, currentMode)
				end
			end
		end
		table.insert(maps, {
			map = args['map' .. index],
			modes = modes
		})
		index = index + 1
	end

	lpdbData.maps = table.concat(Array.map(
		self:getAllArgsForBase(args, 'map'),
		mw.ext.TeamLiquidIntegration.resolve_redirect
	), ';')

	lpdbData.extradata.maps = Json.stringify(maps)
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
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('tournament_tiertype', args.liquipediatiertype)
end

---@return string[]
function CustomLeague:_makeMapList()
	local date = self.data.endDate or self.data.startDate or os.date('%Y-%m-%d') --[[@as string]]
	local map1 = PageLink.makeInternalLink({}, self.args['map1'])
	local map1Modes = self:_getMapModes(self.args['map1modes'], date)

	local foundMaps = {
		tostring(self:_createNoWrappingSpan(map1Modes .. map1))
	}
	local index = 2
	while not String.isEmpty(self.args['map' .. index]) do
		local currentMap = PageLink.makeInternalLink({}, self.args['map' .. index])
		local currentModes = self:_getMapModes(self.args['map' .. index .. 'modes'], date)

		table.insert(
			foundMaps,
			'&nbsp;• ' .. tostring(self:_createNoWrappingSpan(currentModes .. currentMap))
		)
		index = index + 1
	end
	return foundMaps
end

---@param modesString string?
---@param date string?
---@return string
function CustomLeague:_getMapModes(modesString, date)
	if String.isEmpty(modesString) then
		return ''
	end
	---@cast modesString -nil

	local display = ''
	local tempModesList = mw.text.split(modesString, ',')
	for _, item in ipairs(tempModesList) do
		local mode = MapModes.clean(item)
		if not String.isEmpty(mode) then
			if display ~= '' then
				display = display .. '&nbsp;'
			end
			display = display .. MapModes.get({mode = mode, date = date, size = 15})
		end
	end
	return display .. '&nbsp;'
end

---@param base string
---@return string[]
function CustomLeague:_makeBasedListFromArgs(base)
	local firstArg = self.args[base .. '1']
	local foundArgs = {PageLink.makeInternalLink({}, firstArg)}
	local index = 2

	while not String.isEmpty(self.args[base .. index]) do
		local currentArg = self.args[base .. index]
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(self:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, currentArg)
			))
		)
		index = index + 1
	end

	return foundArgs
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
