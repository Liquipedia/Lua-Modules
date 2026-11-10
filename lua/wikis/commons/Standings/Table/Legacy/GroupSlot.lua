---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/GroupSlot
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local StandingTable = Lua.import('Module:Standings/Table')

local Opponent = Lua.import('Module:Opponent/Custom')

---Adaptor for the group tables of Template:GroupTableStart, Template:GroupTableSlot and Template:GroupTableEnd
local StandingTableLegacyGroupSlot = {}

local STASH = 'standings_legacy_group_slot'

local STATUSES = {
	u = 'up', up = 'up', proceed = 'up',
	su = 'stayup', stayup = 'stayup',
	s = 'stay', stay = 'stay',
	sd = 'staydown', staydown = 'staydown',
	d = 'down', down = 'down', drop = 'down',
}

-- Each count of a result times its points, read from the start, then the slot, then the default
local RESULT_POINTS = {
	{count = 'win_m', inputs = {'win_p', 'win_points'}, default = 3},
	{count = 'tie_m', inputs = {'tie_p'}, default = 1},
	{count = 'lose_m', inputs = {'loss_p'}, default = 0},
	{count = 'ot_win_m', inputs = {'ot_win_p'}, default = 2},
	{count = 'ot_lose_m', inputs = {'ot_lose_p'}, default = 1},
}

---The GroupTableSlot variants of wikis
---@class LegacyGroupSlotConfig
---@field pointsShownByDefault boolean # Points show unless `show_p=false`, else only with `show_p=true`
---@field countsTempPoints boolean # `temp_p` adds to the points

---@type LegacyGroupSlotConfig
StandingTableLegacyGroupSlot.CONFIG = {pointsShownByDefault = true, countsTempPoints = false}

---@type LegacyGroupSlotConfig
StandingTableLegacyGroupSlot.POINTS_OPT_IN_CONFIG = {pointsShownByDefault = false, countsTempPoints = true}

---Template:GroupTableStart
---@param frame Frame
---@return string
function StandingTableLegacyGroupSlot.slotStart(frame)
	local args = Arguments.getArgs(frame)
	args.__source = 'legacy_start'
	-- The stash is JSON, which keeps no positional keys
	args.title = args.title or args[1]
	return Template.stashReturnValue(args, STASH)
end

---Template:GroupTableSlot
---@param frame Frame
---@return string
function StandingTableLegacyGroupSlot.slot(frame)
	local args = Arguments.getArgs(frame)
	args.__source = 'legacy_slot'
	args.opponent = args[1]
	return Template.stashReturnValue(args, STASH)
end

---Template:GroupTableEnd
---@param frame Frame
---@return Renderable?
function StandingTableLegacyGroupSlot.templateEnd(frame)
	return StandingTableLegacyGroupSlot.run(StandingTableLegacyGroupSlot.CONFIG)
end

---Template:GroupTableEnd of wikis that only show points with `show_p=true`
---@param frame Frame
---@return Renderable?
function StandingTableLegacyGroupSlot.templateEndPointsOptIn(frame)
	return StandingTableLegacyGroupSlot.run(StandingTableLegacyGroupSlot.POINTS_OPT_IN_CONFIG)
end

---@param config LegacyGroupSlotConfig
---@return Renderable?
function StandingTableLegacyGroupSlot.run(config)
	local entries = Template.retrieveReturnValues(STASH)
	if #entries == 0 then
		return
	end

	local startArgs = table.remove(entries, 1)
	local isSlot = function(entry) return entry.__source == 'legacy_slot' end
	if startArgs.__source ~= 'legacy_start' or not Array.all(entries, isSlot) then
		mw.ext.TeamLiquidIntegration.add_category('Pages with malformed Legacy GroupTableSlot structure')
		error('Invalid legacy GroupTableSlot setup')
	end

	return StandingTable.fromTemplate(StandingTableLegacyGroupSlot.parseTable(startArgs, entries, config))
end

---@param startArgs table
---@param slots table[]
---@param config LegacyGroupSlotConfig
---@return table
function StandingTableLegacyGroupSlot.parseTable(startArgs, slots, config)
	local points = Array.map(slots, function(slot)
		return StandingTableLegacyGroupSlot.parsePoints(startArgs, slot, config)
	end)
	local tiebreakers = StandingTableLegacyGroupSlot.parseOrder(Array.map(slots, function(slot, index)
		return {place = tonumber(slot.place), points = points[index]}
	end))

	local opponents = Array.map(slots, function(slot, index)
		return Table.merge(
			StandingTableLegacyGroupSlot.parseOpponent(slot.opponent),
			StandingTableLegacyGroupSlot.parseRecord(slot),
			{
				points = points[index],
				tiebreaker = tiebreakers[index],
				dq = String.trim(slot.place or ''):lower() == 'dq' or nil,
				r1bg = StandingTableLegacyGroupSlot.parseStatus(slot.bg),
			}
		)
	end)

	-- `pbg` is the status of the placement, by slot as the rows keep their order
	local bgs = {}
	Array.forEach(slots, function(slot, index)
		local status = StandingTableLegacyGroupSlot.parseStatus(slot.pbg)
		if status then
			table.insert(bgs, index .. '=' .. status)
		end
	end)

	return Table.merge({
		tabletype = 'group',
		import = false,
		importopponents = false,
		started = true,
		finished = true,
		title = startArgs.title,
		width = startArgs.width,
		date = DateExt.readTimestampOrNil(startArgs.edate or startArgs.date),
		bg = table.concat(bgs, ','),
		tiebreakers = StandingTableLegacyGroupSlot.pointsShown(startArgs, slots, config)
			and {'manual', 'points'} or {'manual'},
	}, opponents)
end

---@param value string?
---@param name string
---@return number?
local function readNumber(value, name)
	value = String.trim(value or '')
	if value == '' then
		return nil
	end
	return assert(tonumber((value:gsub('^%+', ''))), 'Invalid ' .. name .. ': ' .. value)
end

---Legacy shows `overwrite_p` in place of the points of the results
---@param startArgs table
---@param slot table
---@param config LegacyGroupSlotConfig
---@return number
function StandingTableLegacyGroupSlot.parsePoints(startArgs, slot, config)
	local overwrite = readNumber(slot.overwrite_p, 'overwrite_p')
	if overwrite then
		return overwrite
	end

	local function pointsPer(resultPoints)
		for _, args in ipairs{startArgs, slot} do
			for _, input in ipairs(resultPoints.inputs) do
				local value = readNumber(args[input], input)
				if value then
					return value
				end
			end
		end
		return resultPoints.default
	end

	local points = config.countsTempPoints and readNumber(slot.temp_p, 'temp_p') or 0
	for _, resultPoints in ipairs(RESULT_POINTS) do
		points = points + (readNumber(slot[resultPoints.count], resultPoints.count) or 0) * pointsPer(resultPoints)
	end
	return points
end

---Legacy shows overtime results in the wins and losses
---@param slot table
---@return table<string, number>
function StandingTableLegacyGroupSlot.parseRecord(slot)
	local function read(...)
		local total
		for _, input in ipairs{...} do
			local value = readNumber(slot[input], input)
			if value then
				total = (total or 0) + value
			end
		end
		return total
	end

	local function first(...)
		for _, input in ipairs{...} do
			local value = read(input)
			if value then
				return value
			end
		end
	end

	return {
		matchwins = read('win_m', 'ot_win_m'),
		matchdraws = read('tie_m'),
		matchlosses = read('lose_m', 'ot_lose_m'),
		gamewins = first('win_g', 'w_map'),
		gamedraws = read('tie_g'),
		gamelosses = first('lose_g', 'l_map'),
		roundwins = first('win_r', 'win_b'),
		roundlosses = first('lose_r', 'lose_b'),
	}
end

---The order of the rows is kept by the manual tiebreaker. Consecutive rows share a place only with the same `place`
---and points, so a mistyped `place` does not reorder them.
---@param rows {place: number?, points: number}[]
---@return integer[]
function StandingTableLegacyGroupSlot.parseOrder(rows)
	local values = {}
	Array.forEach(rows, function(row, index)
		local previous = rows[index - 1]
		local sharesPlace = previous and row.place and row.place == previous.place and row.points == previous.points
		values[index] = sharesPlace and values[index - 1] or -index
	end)
	return values
end

---@param input string?
---@return string?
function StandingTableLegacyGroupSlot.parseStatus(input)
	input = String.trim(input or ''):lower()
	if input == '' then
		return nil
	end
	return STATUSES[input] or input
end

---@param startArgs table
---@param slots table[]
---@param config LegacyGroupSlotConfig
---@return boolean
function StandingTableLegacyGroupSlot.pointsShown(startArgs, slots, config)
	local showPoints = Logic.readBoolOrNil(startArgs.show_p)
	if config.pointsShownByDefault then
		return Logic.nilOr(showPoints, Logic.readBoolOrNil((slots[1] or {}).show_p), true) --[[@as boolean]]
	end
	return showPoints == true
end

local ENTITIES = {amp = '&', quot = '"', lt = '<', gt = '>', nbsp = ' ', ['#39'] = "'", ['#039'] = "'"}

---@param input string
---@return string
local function decodeEntities(input)
	return (input:gsub('&(#?%w+);', ENTITIES))
end

---@param input string
---@return string
local function plainText(input)
	local text = input
		:gsub('%[%[[Ff]ile:[^%]]*%]%]', '')
		:gsub('%[%[[^%]|]+|([^%]]+)%]%]', '%1')
		:gsub('%[%[([^%]]+)%]%]', '%1')
		:gsub('<[^>]+>', '')
	return String.trim(decodeEntities(text))
end

---@param input string
---@return string?
local function readFlag(input)
	return input:match('class="flag">%[%[[Ff]ile:([%w%-]+)[ _]hd%.png')
end

---The expanded team templates hold the name and page of the team, not its template. The page is the template.
---@param input string
---@return string?
function StandingTableLegacyGroupSlot.findTeam(input)
	-- The team part of a player has no highlighting
	local teamStart = input:find('data%-highlighting%-?class="') or input:find('team-template-team-part', 1, true)
	if not teamStart then
		return
	end
	local team = input:sub(teamStart)
	local page = team:match('team%-template%-text">%[%[([^%]|]+)') or team:match('link=([^|%]]+)')
		or team:match('data%-highlighting%-?class="([^"]+)"')
	return decodeEntities(page):gsub('_', ' '):lower()
end

---The opponent is the expanded `{{Team}}`, `{{TeamShort}}`, `{{TeamIcon}}`, `{{Player}}` or `{{Flag}}` and name of
---the slot, or plain text.
---@param input string?
---@return table
function StandingTableLegacyGroupSlot.parseOpponent(input)
	input = input or ''

	-- Before the team, as players can have a team icon in front of them
	local playerStart = input:find('inline-player', 1, true)
	if playerStart then
		local player = input:sub(playerStart)
		local link, name
		for target, text in player:gmatch('%[%[([^%[%]|]+)|?([^%[%]]*)%]%]') do
			if not target:find('^[Ff]ile:') then
				link, name = target, Logic.emptyOr(text, target)
				break
			end
		end
		return {
			type = Opponent.solo,
			name and decodeEntities(name) or plainText(player),
			link = link,
			flag = readFlag(player) or readFlag(input),
			team = StandingTableLegacyGroupSlot.findTeam(input),
		}
	end

	local team = StandingTableLegacyGroupSlot.findTeam(input)
	if team then
		return {type = Opponent.team, template = team}
	end

	local text = plainText(input)
	local flag = readFlag(input)
	if flag and text ~= '' then
		return {type = Opponent.solo, text, flag = flag}
	end
	return {type = Opponent.literal, name = text}
end

return StandingTableLegacyGroupSlot
