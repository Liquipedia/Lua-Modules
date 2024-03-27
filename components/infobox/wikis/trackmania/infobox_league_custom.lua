---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Game = require('Module:Game')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local Chronology = Widgets.Chronology

local DEFAULT_MODE = 'solo'

---@class TrackmaniaLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.player_number = league.args.participants_number

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'sponsors' then
		local partners = self.caller:getAllArgsForBase(args, 'partner')
		table.insert(widgets, Cell{
			name = 'Partner' .. (#partners > 1 and 's' or ''),
			content = Array.map(partners, Page.makeInternalLink)
		})
	elseif id == 'gamesettings' then
		local games = self.caller:getAllArgsForBase(args, 'game')
		table.insert(widgets, Cell{
			name = 'Game' .. (#games > 1 and 's' or ''),
			content = Array.map(games,
					function(game)
						local info = Game.raw{game = game}
						if not info then
							return 'Unknown game, check Module:Info.'
						end
						return Page.makeInternalLink(info.name, info.link)
					end)
		})
	elseif id == 'customcontent' then
		table.insert(widgets, Title{name = String.isNotEmpty(args.team_number) and 'Teams' or 'Players'})
		table.insert(widgets, Cell{
			name = 'Number of Teams',
			content = {args.team_number}
		})
		table.insert(widgets, Cell{
			name = 'Number of Players',
			content = {args.player_number}
		})

		local maps = self.caller:getAllArgsForBase(args, 'map')
		if #maps > 0 then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end

		if args.circuit or args.points or args.circuit_next or args.circuit_previous then
			table.insert(widgets, Title{name = 'Circuit Information'})
			self.caller:_createCircuitInformation(widgets)
		end
	end

	return widgets
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Array.any(self:getAllArgsForBase(args, 'organizer'),
		function(organizer)
			return organizer:find('Nadeo', 1, true) or organizer:find('Ubisoft', 1, true)
		end)
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = Logic.emptyOr(
		args.mode,
		(String.isNotEmpty(args.team_number) and 'team' or nil),
		DEFAULT_MODE
	)
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- legacy variables, to be removed
	Variables.varDefine('tournament_tier', self.data.liquipediatier)
	Variables.varDefine('tournament_tier_type', self.data.liquipediatiertype)

	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)

	Variables.varDefine('circuit', self.data.circuit)
	Variables.varDefine('circuittier', self.data.circuittier)
	Variables.varDefine('circuitabbr', self.data.circuitabbr)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = Array.map(self:getAllArgsForBase(args, 'game'), function(game)
		local info = Game.raw{game = game}

		return info and (info.link .. ' Competitions') or nil
	end)

	return Array.append(categories, self:liquipediaTierHighlighted(args) and 'Ubisoft Tournaments' or nil)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	if String.isEmpty(args.tickername) then
		lpdbData.tickername = args.name
	end

	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.circuit = args.circuit
	lpdbData.extradata.circuittier = args.circuittier

	-- Legacy, can be superseeded by lpdbData.mode
	lpdbData.extradata.individual = self.data.mode == DEFAULT_MODE

	return lpdbData
end

---@param widgets Widget[]
---@param circuitIndex string|number?
function CustomLeague:_createCircuitInformation(widgets, circuitIndex)
	local args = self.args
	circuitIndex = circuitIndex or ''
	local circuitArgs = {
		tier = args['circuit' .. circuitIndex .. 'tier'],
		region = args['region' .. circuitIndex],
		points = args['points' .. circuitIndex],
		next = args['circuit' .. circuitIndex .. '_next'],
		previous = args['circuit' .. circuitIndex .. '_previous'],
	}

	Array.appendWith(widgets,
		Cell{
			name = 'Circuit',
			content = {self:_createCircuitLink(circuitIndex)}
		},
		Cell{name = 'Circuit Tier', content = {circuitArgs.tier}},
		Cell{name = 'Tournament Region', content = {circuitArgs.region}},
		Cell{name = 'Points', content = {circuitArgs.points}},
		Chronology{content = {next = circuitArgs.next, previous = circuitArgs.previous}}
	)
end

---@param circuitIndex string|number
---@return string?
function CustomLeague:_createCircuitLink(circuitIndex)
	local args = self.args

	return self:createSeriesDisplay({
		displayManualIcons = true,
		series = args['circuit' .. circuitIndex],
		abbreviation = args['circuit' .. circuitIndex .. 'abbr'],
	}, self.data['circuitIconDisplay' .. circuitIndex])
end

return CustomLeague
