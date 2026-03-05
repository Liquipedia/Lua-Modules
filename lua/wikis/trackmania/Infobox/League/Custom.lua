---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Game = Lua.import('Module:Game')
local Class = Lua.import('Module:Class')
local Page = Lua.import('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local Chronology = Widgets.Chronology

---@class TrackmaniaLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
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

	if id == 'gamesettings' then
		local games = self.caller:getAllArgsForBase(args, 'game')
		table.insert(widgets, Cell{
			name = 'Game' .. (#games > 1 and 's' or ''),
			children = Array.map(games,
					function(game)
						local info = Game.raw{game = game}
						if not info then
							return 'Unknown game, check Module:Info.'
						end
						return Page.makeInternalLink(info.name, info.link)
					end)
		})
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Number of Players', children = {args.player_number}},
			Cell{name = 'Number of Teams', children = {args.team_number}}
		)
	elseif id == 'customcontent' then
		local maps = self.caller:getAllArgsForBase(args, 'map')
		if #maps > 0 then
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end

		if args.circuit or args.circuit_next or args.circuit_previous then
			table.insert(widgets, Title{children = 'Circuit Information'})
			self.caller:_createCircuitInformation(widgets)
		end
	end

	return widgets
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = self.data.publishertier or Array.any(self:getAllArgsForBase(args, 'organizer'),
		function(organizer)
			return organizer:find('Nadeo', 1, true) or organizer:find('Ubisoft', 1, true)
		end)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = Array.map(self:getAllArgsForBase(args, 'game'), function(game)
		local info = Game.raw{game = game}

		return info and (info.link .. ' Competitions') or nil
	end)

	return Array.append(categories, self.data.publishertier and 'Ubisoft Tournaments' or nil)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.circuit = args.circuit
	lpdbData.extradata.circuittier = args.circuittier

	return lpdbData
end

---@param widgets Widget[]
function CustomLeague:_createCircuitInformation(widgets)
	local args = self.args

	Array.appendWith(widgets,
		Cell{
			name = 'Circuit',
			children = {self:_createCircuitLink()}
		},
		Cell{name = 'Circuit Tier', children = {args.circuittier}},
		Cell{name = 'Tournament Region', children = {args.region}},
		Chronology{args = {next = args.circuit_next, previous = args.circuit_previous}, showTitle = false}
	)
end

---@return string?
function CustomLeague:_createCircuitLink()
	local args = self.args

	return self:createSeriesDisplay({
		displayManualIcons = true,
		series = args.circuit,
	})
end

return CustomLeague
