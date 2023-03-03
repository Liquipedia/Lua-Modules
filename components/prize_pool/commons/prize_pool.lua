---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Import = Lua.import('Module:PrizePool/Import', {requireDevIfEnabled = true})
local BasePrizePool = Lua.import('Module:PrizePool/Base', {requireDevIfEnabled = true})
local Placement = Lua.import('Module:PrizePool/Placement', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

local TableCell = require('Module:Widget/Table/Cell')
local TableRow = require('Module:Widget/Table/Row')

--- @class PrizePool
local PrizePool = Class.new(BasePrizePool)

local tournamentVars = PageVariableNamespace('Tournament')

local NON_BREAKING_SPACE = '&nbsp;'

-- Allowed none-numeric score values.
local WALKOVER_SCORE = 'W'
local FORFEIT_SCORE = 'FF'
local SPECIAL_SCORES = {WALKOVER_SCORE, FORFEIT_SCORE , 'L', 'DQ', 'D'}

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

function PrizePool:placeOrAwardCell(placement)
	local placeCell = TableCell{
		content = {{placement:getMedal() or '', NON_BREAKING_SPACE, placement:_displayPlace()}},
		css = {['font-weight'] = 'bolder'},
		classes = {'prizepooltable-place'},
	}
	placeCell.rowSpan = #placement.opponents

	return placeCell
end

function PrizePool:applyCutAfter(placement, row)
	if placement.placeStart > self.options.cutafter then
		row:addClass('ppt-hide-on-collapse')
	end
end

function PrizePool:applyToggleExpand(placement, rows)
	if placement.placeStart <= self.options.cutafter
		and placement.placeEnd >= self.options.cutafter
		and placement ~= self.placements[#self.placements] then

		table.insert(rows, self:_toggleExpand(placement.placeEnd + 1, self.placements[#self.placements].placeEnd))
	end
end

function PrizePool:_toggleExpand(placeStart, placeEnd)
	local text = 'place ' .. placeStart .. ' to ' .. placeEnd
	local expandButton = TableCell{content = {'<div>' .. text .. '&nbsp;<i class="fa fa-chevron-down"></i></div>'}}
		:addClass('general-collapsible-expand-button')
	local collapseButton = TableCell{content = {'<div>' .. text .. '&nbsp;<i class="fa fa-chevron-up"></i></div>'}}
		:addClass('general-collapsible-collapse-button')

	return TableRow{classes = {'ppt-toggle-expand'}}:addCell(expandButton):addCell(collapseButton)
end

function PrizePool:storeSmw(lpdbEntry, smwTournamentStash)
	local smwEntry = self:_lpdbToSmw(lpdbEntry)

	if self._smwInjector then
		smwEntry = self._smwInjector:adjust(smwEntry, lpdbEntry)
	end

	local count = (tonumber(tournamentVars:get('smwRecords.count')) or 0) + 1
	tournamentVars:set('smwRecords.count', count)
	tournamentVars:set('smwRecords.' .. count .. '.id', Table.extract(smwEntry, 'objectName'))
	tournamentVars:set('smwRecords.' .. count .. '.data', Json.stringify(smwEntry))

	local place = smwEntry['has placement']
	if place and not Placement.specialStatuses[string.upper(place)] then
		local key = 'has '
		if String.isNotEmpty(self.options.lpdbPrefix) then
			key = key .. self.options.lpdbPrefix .. ' '
		end
		place = mw.text.split(place, '-')[1]
		key = key .. Template.safeExpand(mw.getCurrentFrame(), 'OrdinalWritten/' .. place, {}, '')
		if lpdbEntry.opponentindex ~= 1 then
			key = key .. lpdbEntry.opponentindex
		end
		key = key .. ' place page'

		smwTournamentStash[key] = lpdbEntry.participant
	end

	return smwTournamentStash
end

function PrizePool:_lpdbToSmw(lpdbData)
	local smwOpponentData = {}
	if lpdbData.opponenttype == Opponent.team then
		smwOpponentData['has team page'] = lpdbData.participant
	elseif lpdbData.opponenttype == Opponent.literal then
		smwOpponentData['has literal team'] = lpdbData.participant
	elseif lpdbData.opponenttype == Opponent.solo then
		local playersData = Json.parseIfString(lpdbData.players) or {}
		smwOpponentData = {
			['has player id'] = lpdbData.participant,
			['has player page'] = lpdbData.participantlink,
			['has flag'] = lpdbData.participantflag,
			['has team page'] = playersData.p1team,
			['has team'] = playersData.p1team,
		}
	end

	local scoreData = {
		['has last wdl'] = lpdbData.groupscore,
	}
	if Table.includes(SPECIAL_SCORES, lpdbData.lastscore) then
		if lpdbData.lastscore == WALKOVER_SCORE then
			scoreData['has walkover from'] = lpdbData.lastvs
		elseif lpdbData.lastscore == FORFEIT_SCORE then
			scoreData['has walkover to'] = lpdbData.lastvs
		end
	else
		scoreData['has last score'] = lpdbData.lastscore
		scoreData['has last opponent score'] = lpdbData.lastvsscore
	end

	return Table.mergeInto({
			objectName = lpdbData.objectName,

			['has tournament page'] = lpdbData.parent,
			['has tournament name'] = lpdbData.tournament,
			['has tournament type'] = lpdbData.type,
			['has tournament series'] = lpdbData.series,
			['has icon'] = lpdbData.icon,
			['is result type'] = lpdbData.mode,
			['has game'] = lpdbData.game,
			['has date'] = lpdbData.date,
			['is tier'] = lpdbData.liquipediatier,
			['has placement'] = lpdbData.placement,
			['has prizemoney'] = lpdbData.prizemoney,
			['has last opponent'] = lpdbData.lastvs,
			['has weight'] = lpdbData.weight,
		},
		smwOpponentData,
		scoreData
	)
end

-- get the lpdbObjectName depending on opponenttype
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
