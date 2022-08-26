---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Storage/StarcraftLegacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local StandingsStorage = Lua.import('Module:Standings/Storage', {requireDevIfEnabled = true})

local LEAGUE_TYPE = 'league'
local TYPE_FROM_NUMBER = {
	Opponent.solo,
	Opponent.duo,
	Opponent.trio,
	Opponent.quad,
}
local INVALID_OPPONENT_CATEGORY = '[[Category:Pages with invalid opponent '
	.. 'parsing in legacy group tables]]'

local Wrapper = {}

function Wrapper.table(frame)
	local args = Arguments.getArgs(frame)
	-- option to disable storage in case of transclusions etc
	if not Logic.readBool(Logic.emptyOr(args.store, true)) then
		return
	end

	return StandingsStorage.fromTemplateHeader(frame)
end

function Wrapper.entry(frame)
	local args = Arguments.getArgs(frame)
	if not Logic.readBool(Logic.emptyOr(args.store, true)) then
		return
	end

	local opponent = Wrapper._processOpponent(args)
	if not opponent then
		mw.log('Unable to parse opponent for group slot with the following arguments:')
		mw.logObject(args, 'args')
		return INVALID_OPPONENT_CATEGORY
	end

	local storageArgs = {
		opponentLibrary = 'Opponent/Starcraft',
		opponent = opponent,
		title = Variables.varDefault('standings_title'),
		tournament = Variables.varDefault('tournament_name', mw.title.getCurrentTitle().text),
		type = args.type or LEAGUE_TYPE,
		placement = args.place,
		definitestatus = args.bg,
		currentstatus = args.pbg or args.bg,
		diff = args.diff,
		win_m = args.win_m,
		tie_m = args.tie_m,
		lose_m = args.lose_m,
		win_g = args.win_g,
		tie_g = args.tie_g,
		lose_g = args.lose_g,
		points = args.points,
		roundindex = 1,
		standingsindex = Variables.varDefault('standingsindex'),
	}

	return StandingsStorage.fromTemplateEntry(storageArgs)
end

function Wrapper._processOpponent(args)
	local opponentInput = args[1] or ''
	-- case team opponent
	if opponentInput:match('class="team%-template') then
		local teamPage = opponentInput:match('%[%[([^|]-)|[^|]-%]%]')
		return {type = Opponent.team, template = teamPage:lower()}
	end

	local opponentArgs = {}
	-- split the opponentInput into the sep. playerInputs
	local playerInputs = mw.text.split(opponentInput, '<span class="starcraft%-inline%-player')
	-- since the split can add empty strings we need to remove them again
	playerInputs = Wrapper._removeEmpty(playerInputs)

	local opponentType = TYPE_FROM_NUMBER[#playerInputs]
	if not opponentType then
		return
	end
	opponentArgs.type = opponentType

	for playerIndex, playerInput in ipairs(playerInputs) do
		Wrapper._processPlayer(playerInput, opponentArgs, 'p' .. playerIndex)
	end

	-- archon handling gets ignored here
	-- due to the input patern for them being inconsistent it is unfeasible to regex them
	-- hence they will be manually converted to use the automated GroupTableLeague

	return opponentArgs
end

function Wrapper._removeEmpty(tbl)
	local newTable = {}
	for _, item in ipairs(tbl) do
		if String.isNotEmpty(item) then
			table.insert(newTable, item)
		end
	end

	return newTable
end

function Wrapper._processPlayer(playerInput, opponentArgs, prefix)
	-- parse the single player and add them to the opponentArgs
	local link, name = playerInput:match('%[%[([^|]-)|([^|]-)%]%]')
	if String.isEmpty(link) or String.isEmpty(name) then
		-- invalid input
		return
	end
	opponentArgs[prefix] = name
	opponentArgs[prefix .. 'link'] = link
	opponentArgs[prefix .. 'flag'] = playerInput:match('<span class="flag">%[%[File:[^|]-%.png|([^|]-)|')

	-- get the race
	-- first remove the flag so that only 1 image is left
	playerInput = playerInput:gsub('<span class="flag">.-</span>', '')
	-- now read the race from the remaining file
	opponentArgs[prefix .. 'race'] = playerInput:match('&nbsp;%[%[File:[^]]-|([^|]-)%]%]')
end

return Wrapper
