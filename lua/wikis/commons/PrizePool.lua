---
-- @Liquipedia
-- page=Module:PrizePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')

local Import = Lua.import('Module:PrizePool/Import')
local BasePrizePool = Lua.import('Module:PrizePool/Base')
local Placement = Lua.import('Module:PrizePool/Placement')

local Opponent = Lua.import('Module:Opponent/Custom')

local ChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/ChevronToggle')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Label = Lua.import('Module:Widget/Basic/Label')
local PrizePoolCell = Lua.import('Module:Widget/PrizePool/Cell')

---@class PrizePool: BasePrizePool
---@operator call(...): PrizePool
---@field placements PrizePoolPlacement[]
local PrizePool = Class.new(BasePrizePool)

---@param args table
function PrizePool:readPlacements(args)
	local currentPlace = 0
	self.placements = Array.mapIndexes(function(placementIndex)
		if not args[placementIndex] then
			return
		end

		local placementInput = Json.parseIfString(args[placementIndex])
		local placement = Placement(placementInput, self):create(currentPlace)

		currentPlace = placement.placeEnd

		return placement
	end)

	self.placements = Import.run(self)
end

---@param placement PrizePoolPlacement
---@return VNode
function PrizePool:placeOrAwardCell(placement)
	local placementDisplay = placement:_lpdbValue()

	return PrizePoolCell{
		children = Label{
			labelScheme = 'prize-pool-placement',
			children = placementDisplay
		},
		fullHeight = true,
	}
end

---@param placement PrizePoolPlacement
---@return boolean
function PrizePool:applyHideAfter(placement)
	return placement.placeStart > self.options.hideafter
end

---@param placement PrizePoolPlacement
---@return boolean
function PrizePool:applyCutAfter(placement)
	if placement.placeStart > self.options.cutafter then
		return true
	end
	return false
end

---@return VNode?
function PrizePool:getCollapsibleToggle()
	local placeStart = Array.find(self.placements, function (placement)
		return placement.placeStart > self.options.cutafter
	end)
	if not placeStart then
		return
	end
	local placeEnd = self.placements[#self.placements].placeEnd

	if self.options.hideafter < math.huge then
		local lastCut = Array.max(
			Array.filter(self.placements, function (placement)
				return placement.placeEnd <= self.options.hideafter
			end),
			Operator.property('placeEnd')
		)
		placeEnd = lastCut.placeEnd
	end

	local text = 'place ' .. placeStart.placeStart .. ' to ' .. placeEnd

	return Div{
		classes = {'prize-pool-toggle'},
		attributes = {['data-collapsible-click-region'] = 'true'},
		children = Div{children = {
			text,
			ChevronToggle{}
		}}
	}
end

-- get the lpdbObjectName depending on opponenttype
---@param lpdbEntry placement
---@param prizePoolIndex integer|string
---@param lpdbPrefix string?
---@return string
function PrizePool:_lpdbObjectName(lpdbEntry, prizePoolIndex, lpdbPrefix)
	local objectName = 'ranking'
	if String.isNotEmpty(lpdbPrefix) then
		objectName = objectName .. '_' .. lpdbPrefix
	end
	if lpdbEntry.opponenttype == Opponent.team then
		return objectName .. '_' .. mw.ustring.lower(lpdbEntry.participant)
	end
	-- for non team opponents the pagename can be case sensitive
	-- so objectname needs to be case sensitive to avoid edge cases
	return objectName .. prizePoolIndex .. '_' .. lpdbEntry.participant
end

return PrizePool
