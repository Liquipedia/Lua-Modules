---
-- @Liquipedia
-- page=Module:PrizePool/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local String = Lua.import('Module:StringUtils')

local BasePrizePool = Lua.import('Module:PrizePool/Base')
local Placement = Lua.import('Module:PrizePool/Award/Placement')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local Widgets = Lua.import('Module:Widget/All')
local TableRow = Widgets.TableRow
local TableCell = Widgets.TableCell

--- @class AwardPrizePool
--- @field options table
--- @field _lpdbInjector LpdbInjector?
local AwardPrizePool = Class.new(BasePrizePool)

---@param args table
function AwardPrizePool:readPlacements(args)
	local numberOfParticipants = 0
	self.placements = Array.mapIndexes(function(placementIndex)
		if not args[placementIndex] then
			return
		end

		local placementInput = Json.parseIfString(args[placementIndex])
		if not placementInput.award then
			return
		end

		local placement = Placement(placementInput, self):create(placementInput.award)
		placement.previousTotalNumberOfParticipants = numberOfParticipants
		numberOfParticipants = numberOfParticipants + #placement.opponents
		placement.currentTotalNumberOfParticipants = numberOfParticipants

		return placement
	end)
end

---@param placement AwardPlacement
---@return WidgetTableCell
function AwardPrizePool:placeOrAwardCell(placement)
	local awardCell = TableCell{
		children = {placement.award},
		css = {['font-weight'] = 'bolder'},
		classes = {'prizepooltable-place'},
	}
	awardCell.rowSpan = #placement.opponents

	return awardCell
end

---@param placement AwardPlacement
---@return boolean
function AwardPrizePool:applyCutAfter(placement)
	if (placement.previousTotalNumberOfParticipants + 1) > self.options.cutafter then
		return true
	end
	return false
end

---@param placement AwardPlacement?
---@param nextPlacement AwardPlacement
---@param rows WidgetTableRow[]
function AwardPrizePool:applyToggleExpand(placement, nextPlacement, rows)
	if placement ~= nil
		and (placement.previousTotalNumberOfParticipants + 1) <= self.options.cutafter
		and placement.currentTotalNumberOfParticipants >= self.options.cutafter
		and placement ~= self.placements[#self.placements] then

		table.insert(rows, self:_toggleExpand())
	end
end

---@return WidgetTableRow
function AwardPrizePool:_toggleExpand()
	local expandButton = TableCell{
		children = {'<div>Show more Awards&nbsp;<i class="fa fa-chevron-down"></i></div>'},
		classes = {'general-collapsible-expand-button'},
	}
	local collapseButton = TableCell{
		children = {'<div>Show less Awards&nbsp;<i class="fa fa-chevron-up"></i></div>'},
		classes = {'general-collapsible-collapse-button'},
	}

	return TableRow{classes = {'ppt-toggle-expand'}, children = {expandButton, collapseButton}}
end

-- Get the lpdbObjectName depending on opponenttype
---@param lpdbEntry placement
---@param prizePoolIndex integer|string
---@param lpdbPrefix string?
---@return string
function AwardPrizePool:_lpdbObjectName(lpdbEntry, prizePoolIndex, lpdbPrefix)
	local objectName = 'award'
	if String.isNotEmpty(lpdbPrefix) then
		objectName = objectName .. '_' .. lpdbPrefix
	end

	-- Append the award name in case there is a participant who gets several awards
	objectName = objectName .. '_' .. lpdbEntry.extradata.award

	if lpdbEntry.opponenttype == Opponent.team then
		return objectName .. '_' .. mw.ustring.lower(lpdbEntry.participant)
	end

	-- for non team opponents the pagename can be case sensitive
	-- so objectname needs to be case sensitive to avoid edge cases
	return objectName .. prizePoolIndex .. '_' .. lpdbEntry.participant
end

return AwardPrizePool
