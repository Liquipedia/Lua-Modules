---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Game = Lua.import('Module:Game')
local Info = Lua.import('Module:Info', {loadData = true})
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
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
---@return VNode
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.player_number = league.args.participants_number

	return league:createInfobox()
end

---Creates the cell for one of the parsed list arguments, e.g. `Mode` or `Styles`
---@param name string
---@param values string[]
---@return Renderable?
function CustomLeague:_createListCell(name, values)
	if Logic.isEmpty(values) then
		return nil
	end

	return Cell{name = name .. (#values > 1 and 's' or ''), children = values}
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		local games = self.caller:getAllArgsForBase(args, 'game')
		table.insert(widgets, Cell{
			name = 'Game' .. (#games > 1 and 's' or ''),
			children = Array.map(games,
					function(game)
						local gameInfo = Game.raw{game = game}
						if not gameInfo then
							return 'Unknown game, check Module:Info.'
						end
						return Page.makeInternalLink(gameInfo.name, gameInfo.link)
					end)
		})

		local data = self.caller.data
		Array.appendWith(widgets,
			self.caller:_createListCell('Mode', data.modes),
			self.caller:_createListCell('Style', data.styles)
		)
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
	self.data.modes = Array.map(self:getAllArgsForBase(self.args, 'mode'),
		function(input) return Info.modes[string.lower(input)] end)
	self.data.mode = self.data.modes[1] or self.data.mode

	self.data.styles = Array.map(self:getAllArgsForBase(self.args, 'style'),
		function(input) return Info.styles[string.lower(input)] end)

	self.data.publishertier = self.data.publishertier or Array.any(self:getAllArgsForBase(args, 'organizer'),
		function(organizer)
			return organizer:find('Nadeo', 1, true) or organizer:find('Ubisoft', 1, true)
		end)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = Array.map(self:getAllArgsForBase(args, 'game'), function(game)
		local gameInfo = Game.raw{game = game}

		return gameInfo and (gameInfo.link .. ' Competitions') or nil
	end)

	return Array.append(categories,
		self.data.publishertier and 'Ubisoft Tournaments' or nil,
		Logic.isEmpty(self.data.modes) and 'Tournaments without mode' or nil,
		Logic.isEmpty(self.data.styles) and 'Tournaments without style' or nil
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.circuit = args.circuit
	lpdbData.extradata.circuittier = args.circuittier

	if Logic.isNotEmpty(self.data.modes) then
		lpdbData.extradata.modes = self.data.modes
	end

	if Logic.isNotEmpty(self.data.styles) then
		lpdbData.extradata.styles = self.data.styles
	end

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
