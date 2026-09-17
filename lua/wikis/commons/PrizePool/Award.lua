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
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local BasePrizePool = Lua.import('Module:PrizePool/Base')
local Placement = Lua.import('Module:PrizePool/Award/Placement')

local Opponent = Lua.import('Module:Opponent/Custom')

local ReferenceTag = Lua.import('Module:Widget/ReferenceTag')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local TableCell = TableWidgets.Cell

--- @class AwardPrizePool: BasePrizePool
--- @operator call(...): AwardPrizePool
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

---@protected
---@param placement AwardPlacement
---@return Renderable
function AwardPrizePool:placeOrAwardCell(placement)
	---@return Renderable|Renderable[]
	local function buildChildren()
		local references = placement.references
		if Table.isEmpty(references) then
			return placement.award
		end
		---@cast references -nil
		local frame = mw.getCurrentFrame()
		return Array.extend(
			placement.award,
			Array.map(references, function (reference)
				return ReferenceTag{
					frame = frame,
					name = Table.extract(reference, 'name'),
					children = Template.safeExpand(frame, 'Cite web', reference)
				}
			end)
		)
	end

	return TableCell{
		children = buildChildren(),
		classes = {'prizepooltable-place'},
		rowspan = #placement.opponents,
	}
end

---@protected
---@param placement AwardPlacement
---@return boolean
function AwardPrizePool:applyCutAfter(placement)
	return (placement.previousTotalNumberOfParticipants + 1) > self.options.cutafter
end

---@protected
---@return {opentext: string, closetext: string}?
function AwardPrizePool:_collapseText()
	return {opentext = 'Show more Awards', closetext = 'Show less Awards'}
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
