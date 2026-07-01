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

local HtmlWidgets = Lua.import('Module:Widget/Html')
local Span = HtmlWidgets.Span
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local TableCell = TableWidgets.Cell

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

---@protected
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

---@protected
---@param placement PrizePoolPlacement
---@return boolean
function PrizePool:applyHideAfter(placement)
	return placement.placeStart > self.options.hideafter
end

---@protected
---@param placement PrizePoolPlacement
---@return boolean
function PrizePool:applyCutAfter(placement)
	return placement.placeStart > self.options.cutafter
end

---@protected
---@return {opentext: string, closetext: string}?
function PrizePool:_collapseText()
	local visible = Array.filter(self.placements, function(placement)
		return placement.placeStart <= self.options.hideafter
	end)
	local lastVisible = visible[#visible]
	local firstHidden = Array.find(visible, function(placement)
		return placement.placeStart > self.options.cutafter
	end)
	if not firstHidden or not lastVisible then
		return nil
	end
	local text = 'place ' .. firstHidden.placeStart .. ' to ' .. lastVisible.placeEnd
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
