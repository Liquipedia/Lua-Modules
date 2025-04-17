---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateClean = require('Module:DateTime')
local GameLookup = require('Module:GameLookup')
local GameModeLookup = require('Module:GameModeLookup')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapMode = require('Module:MapMode')
local MatchTicker = require('Module:Matches Tournament')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class AgeofempiresLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local SECONDS_PER_DAY = 86400

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.liquipediatier = Tier.toNumber(league.args.liquipediatier)

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = Logic.emptyOr(
		args.mode,
		String.isNotEmpty(args.team_number) and 'team' or '1v1'
	)

	self.data.maps = self:_getMaps()
	self.data.gameModes = self:_getGameModes(args)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'gamesettings' then
		Array.appendWith(widgets,
			Cell{name = 'Game & Version', content = caller:_getGameVersion(args)},
			Cell{name = 'Game Mode', content = Array.map(caller.data.gameModes, function(gameMode)
				return Page.makeInternalLink(gameMode)
			end)}
		)
	elseif id == 'customcontent' then
		local playertitle = (not String.isEmpty(args.team_number)) and 'Teams' or 'Players'

		Array.appendWith(widgets,
			Title{children = playertitle},
			Cell{name = 'Number of Teams', content = {args.team_number}},
			Cell{name = 'Number of Players', content = {args.player_number}}
		)

		if not String.isEmpty(args.team1) then
			local teams = {Page.makeInternalLink(args.team1)}
			local index = 2

			while not String.isEmpty(args['team' .. index]) do
				table.insert(teams, '&nbsp;• ' ..
					tostring(caller:_createNoWrappingSpan(
						Page.makeInternalLink(args['team' .. index])
					))
				)
				index = index + 1
			end

			table.insert(widgets, Center{children = teams})
		end

		if not String.isEmpty(args.map1) then
			Array.appendWith(widgets,
				Title{children = 'Maps'},
				Center{children = caller:_displayMaps(caller.data.maps)}
			)
		end
	elseif id == 'sponsors' then
		if not String.isEmpty(args.sponsors) then
			local sponsors = mw.text.split(args.sponsors, ',', true)
			table.insert(widgets, Cell{
				name = 'Sponsor(s)',
				content = {table.concat(sponsors, '&nbsp;• ')}
			})
		end
	end

	return widgets
end

---@return string?
function CustomLeague:createBottomContent()
	local yesterday = os.date('%Y-%m-%d', os.time() - SECONDS_PER_DAY)

	if self.data.endDate and yesterday <= self.data.endDate then
		return MatchTicker.get{args={
			parent = self.pagename,
			limit = tonumber(self.args.matchtickerlimit) or 7,
			noInfoboxWrapper = true
		}}
	end
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return Array.append({},
		String.isEmpty(args.game) and 'Tournaments without game version'
			or (GameLookup.getName({args.game}) .. (args.beta and ' Beta' or '') .. ' Competitions')
	)
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', self:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', args.sponsors)


	local dateclean = ReferenceCleaner.clean{input = args.date}
	local edateclean = ReferenceCleaner.clean{input = args.edate}
	local sdateclean = ReferenceCleaner.clean{input = args.sdate}
	local date = (not String.isEmpty(args.date)) and dateclean
					or edateclean
	local startdate = (not String.isEmpty(args.sdate)) and sdateclean
					or dateclean
	local enddate = (not String.isEmpty(args.edate)) and edateclean
					or dateclean
	Variables.varDefine('tournament_date', date)
	Variables.varDefine('tournament_sdate', startdate)
	Variables.varDefine('tournament_edate', enddate)
	Variables.varDefine('date', date)
	Variables.varDefine('sdate', startdate)
	Variables.varDefine('edate', enddate)

	Variables.varDefine('game', GameLookup.getName({args.game}))
	Variables.varDefine('tournament_game', GameLookup.getName({args.game}))
	-- Currently, args.patch shall be used for official patches,
	-- whereas voobly is used to denote non-official version played via voobly
	Variables.varDefine('tournament_patch', args.patch or args.voobly)
	Variables.varDefine('patch', args.patch or args.voobly)
	Variables.varDefine('tournament_gameversion', args.version)
	Variables.varDefine('tournament_headtohead', args.headtohead)

	-- Legacy notability vars
	Variables.varDefine('tournament_notability_mod', args.notabilitymod or 1)

	-- Variables for extradata to be added again in
	-- Module:Prize pool, Module:Prize pool team, Module:TeamCard and Module:TeamCard2
	Variables.varDefine('tournament_deadline', DateClean._clean(args.deadline or ''))
	Variables.varDefine('tournament_gamemode', table.concat(self.data.gameModes, ','))

	-- map links, to be used by brackets and mappool templates
	Variables.varDefine('tournament_maps', Json.stringify(self.data.maps))
	Array.forEach(self.data.maps, function(map)
		Variables.varDefine('tournament_map_'.. (map.name or map.link), map.link)
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = Logic.emptyOr(lpdbData.tickername, args.name)

	-- Prevent resolving redirects for series
	-- lpdbData.seriespage will still contain the resolved page
	lpdbData.series = args.series

	lpdbData.sponsors = args.sponsors

	lpdbData.maps = self.data.maps

	lpdbData.game = GameLookup.getName({args.game})
	-- Currently, args.patch shall be used for official patches,
	-- whereas voobly is used to denote non-official version played via voobly
	lpdbData.patch = args.patch or args.voobly

	lpdbData.extradata.region = args.region
	lpdbData.extradata.deadline = DateClean._clean(args.deadline or '')
	lpdbData.extradata.gamemode = table.concat(self.data.gameModes, ',')
	lpdbData.extradata.gameversion = args.version

	return lpdbData
end

---@param args table
---@param base string
---@return string
function CustomLeague:_concatArgs(args, base)
	local foundArgs = {args[base] or args[base .. '1']}
	local index = 2
	while not String.isEmpty(args[base .. index]) do
		table.insert(foundArgs, args[base .. index])
		index = index + 1
	end

	return table.concat(foundArgs, ';')
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

---@param args table
---@return string[]
function CustomLeague:_getGameVersion(args)
	local gameversion = {}

	if not String.isEmpty(args.game) then
		local gameName = GameLookup.getName({args.game})
		if String.isEmpty(gameName) then
			error('Unknown or unsupported game: ' .. args.game)
		end
		table.insert(gameversion,
			Page.makeInternalLink(gameName) .. (args.beta and ' Beta' or '')
		)

		if not String.isEmpty(args.version) then
			table.insert(gameversion,
				GameLookup.makeVersionLink({game = args.game, version = args.version}) or args.version
			)
		end

		if not String.isEmpty(args.patch) then
			table.insert(gameversion, self:_makePatchLink(args))
		end

		if not String.isEmpty(args.voobly) then
			table.insert(gameversion, args.voobly)
		end
	end

	return gameversion
end

---@param args table
---@return string
function CustomLeague:_makePatchLink(args)
	local content = GameLookup.makePatchLink({game = args.game, version = args.version, patch = args.patch})

	if not String.isEmpty(args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		local version = not String.isEmpty(args.eversion) and args.eversion or args.version

		content = content .. GameLookup.makePatchLink({game = args.game, version = version, patch = args.epatch})
	end
	return content
end

---@param args table
---@return string[]
function CustomLeague:_getGameModes(args)
	if String.isEmpty(args.gamemode) then
		local default = GameModeLookup.getDefault(args.game or '')
		self:categories(default .. ' Tournaments')
		return {default}
	end

	local gameModes = mw.text.split(args.gamemode, ',', true)
	Array.forEach(gameModes,
		function(mode, index)
			gameModes[index] = GameModeLookup.getName(mode) or ''

			self:categories(not String.isEmpty(gameModes[index])
				and gameModes[index] .. ' Tournaments'
				or 'Pages with unknown game mode'
			)
		end
	)

	return gameModes
end

---@return {link: string, name: string?, mode: string?, image: string?}[]
function CustomLeague:_getMaps()
	local args = self.args

	local maps = {}
	for prefix, mapInput in Table.iter.pairsByPrefix(args, 'map', {strict = true}) do
		local mode = String.isNotEmpty(args[prefix .. 'mode']) and MapMode.get({args[prefix .. 'mode']}) or nil

		mapInput = mw.text.split(mapInput, '|', true)
		local display, link

		if String.isNotEmpty(args[prefix .. 'link']) then
			link = args[prefix .. 'link']
			display = mapInput[1]
		else
			link = mapInput[1]
			display = mapInput[2] or mapInput[1]
		end
		link = mw.ext.TeamLiquidIntegration.resolve_redirect(link)
		if link == display then
			display = nil
		end

		self:_checkMapInformation(display or link, link, self.data.game)

		table.insert(maps, {link = link, name = display, mode = mode, image = args[prefix .. 'image']})
	end

	return maps
end

---@param name string?
---@param link string
---@param game string?
function CustomLeague:_checkMapInformation(name, link, game)
	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::map]] AND [[pagename::' .. link:gsub(' ', '_') .. ']]',
		query = 'name, extradata'
	})
	if Table.isNotEmpty(data[1]) then
		local extradata = data[1].extradata or {}
		if extradata.game ~= game then
			mw.logObject('Map ' .. name .. ' is linking to ' .. link .. ', an ' .. extradata.game .. ' page.')
			self:categories('Tournaments linking to maps for a different game')
		end
	end
end

---@param maps {link: string, name: string?, mode: string?, image: string?}[]
---@return table
function CustomLeague:_displayMaps(maps)
	local mapDisplay = function(map)
		return tostring(self:_createNoWrappingSpan(
			Page.makeInternalLink({}, (map.name or map.link) .. (map.mode or ''), map.link)
		))
	end

	return {table.concat(
		Table.mapValues(maps, function(map) return mapDisplay(map) end),
		'&nbsp;• '
	)}
end

---@param args table
---@return string?
function CustomLeague:createLiquipediaTierDisplay(args)
	local tierDisplay = Tier.display(
		args.liquipediatier,
		args.liquipediatiertype,
		{link = true, game = GameLookup.getName{args.game}}
	)

	if String.isEmpty(tierDisplay) then
		return
	end

	return tierDisplay .. self:appendLiquipediatierDisplay(args)
end

return CustomLeague
