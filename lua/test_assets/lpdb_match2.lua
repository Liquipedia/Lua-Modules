--- Triple Comment to Enable our LLS Plugin

--[[
Sample match2 records originally created for the match ticker card snapshot.
Records only include fields that are relevant to the snapshot generation.
]]
---@diagnostic disable: missing-fields

local TOURNAMENT = {
	tournament = 'Example Championship 2024',
	pagename = 'Example_Championship/2024',
	parent = 'Example_Championship/2024',
	liquipediatier = '1',
	liquipediatiertype = '',
	game = '',
}

local PAST_DATE = '2024-06-01 12:00:00'
local PAST_TIMESTAMP = 1717243200
local FUTURE_DATE = '2099-06-01 12:00:00'
local FUTURE_TIMESTAMP = 4083998400

---@param matchFields table
---@return match2
local function matchRecord(matchFields)
	local record = {}
	for key, value in pairs(TOURNAMENT) do
		record[key] = value
	end
	for key, value in pairs(matchFields) do
		record[key] = value
	end
	record.match2games = record.match2games or {}
	record.match2bracketdata = record.match2bracketdata or {}
	return record
end

---@param template string
---@param fields table?
---@return match2opponent
local function teamOpponent(template, fields)
	local opponent = {type = 'team', template = template, name = template, match2players = {}}
	for key, value in pairs(fields or {}) do
		opponent[key] = value
	end
	return opponent
end

---@param players {name: string, flag: string}[]
---@param fields table?
---@return match2opponent
local function playerOpponent(players, fields)
	local opponent = {type = #players == 1 and 'solo' or 'duo', match2players = {}}
	local names = {}
	for _, player in ipairs(players) do
		table.insert(names, player.name)
		table.insert(opponent.match2players, {name = player.name, displayname = player.name, flag = player.flag})
	end
	opponent.name = table.concat(names, ' / ')
	for key, value in pairs(fields or {}) do
		opponent[key] = value
	end
	return opponent
end

local BATTLE_ROYALE_TEAMS = {
	'team liquid', 'heroic', 'team secret', 'wolves esports',
	'streamerzone', 'natus vincere 2021', 'rogue 2021', 'mnm gaming 2021',
}
local BATTLE_ROYALE_PLACEMENTS = {4, 1, 7, 3, 8, 2, 6, 5}

---@param withPlacements boolean
---@return match2opponent[]
local function battleRoyaleOpponents(withPlacements)
	local opponents = {}
	for index, template in ipairs(BATTLE_ROYALE_TEAMS) do
		table.insert(opponents, teamOpponent(template, withPlacements and {
			placement = tostring(BATTLE_ROYALE_PLACEMENTS[index])
		} or nil))
	end
	return opponents
end

local teamVsTeam = matchRecord{
	match2id = 'TICKERTEST_R01-M001',
	bestof = '3',
	date = PAST_DATE,
	dateexact = '1',
	finished = '1',
	winner = '1',
	mode = 'team',
	section = 'Playoffs',
	extradata = {timestamp = PAST_TIMESTAMP},
	match2opponents = {
		teamOpponent('team liquid', {score = '2', status = 'S'}),
		teamOpponent('heroic', {score = '1', status = 'S'}),
	},
}

local playerVsPlayer = matchRecord{
	match2id = 'TICKERTEST_R01-M002',
	bestof = '5',
	date = FUTURE_DATE,
	dateexact = '1',
	finished = '0',
	mode = 'solo',
	section = 'Playoffs',
	extradata = {timestamp = FUTURE_TIMESTAMP},
	match2opponents = {
		playerOpponent({{name = 'Serral', flag = 'fi'}}),
		playerOpponent({{name = 'Clem', flag = 'fr'}}),
	},
}

local duoVsDuo = matchRecord{
	match2id = 'TICKERTEST_R01-M003',
	bestof = '3',
	date = PAST_DATE,
	dateexact = '1',
	finished = '1',
	winner = '2',
	mode = 'duo',
	section = 'Playoffs',
	extradata = {timestamp = PAST_TIMESTAMP},
	match2opponents = {
		playerOpponent({{name = 'Reynor', flag = 'it'}, {name = 'MaxPax', flag = 'dk'}}, {score = '0', status = 'S'}),
		playerOpponent({{name = 'Cure', flag = 'kr'}, {name = 'Dark', flag = 'kr'}}, {score = '2', status = 'S'}),
	},
}

local upcomingBattleRoyale = matchRecord{
	match2id = 'TICKERTEST_R01-M004',
	bestof = '0',
	date = FUTURE_DATE,
	dateexact = '1',
	finished = '0',
	mode = 'team',
	section = 'Grand Final',
	extradata = {timestamp = FUTURE_TIMESTAMP},
	match2opponents = battleRoyaleOpponents(false),
}

local completedBattleRoyale = matchRecord{
	match2id = 'TICKERTEST_R01-M005',
	bestof = '0',
	date = PAST_DATE,
	dateexact = '1',
	finished = '1',
	mode = 'team',
	section = 'Grand Final',
	extradata = {timestamp = PAST_TIMESTAMP},
	match2opponents = battleRoyaleOpponents(true),
}

--- In display order.
---@type match2[]
return {
	teamVsTeam,
	playerVsPlayer,
	duoVsDuo,
	upcomingBattleRoyale,
	completedBattleRoyale,
}
