---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class RocketleagueLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)
local NotabilityCalculator = {}

local SERIES_RLCS = 'Rocket League Championship Series'
local MODE_2v2 = '2v2'

local TIER_1 = 1
local MISC_TIER = -1
local H2H_TIER_THRESHOLD = 5

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
			Cell{name = 'Mode', content = {args.mode}},
			Cell{name = 'Game', content = {Game.text{game = args.game}}},
			Cell{name = 'Misc Mode', content = {args.miscmode}}
		)
	elseif id == 'customcontent' then
		if not String.isEmpty(args.map1) then
			local maps = {self.caller:_makeInternalLink(args.map1)}
			local index = 2

			while not String.isEmpty(args['map' .. index]) do
				table.insert(maps, '&nbsp;• ' ..
					tostring(self.caller:_createNoWrappingSpan(
						self.caller:_makeInternalLink(args['map' .. index])
					))
				)
				index = index + 1
			end
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = maps})
		end

		if not String.isEmpty(args.team_number) then
			table.insert(widgets, Title{children = 'Teams'})
			table.insert(widgets, Cell{
				name = 'Number of teams',
				content = {args.team_number}
			})
		elseif not String.isEmpty(args.player_number) then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{
				name = 'Number of players',
				content = {args.player_number}
			})
		end
	end
	return widgets
end

---@param args table
---@return string?
function CustomLeague:createLiquipediaTierDisplay(args)
	local tierDisplay = Tier.display(
		args.liquipediatier,
		args.liquipediatiertype,
		{link = true, tierType2 = args.liquipediatiertype2}
	)

	if String.isEmpty(tierDisplay) then
		return
	end

	return tierDisplay .. self:appendLiquipediatierDisplay(args)
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.rlcsPremier = args.series == SERIES_RLCS and 1 or 0
	self.data.publishertier = args.series == SERIES_RLCS and tonumber(self.data.liquipediatier) == TIER_1
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', self:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', self:_concatArgs(args, 'sponsor'))
	Variables.varDefine('tournament_rlcs_premier', self.data.rlcsPremier)
	Variables.varDefine('date', ReferenceCleaner.clean{input = args.date})
	Variables.varDefine('sdate', ReferenceCleaner.clean{input = args.sdate})
	Variables.varDefine('edate', ReferenceCleaner.clean{input = args.edate})

	-- Legacy tier vars
	Variables.varDefine('tournament_lptier', args.liquipediatier)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('tournament_tiertype', args.liquipediatiertype)
	Variables.varDefine('tournament_tiertype2', args.liquipediatiertype2)
	Variables.varDefine('ltier', args.liquipediatier == 1 and 1 or
		args.liquipediatier == 2 and 2 or
		args.liquipediatier == 3 and 3 or 4
	)

	-- Legacy notability vars
	Variables.varDefine('tournament_notability_mod', args.notabilitymod or 1)

	-- Rocket League specific
	Variables.varDefine('tournament_participant_number', 0)
	Variables.varDefine('tournament_participants', '(')
	Variables.varDefine('tournament_teamplayers', args.mode == MODE_2v2 and 2 or 3)
	Variables.varDefine('showh2h', CustomLeague.parseShowHeadToHead(args))
end

---@param args table
---@return string?
function CustomLeague.parseShowHeadToHead(args)
	return Logic.emptyOr(
		args.showh2h,
		tostring(
			(tonumber(args.liquipediatier) or H2H_TIER_THRESHOLD) < H2H_TIER_THRESHOLD
			and args.liquipediatier ~= MISC_TIER
		)
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.patch = args.patch

	lpdbData.extradata.region = args.region
	lpdbData.extradata.mode = args.mode
	lpdbData.extradata.notabilitymod = args.notabilitymod
	lpdbData.extradata.liquipediatiertype2 = args.liquipediatiertype2
	lpdbData.extradata.notabilitypercentage = args.edate ~= 'tba' and NotabilityCalculator.run() or ''

	return lpdbData
end

---@param args table
---@return table
function CustomLeague:getWikiCategories(args)
	local gameName = Game.name{game = args.game}
	if not gameName then
		return {'Competitions'}
	end
	return {gameName .. ' Competitions'}
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
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

---@param content string
---@return string
function CustomLeague:_makeInternalLink(content)
	return '[[' .. content .. ']]'
end

---@return number
function NotabilityCalculator.run()
	local pagename = mw.title.getCurrentTitle().text:gsub(' ', '_')
	local placements = NotabilityCalculator._getPlacements(pagename)
	local allTeams = NotabilityCalculator._getAllTeams()

	local teamsWithAPage = 0

	-- We need this because sometimes we get a placement like "tbd"
	local numberOfPlacements = 0

	for _, placement in ipairs(placements) do
		if placement.participant:lower() ~= '' and placement.participant:lower() ~= 'tbd' then
			local doesTeamExist = NotabilityCalculator._findTeam(allTeams, placement.participant)
			numberOfPlacements = numberOfPlacements + 1

			if doesTeamExist == true then
				teamsWithAPage = teamsWithAPage + 1
			end
		end
	end

	if numberOfPlacements == 0 then
		return 0
	end

	return Math.round((teamsWithAPage / numberOfPlacements) * 100, 2)
end

---@param allTeams table
---@param teamToFind string
---@return boolean
function NotabilityCalculator._findTeam(allTeams, teamToFind)
	local firstLetter = string.sub(teamToFind, 1, 1):lower()

	if not allTeams[firstLetter] then
		return false
	end

	for _, team in ipairs(allTeams[firstLetter]) do
		if team:lower() == teamToFind:lower() then
			return true
		end
	end

	return false
end

---@return table
function NotabilityCalculator._getAllTeams()
	local teams = mw.ext.LiquipediaDB.lpdb('team', {
		query = 'name',
		limit = 5000,
	})

	-- Make a table of letters, with each letter mapping to an
	-- array of names, to aid in faster lookup
	local indexedTeams = {}

	for _, team in pairs(teams) do
		local firstLetter = string.sub(team.name, 1, 1):lower()

		if indexedTeams[firstLetter] == nil then
			indexedTeams[firstLetter] = {}
		end

		table.insert(indexedTeams[firstLetter], team.name)
	end

	return indexedTeams
end

---@param pagename string
---@return {participant: string, participantflag: string, mode: string}[]
function NotabilityCalculator._getPlacements(pagename)
	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. pagename .. ']] AND [[mode::3v3]]',
		query = 'participant, participantflag, mode'
	})
end


return CustomLeague
