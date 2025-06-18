---
-- @Liquipedia
-- page=Module:Standings/Storage/StarcraftLegacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local LEAGUE_TYPE = 'league'
local TYPE_FROM_NUMBER = Table.map(Opponent.partySizes, function(key, code) return code, key end)
local INVALID_OPPONENT_CATEGORY = '[[Category:Pages with invalid opponent '
	.. 'parsing in legacy group tables]]'

local Wrapper = {}

---@param frame Frame
function Wrapper.table(frame)
	local args = Arguments.getArgs(frame)
	if not Wrapper._shouldStore(args) then
		return
	end

	args.roundcount = 1
	StandingsStorage.fromTemplateHeader(args)
end

---@param frame Frame
---@return string?
function Wrapper.entry(frame)
	local args = Arguments.getArgs(frame)
	if not Wrapper._shouldStore(args) then
		return
	end

	local opponent = Wrapper._processOpponent(args)
	if not opponent then
		mw.log('Unable to parse opponent for group slot with the following arguments:')
		mw.logObject(args, 'args')
		return INVALID_OPPONENT_CATEGORY
	end

	local storageArgs = {
		opponent = opponent,
		title = Variables.varDefault('standings_title'),
		tournament = Variables.varDefault('tournament_name', mw.title.getCurrentTitle().text),
		type = args.type or LEAGUE_TYPE,
		placement = args.place,
		placerange = {tonumber(args.place), tonumber(args.place)},
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

---@param args table
---@return table?
function Wrapper._processOpponent(args)
	local opponentInput = args[1] or ''
	-- case team opponent
	if opponentInput:match('class="team%-template') then
		-- attempts to find [[teamPage|teamDisplay]] and skips images (images have multiple |)
		local teamPage = opponentInput:match('%[%[([^|]-)|[^|]-%]%]')
		if not teamPage then
			return
		end
		return {type = Opponent.team, template = teamPage:lower()}
	end

	local opponentArgs = {}
	-- split the opponentInput into the sep. playerInputs
	local playerInputs = mw.text.split(opponentInput, '<span class="starcraft%-inline%-player')
	-- since the split can add empty strings we need to remove them again
	playerInputs = Array.filter(playerInputs, String.isNotEmpty)

	local opponentType = TYPE_FROM_NUMBER[#playerInputs]
	if not opponentType then
		return
	end

	for playerIndex, playerInput in ipairs(playerInputs) do
		Wrapper._processPlayer(playerInput, opponentArgs, 'p' .. playerIndex)
	end

	if Table.isEmpty(opponentArgs) then
		return
	end
	opponentArgs.type = opponentType

	-- archon handling gets ignored here
	-- due to the input patern for them being inconsistent it is unfeasible to regex them
	-- hence they already got manually converted to use the automated GroupTableLeague

	return opponentArgs
end

-- parse the single player and add them to the opponentArgs
---@param playerInput string
---@param opponentArgs table
---@param prefix string
function Wrapper._processPlayer(playerInput, opponentArgs, prefix)
	-- attempts to find [[link|name]] and skips images (images have multiple |)
	local link, name = playerInput:match('%[%[([^|]-)|([^|]-)%]%]')
	if String.isEmpty(link) or String.isEmpty(name) then
		-- invalid input
		return
	end
	opponentArgs[prefix] = name
	opponentArgs[prefix .. 'link'] = link
	opponentArgs[prefix .. 'flag'] = playerInput:match('<span class="flag">%[%[File:[^|]-%.png|36x24px|([^|]-)|')

	-- get the faction
	-- first remove the flag so that only 1 image is left
	playerInput = playerInput:gsub('<span class="flag">.-</span>', '')
	-- now read the faction from the remaining file
	opponentArgs[prefix .. 'faction'] = playerInput:match('&nbsp;%[%[File:[^]]-|([^|]-)%]%]')
end

---@param args table
---@return boolean
function Wrapper._shouldStore(args)
	return Logic.readBool(Logic.emptyOr(args.store, Namespace.isMain()))
end

return Wrapper
