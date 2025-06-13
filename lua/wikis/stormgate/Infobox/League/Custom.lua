---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local PatchAuto = Lua.import('Module:Infobox/Extension/PatchAuto')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class StormgateLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local CANCELLED = 'cancelled'
local FINISHED = 'finished'

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	args.raceBreakDown = RaceBreakdown.run(args) or {}
	args.player_number = args.raceBreakDown.total
	args.maps = self:_getMaps(args)
	self.data.status = self:_getStatus(args)
	self.data = PatchAuto.run(self.data, args)
end

---@param args table
---@return string?
function CustomLeague:_getStatus(args)
	local status = args.status or Variables.varDefault('tournament_status')
	if Logic.isNotEmpty(status) then
		---@cast status -nil
		return status:lower()
	end

	if Logic.readBool(args.cancelled) then
		return CANCELLED
	end

	if self:_isFinished(args) then
		return FINISHED
	end
end

---@param args table
---@return boolean
function CustomLeague:_isFinished(args)
	local finished = Logic.readBoolOrNil(args.finished)
	if finished ~= nil then
		return finished
	end

	local queryDate = self.data.endDate or self.data.startDate

	if not queryDate or os.date('%Y-%m-%d') < queryDate then
		return false
	end

	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
			.. 'AND [[opponentname::!TBD]] AND [[placement::1]]',
		query = 'date',
		order = 'date asc',
		limit = 1
	})[1] ~= nil
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		table.insert(widgets, Cell{name = 'Game Version', content = {self.caller:_getGameVersion()}})
	elseif id == 'customcontent' then
		if args.player_number and args.player_number > 0 then
			Array.appendWith(widgets,
				Title{children = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {args.raceBreakDown.total}},
				Breakdown{children = args.raceBreakDown.display, classes = { 'infobox-center' }}
			)
		end

		--teams section
		if Logic.isNumeric(args.team_number) and tonumber(args.team_number) > 0 then
			Array.appendWith(widgets,
				Title{children = 'Teams'},
				Cell{name = 'Number of Teams', content = {args.team_number}}
			)
		end

		--maps
		if String.isNotEmpty(args.map1) then
			Array.appendWith(widgets,
				Title{children = 'Maps'},
				Center{children = {self.caller:_mapsDisplay(args.maps)}}
			)
		end
	end

	return widgets
end

---@param maps {link: string, displayname: string}[]
---@return string
function CustomLeague:_mapsDisplay(maps)
	return table.concat(
		Array.map(maps, function(mapData)
			return tostring(self:_createNoWrappingSpan(
				Page.makeInternalLink({}, mapData.displayname, mapData.link)
			))
		end),
		'&nbsp;• '
	)
end

---@return string?
function CustomLeague:_getGameVersion()
	return table.concat({
		Page.makeInternalLink({}, self.data.patchDisplay, self.data.patch),
		Page.makeInternalLink({}, self.data.endPatchDisplay, self.data.endPatch)
	}, ' &ndash; ')
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)

	--wiki specific vars
	Variables.varDefine('tournament_maps', Json.stringify(args.maps))
end

---@param args table
---@return {link: string, displayname: string}[]
function CustomLeague:_getMaps(args)
	local mapArgs = self:getAllArgsForBase(args, 'map')

	return Table.map(mapArgs, function(mapIndex, map)
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(map),
			displayname = args['map' .. mapIndex .. 'display'] or map,
		}
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.maps = Json.stringify(args.maps)

	return lpdbData
end

---@param content string|Html|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague
