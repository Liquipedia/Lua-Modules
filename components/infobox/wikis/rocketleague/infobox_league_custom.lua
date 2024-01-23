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
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local TournamentNotability = require('Module:TournamentNotability')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class RocketleagueLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local SERIES_RLCS = 'Rocket League Championship Series'
local MODE_2v2 = '2v2'

local TIER_1 = 1
local MISC_TIER = -1
local H2H_TIER_THRESHOLD = 5

local PSYONIX = 'Psyonix'

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
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = maps})
		end

		if not String.isEmpty(args.team_number) then
			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Cell{
				name = 'Number of teams',
				content = {args.team_number}
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
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	if (
		String.isNotEmpty(args.liquipediatiertype) or
		tonumber(args.liquipediatier) ~= TIER_1
	) then
		return false
	end

	return self:containsPsyonix('organizer') or
		self:containsPsyonix('sponsor')
end

---@param prefix string
---@return boolean
function CustomLeague:containsPsyonix(prefix)
	return Table.any(
		League:getAllArgsForBase(self.args, prefix),
		function (_, value) return value == PSYONIX end
	)
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.rlcsPremier = args.series == SERIES_RLCS and 1 or 0
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', self:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', self:_concatArgs(args, 'sponsor'))
	Variables.varDefine('tournament_rlcs_premier', self.data.rlcsPremier)
	Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
	Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))

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
	lpdbData.extradata.notabilitypercentage = args.edate ~= 'tba' and TournamentNotability.run() or ''
	lpdbData.extradata['is rlcs'] = self.data.rlcsPremier

	return lpdbData
end

---@param args table
---@return table
function CustomLeague:getWikiCategories(args)
	return {Game.name{game = args.game} .. ' Competitions'}
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

return CustomLeague
