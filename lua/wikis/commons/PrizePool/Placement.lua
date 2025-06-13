---
-- @Liquipedia
-- page=Module:PrizePool/Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchPlacement = require('Module:Match/Placement')
local Ordinal = require('Module:Ordinal')
local PlacementInfo = require('Module:Placement')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

---@class PrizePoolPlacement: BasePlacement
---@field opponents BasePlacementOpponent[]
local BasePlacement = Lua.import('Module:PrizePool/Placement/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local DASH = '&#045;'

local PRIZE_TYPE_BASE_CURRENCY = 'BASE_CURRENCY'
local PRIZE_TYPE_POINTS = 'POINTS'

-- Allowed none-numeric score values.
local SPECIAL_SCORES = {'W', 'FF' , 'L', 'DQ', 'D'}

local _tbd_index = 0

--- @class PrizePoolPlacement: BasePlacement
--- A Placement is a set of opponents who all share the same final place in the tournament.
--- Its input is generally a table created by `Template:Slot`.
--- It has a range from placeStart to placeEnd, for example 5 to 8, or count (slotSize)
--- and is expected to have at maximum the same amount of opponents as the range allows (4 in the 5-8 example).
--- @field parent PrizePool
--- @field args table
local Placement = Class.new(BasePlacement)

Placement.specialStatuses = {
	DQ = {
		active = function (args)
			return Logic.readBool(args.dq)
		end,
		display = function ()
			return Abbreviation.make{text = 'DQ', title = 'Disqualified'}
		end,
		lpdb = 'DQ',
	},
	DNF = {
		active = function (args)
			return Logic.readBool(args.dnf)
		end,
		display = function ()
			return Abbreviation.make{text = 'DNF', title = 'Did not finish'}
		end,
		lpdb = 'DNF',
	},
	DNP = {
		active = function (args)
			return Logic.readBool(args.dnp)
		end,
		display = function ()
			return Abbreviation.make{text = 'DNP', title = 'Did not participate'}
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
			return Abbreviation.make{text = 'Q', title = 'Qualified Automatically'}
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
			return placement:parseOpponentArgs(input, context.date)
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
			local rawScores = Array.map(mw.text.split(input, '-'), String.trim)
			local scores = {}
			for index, rawScore in ipairs(rawScores) do
				if Logic.isEmpty(rawScore) and Logic.isNotEmpty(rawScores[index + 1]) then
					rawScores[index + 1] = '-' .. rawScores[index + 1]
				else
					table.insert(scores, rawScore)
				end
			end

			scores = Table.mapValues(scores, forceValidScore)
			return {score = scores[1], vsscore = scores[2]}
		end
	},
	LASTVSMATCHID = {
		field = 'lastvsmatchid',
		parse = function (placement, input, context)
			return input
		end
	},
}

---@param lastPlacement integer The previous placement's end
---@return self
function Placement:create(lastPlacement)
	self:_parseArgs()

	self.opponents = self:parseOpponents(self.args)

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

	return self
end

function Placement:_parseArgs()
	local args = self.args

	self.count = tonumber(args.count)

	-- Explicit place range has been given
	if args.place then
		local places = Table.mapValues(mw.text.split(args.place, '-'), tonumber)
		self.placeStart = places[1]
		self.placeEnd = places[2] or places[1]
		assert(self.placeStart and self.placeEnd, 'Placement: Invalid |place= provided.')

		local calculatedCount = self.placeEnd - self.placeStart + 1
		self.count = self.count or calculatedCount

		assert(self.count <= calculatedCount,
			'Placement: Invalid count (' .. self.count .. ') and placement (' .. args.place .. ') combination')
	end
end

--- Parse and set additional data fields for opponents.
-- This includes fields such as group stage score (wdl) and last versus (lastvs).
---@param args table
---@return table
function Placement:readAdditionalData(args)
	local data = {}

	for prizeType, typeData in pairs(self.additionalData) do
		local fieldName = typeData.field
		if args[fieldName] then
			data[prizeType] = typeData.parse(self, args[fieldName], args)
		end
	end

	return data
end

---@param ... string|number
---@return placement[]
function Placement:_getLpdbData(...)
	local entries = {}
	for _, opponent in ipairs(self.opponents) do
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
		lpdbData.players = lpdbData.players or Table.copy(lpdbData.opponentplayers or {})

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

---@return string|number
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

---@return string?
function Placement:_displayPlace()
	for _, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return status.display()
		end
	end

	local start = Ordinal.toOrdinal(self.placeStart)
	if self.placeEnd > self.placeStart then
		return start .. DASH .. Ordinal.toOrdinal(self.placeEnd)
	end

	return start
end

---@return string?
function Placement:getBackground()
	for statusName, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return PlacementInfo.getBgClass{placement = statusName:lower()}
		end
	end

	return PlacementInfo.getBgClass{placement = self.placeStart}
end

---@return string?
function Placement:getMedal()
	if self:hasSpecialStatus() then
		return
	end

	local medal = MatchPlacement.MedalIcon{range = {self.placeStart, self.placeEnd}}
	if medal then
		return tostring(medal)
	end
end

---@return boolean
function Placement:hasSpecialStatus()
	return Table.any(Placement.specialStatuses, function(_, status) return status.active(self.args) end)
end

return Placement
