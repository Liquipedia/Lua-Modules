---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local MatchPlacement = require('Module:Match/Placement')
local Ordinal = require('Module:Ordinal')
local PlacementInfo = require('Module:Placement')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Opponent = require('Module:OpponentLibraries').Opponent

local DASH = '&#045;'

local PRIZE_TYPE_BASE_CURRENCY = 'BASE_CURRENCY'
local PRIZE_TYPE_POINTS = 'POINTS'

-- Allowed none-numeric score values.
local SPECIAL_SCORES = {'W', 'FF' , 'L', 'DQ', 'D'}

local _tbd_index = 0

--- @class Placement
--- A Placement is a set of opponents who all share the same final place in the tournament.
--- Its input is generally a table created by `Template:Placement`.
--- It has a range from placeStart to placeEnd, for example 5 to 8
--- and is expected to have the same amount of opponents as the range allows (4 is the 5-8 example).
local Placement = Class.new(function(self, ...) self:init(...) end)

Placement.specialStatuses = {
	DQ = {
		active = function (args)
			return Logic.readBool(args.dq)
		end,
		display = function ()
			return Abbreviation.make('DQ', 'Disqualified')
		end,
		lpdb = 'DQ',
	},
	DNF = {
		active = function (args)
			return Logic.readBool(args.dnf)
		end,
		display = function ()
			return Abbreviation.make('DNF', 'Did not finish')
		end,
		lpdb = 'DNF',
	},
	DNP = {
		active = function (args)
			return Logic.readBool(args.dnp)
		end,
		display = function ()
			return Abbreviation.make('DNP', 'Did not participate')
		end,
		lpdb = 'DNP',
	},
	W = {
		active = function (args)
			return Logic.readBool(args.w)
		end,
		display = function ()
			return 'W'
		end,
		lpdb = 'W',
	},
	D = {
		active = function (args)
			return Logic.readBool(args.d)
		end,
		display = function ()
			return 'D'
		end,
		lpdb = 'D',
	},
	L = {
		active = function (args)
			return Logic.readBool(args.l)
		end,
		display = function ()
			return 'L'
		end,
		lpdb = 'L',
	},
	Q = {
		active = function (args)
			return Logic.readBool(args.q)
		end,
		display = function ()
			return Abbreviation.make('Q', 'Qualified Automatically')
		end,
		lpdb = 'Q',
	},
}

Placement.additionalData = {
	GROUPSCORE = {
		field = 'wdl',
		parse = function (placement, input, context)
			return input
		end
	},
	LASTVS = {
		field = 'lastvs',
		parse = function (placement, input, context)
			return placement:_parseOpponentArgs(input, context.date)
		end
	},
	LASTVSSCORE = {
		field = 'lastvsscore',
		parse = function (placement, input, context)
			local forceValidScore = function(score)
				if Table.includes(SPECIAL_SCORES, score:upper()) then
					return score:upper()
				end
				return tonumber(score)
			end

			-- split the lastvsscore entry by '-', but allow negative scores
			local rawScores = Table.mapValues(mw.text.split(input, '-'), mw.text.trim)
			local scores = {}
			for index, rawScore in ipairs(rawScores) do
				if String.isEmpty(rawScore) and String.isNotEmpty(rawScores[index + 1]) then
					rawScores[index + 1] = '-' .. rawScores[index + 1]
				else
					table.insert(scores, rawScore)
				end
			end

			scores = Table.mapValues(scores, forceValidScore)
			return {score = scores[1], vsscore = scores[2]}
		end
	},
}

--- @class Placement
--- @param args table Input information
--- @param parent PrizePool The PrizePool this Placement is part of
--- @param lastPlacement integer The previous placement's end
function Placement:init(args, parent, lastPlacement)
	self.args = self:_parseArgs(args)
	self.parent = parent
	self.prizeTypes = parent.prizeTypes
	self.date = self.args.date or parent.date
	self.placeStart = self.args.placeStart
	self.placeEnd = self.args.placeEnd
	self.count = self.args.count
	self.hasBaseCurrency = false

	self.prizeRewards = self:_readPrizeRewards(self.args)

	self.opponents = self:_parseOpponents(self.args)

	self.count = self.count or math.max(#self.opponents, 1)

	-- Implicit place range has been given (|place= is unset)
	-- Use the last known place and set the place range based on the entered args.count
	-- or the number of entered opponents
	if not self.placeStart and not self.placeEnd then
		self.placeStart = lastPlacement + 1
		self.placeEnd = lastPlacement + self.count
	end

	assert(#self.opponents <= self.count,
		'Placement: Too many opponents in place ' .. self:_displayPlace():gsub('&#045;', '-'))
end

function Placement:_parseArgs(args)
	local parsedArgs = Table.deepCopy(args)

	parsedArgs.count = tonumber(args.count)

	-- Explicit place range has been given
	if args.place then
		local places = Table.mapValues(mw.text.split(args.place, '-'), tonumber)
		parsedArgs.placeStart = places[1]
		parsedArgs.placeEnd = places[2] or places[1]
		assert(parsedArgs.placeStart and parsedArgs.placeEnd, 'Placement: Invalid |place= provided.')

		local calculatedCount = parsedArgs.placeEnd - parsedArgs.placeStart + 1
		parsedArgs.count = parsedArgs.count or calculatedCount

		assert(parsedArgs.count <= calculatedCount,
			'Placement: Invalid count (' .. parsedArgs.count .. ') and placement (' .. args.place .. ') combination')
	end

	return parsedArgs
end

--- Parse the input for available rewards of prizes, for instance how much money a team would win.
--- This also checks if the Placement instance has a dollar reward and assigns a variable if so.
function Placement:_readPrizeRewards(args)
	local rewards = {}

	-- Loop through all prizes that have been defined in the header
	Array.forEach(self.parent.prizes, function (prize)
		local prizeData = self.prizeTypes[prize.type]
		local fieldName = prizeData.row
		if not fieldName then
			return
		end

		local prizeIndex = prize.index
		local reward = args[fieldName .. prizeIndex]
		if prizeIndex == 1 then
			reward = reward or args[fieldName]
		end
		if not reward then
			return
		end

		rewards[prize.id] = prizeData.rowParse(self, reward, args, prizeIndex)
	end)

	-- Special case for Base Currency, as it's not defined in the header.
	local baseType = self.prizeTypes[PRIZE_TYPE_BASE_CURRENCY]
	if baseType.row and args[baseType.row] then
		self.hasBaseCurrency = true
		rewards[PRIZE_TYPE_BASE_CURRENCY .. 1] = baseType.rowParse(self, args[baseType.row], args, 1)
	end

	return rewards
end

--- Parse and set additional data fields for opponents.
-- This includes fields such as group stage score (wdl) and last versus (lastvs).
function Placement:_readAdditionalData(args)
	local data = {}

	for prizeType, typeData in pairs(self.additionalData) do
		local fieldName = typeData.field
		if args[fieldName] then
			data[prizeType] = typeData.parse(self, args[fieldName], args)
		end
	end

	return data
end

function Placement:_parseOpponents(args)
	return Array.mapIndexes(function(opponentIndex)
		local opponentInput = Json.parseIfString(args[opponentIndex])
		local opponent = {opponentData = {}, prizeRewards = {}, additionalData = {}}
		if not opponentInput then
			if self:_shouldAddTbdOpponent(opponentIndex) then
				opponent.opponentData = Opponent.tbd(self.parent.opponentType)
			else
				return
			end
		else
			-- Set the date
			if not Placement._isValidDateFormat(opponentInput.date) then
				opponentInput.date = self.date
			end

			-- Parse Opponent Data
			if opponentInput.type then
				self.parent:assertOpponentStructType(opponentInput)
			else
				opponentInput.type = self.parent.opponentType
			end
			opponent.opponentData = self:_parseOpponentArgs(opponentInput, opponentInput.date)

			opponent.prizeRewards = self:_readPrizeRewards(opponentInput)
			opponent.additionalData = self:_readAdditionalData(opponentInput)

			-- Set date
			opponent.date = opponentInput.date
		end
		return opponent
	end)
end

function Placement:_shouldAddTbdOpponent(opponentIndex)
	-- We want at least 1 opponent present for all placements
	if opponentIndex == 1 then
		return true
	end
	-- If the fillPlaceRange option is disabled or we do not have a give placeRange do not fill up further
	if not self.parent.options.fillPlaceRange or not self.count then
		return false
	end
	-- Only fill up further with TBD's if there is free space in the placeRange/slot
	if opponentIndex <= self.count then
		return true
	end
	return false
end

function Placement:_parseOpponentArgs(input, date)
	-- Allow for lua-table, json-table and just raw string input
	local opponentArgs = Json.parseIfTable(input) or (type(input) == 'table' and input or {input})
	opponentArgs.type = opponentArgs.type or self.parent.opponentType
	assert(Opponent.isType(opponentArgs.type), 'Invalid type')

	local opponentData
	if type(opponentArgs[1]) == 'table' and opponentArgs[1].isAlreadyParsed then
		opponentData = opponentArgs[1]
	elseif type(opponentArgs[1]) ~= 'table' then
		opponentData = Opponent.readOpponentArgs(opponentArgs)
	end

	if not opponentData or (Opponent.isTbd(opponentData) and opponentData.type ~= Opponent.literal) then
		opponentData = Table.deepMergeInto(Opponent.tbd(opponentArgs.type), opponentData or {})
	end

	return Opponent.resolve(opponentData, date, {syncPlayer = self.parent.options.syncPlayers})
end

function Placement:_getLpdbData(...)
	local entries = {}
	for opponentIndex, opponent in ipairs(self.opponents) do
		local participant, image, imageDark, players
		local opponentType = opponent.opponentData.type

		if opponentType == Opponent.team then
			local teamTemplate = mw.ext.TeamTemplate.raw(opponent.opponentData.template) or {}

			participant = teamTemplate.page or ''
			if self.parent.options.resolveRedirect then
				participant = mw.ext.TeamLiquidIntegration.resolve_redirect(participant)
			end

			image = teamTemplate.image
			imageDark = teamTemplate.imagedark
		elseif opponentType == Opponent.solo then
			participant = Opponent.toName(opponent.opponentData)
			local p1 = opponent.opponentData.players[1]
			players = {p1 = p1.pageName, p1dn = p1.displayName, p1flag = p1.flag, p1team = p1.team}
		else
			participant = Opponent.toName(opponent.opponentData)
		end

		local prizeMoney = tonumber(self:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_BASE_CURRENCY .. 1)) or 0
		local pointsReward = self:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1)
		local lpdbData = {
			image = image,
			imagedark = imageDark,
			date = opponent.date,
			participant = participant,
			participantlink = Opponent.toName(opponent.opponentData),
			participantflag = opponentType == Opponent.solo and players.p1flag or nil,
			participanttemplate = opponent.opponentData.template,
			opponentindex = opponentIndex, -- Needed in SMW
			players = players,
			placement = self:_lpdbValue(),
			prizemoney = prizeMoney,
			individualprizemoney = Opponent.typeIsParty(opponentType) and (prizeMoney / Opponent.partySize(opponentType)) or 0,
			lastvs = Opponent.toName(opponent.additionalData.LASTVS or {}),
			lastscore = (opponent.additionalData.LASTVSSCORE or {}).score,
			lastvsscore = (opponent.additionalData.LASTVSSCORE or {}).vsscore,
			groupscore = opponent.additionalData.GROUPSCORE,
			lastvsdata = Table.merge(
				opponent.additionalData.LASTVS and Opponent.toLpdbStruct(opponent.additionalData.LASTVS) or {},
				{
					score = (opponent.additionalData.LASTVSSCORE or {}).vsscore,
					groupscore = opponent.additionalData.GROUPSCORE,
				}
			),
			extradata = {
				prizepoints = tostring(pointsReward or ''),
				participantteam = (opponentType == Opponent.solo and players.p1team)
									and Opponent.toName{template = players.p1team, type = 'team'}
									or nil,
			}
			-- TODO: We need to create additional LPDB Fields
			-- Qualified To struct (json?)
			-- Points struct (json?)
		}

		lpdbData = Table.mergeInto(lpdbData, Opponent.toLpdbStruct(opponent.opponentData))

		lpdbData.objectName = self.parent:_lpdbObjectName(lpdbData, ...)
		if Opponent.isTbd(opponent.opponentData) then
			_tbd_index = _tbd_index + 1
			lpdbData.objectName = lpdbData.objectName .. '_' .. _tbd_index
		end

		if self.parent._lpdbInjector then
			lpdbData = self.parent._lpdbInjector:adjust(lpdbData, self, opponent)
		end

		table.insert(entries, lpdbData)
	end

	return entries
end

function Placement:getPrizeRewardForOpponent(opponent, prize)
	return opponent.prizeRewards[prize] or self.prizeRewards[prize]
end

function Placement:_setBaseFromRewards(prizesToUse, prizeTypes)
	Array.forEach(self.opponents, function(opponent)
		if opponent.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] or self.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] then
			return
		end

		local baseReward = 0
		Array.forEach(prizesToUse, function(prize)
			local localMoney = opponent.prizeRewards[prize.id] or self.prizeRewards[prize.id]

			if not localMoney or localMoney <= 0 then
				return
			end

			baseReward = baseReward + prizeTypes[prize.type].convertToBaseCurrency(
				prize.data,
				localMoney,
				opponent.date,
				self.parent.options.currencyRatePerOpponent
			)
			self.parent.usedAutoConvertedCurrency = true
		end)

		opponent.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] = baseReward
	end)
end

function Placement:_lpdbValue()
	for _, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return status.lpdb
		end
	end

	if self.placeEnd > self.placeStart then
		return self.placeStart .. '-' .. self.placeEnd
	end

	return self.placeStart
end

function Placement:_displayPlace()
	for _, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return status.display()
		end
	end

	local start = Ordinal._ordinal(self.placeStart)
	if self.placeEnd > self.placeStart then
		return start .. DASH .. Ordinal._ordinal(self.placeEnd)
	end

	return start
end

function Placement:getBackground()
	for statusName, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return PlacementInfo.getBgClass(statusName:lower())
		end
	end

	return PlacementInfo.getBgClass(self.placeStart)
end

function Placement:getMedal()
	if self:hasSpecialStatus() then
		return
	end

	local medal = MatchPlacement.MedalIcon{range = {self.placeStart, self.placeEnd}}
	if medal then
		return tostring(medal)
	end
end

function Placement:hasSpecialStatus()
	return Table.any(Placement.specialStatuses, function(_, status) return status.active(self.args) end)
end

--- Returns true if the input matches the format of a date
function Placement._isValidDateFormat(date)
	if type(date) ~= 'string' or String.isEmpty(date) then
		return false
	end
	return date:match('%d%d%d%d%-%d%d%-%d%d') and true or false
end

return Placement
