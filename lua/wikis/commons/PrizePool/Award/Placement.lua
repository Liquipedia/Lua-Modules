---
-- @Liquipedia
-- page=Module:PrizePool/Award/Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BasePlacement = Lua.import('Module:PrizePool/Placement/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local _tbd_index = 0

local PRIZE_TYPE_BASE_CURRENCY = 'BASE_CURRENCY'
local PRIZE_TYPE_POINTS = 'POINTS'

--- @class AwardPlacement
--- An AwardPlacement is a set of opponents who all share the same award in the tournament.
--- Its input is generally a table created by `Template:Slot`.
--- @field args table
--- @field parent AwardPrizePool
--- @field parseOpponents function
--- @field getPrizeRewardForOpponent function
--- @field previousTotalNumberOfParticipants integer
--- @field currentTotalNumberOfParticipants integer
local AwardPlacement = Class.new(BasePlacement)

--- @param award string Award of this slot/placement
--- @return self
function AwardPlacement:create(award)
	self.award = award
	self.count = tonumber(self.args.count)
	self.opponents = self:parseOpponents(self.args)
	self.count = self.count or math.max(#self.opponents, 1)

	return self
end

--- No additionalData for awards so return empty table
---@param args table
---@return {}
function AwardPlacement:readAdditionalData(args)
	return {}
end

---@param ... string|number
---@return placement[]
function AwardPlacement:_getLpdbData(...)
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
			date = opponent.date,
			prizemoney = prizeMoney,
			individualprizemoney = Opponent.typeIsParty(opponentType) and (prizeMoney / Opponent.partySize(opponentType)) or 0,
			mode = 'award_individual',
			weight = 0,
			extradata = {
				award = self.award,
				prizepoints = tostring(pointsReward or ''),
				-- legacy
				participantteam = (opponentType == Opponent.solo and players.p1team)
									and Opponent.toName{template = players.p1team, type = 'team'}
									or nil,
			},
			-- TODO: We need to create additional LPDB Field for Points struct (json?)

			-- legacy
			image = image,
			imagedark = imageDark,
			participant = participant,
			participantlink = Opponent.toName(opponent.opponentData),
			participantflag = opponentType == Opponent.solo and players.p1flag or nil,
			participanttemplate = opponent.opponentData.template,
			players = players,
		}

		lpdbData = Table.mergeInto(lpdbData, Opponent.toLpdbStruct(opponent.opponentData))

		lpdbData.objectName = self.parent:_lpdbObjectName(lpdbData, ...)
		if Opponent.isTbd(opponent.opponentData) then
			_tbd_index = _tbd_index + 1
			lpdbData.objectName = lpdbData.objectName .. _tbd_index
		end

		if self.parent._lpdbInjector then
			lpdbData = self.parent._lpdbInjector:adjust(lpdbData, self, opponent)
		end

		table.insert(entries, lpdbData)
	end

	return entries
end

-- No BG for awards
function AwardPlacement:getBackground()
	return
end

return AwardPlacement
