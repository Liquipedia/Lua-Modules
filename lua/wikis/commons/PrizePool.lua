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
local String = Lua.import('Module:StringUtils')

local Import = Lua.import('Module:PrizePool/Import')
local BasePrizePool = Lua.import('Module:PrizePool/Base')
local Placement = Lua.import('Module:PrizePool/Placement')

local Opponent = Lua.import('Module:Opponent/Custom')

local Widgets = Lua.import('Module:Widget/All')
local Span = Widgets.Span
local TableCell = Lua.import('Module:Widget/Table2/All').Cell

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
---@return Renderable
function PrizePool:placeOrAwardCell(placement)
	local badgeClass = placement:getBadgeClass()
	local placeDisplay = placement:_displayPlace()
	local content = badgeClass
		and Span{classes = {'prizepooltable-badge', badgeClass}, children = {placeDisplay}}
		or placeDisplay

	return TableCell{
		children = {content},
		classes = {'prizepooltable-place'},
		rowspan = #placement.opponents,
	}
end

---@param placement PrizePoolPlacement
---@return boolean
function PrizePool:applyHideAfter(placement)
	return placement.placeStart > self.options.hideafter
end

---@return integer?
function PrizePool:_cutafterRows()
	if self.options.cutafter == math.huge then
		return nil
	end
	local count = 0
	for _, placement in ipairs(self.placements) do
		if placement.placeStart > self.options.cutafter then
			break
		end
		if placement.placeStart > self.options.hideafter then
			break
		end
		count = count + math.max(#placement.opponents, 1)
	end
	return count > 0 and count or nil
end

---@return {opentext: string, closetext: string}?
function PrizePool:_collapseText()
	local firstHidden, lastPlace
	for _, placement in ipairs(self.placements) do
		if placement.placeStart > self.options.hideafter then
			break
		end
		lastPlace = placement.placeEnd
		if not firstHidden and placement.placeStart > self.options.cutafter then
			firstHidden = placement.placeStart
		end
	end
	if not firstHidden or not lastPlace then
		return nil
	end
	local text = 'place ' .. firstHidden .. ' to ' .. lastPlace
	return {opentext = text, closetext = text}
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
