---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsListing/CardList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Conditions = Lua.import('Module:TournamentsListing/Conditions')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local DEFAULT_ALLOWED_PLACES = '1,2,1-2,2-3,W,L'
local DEFAULT_LIMIT = 5000

--- @class BaseTournamentsListing
--- @operator call(...): BaseTournamentsListing
local BaseTournamentsListing = Class.new(function(self, ...) self:init(...) end)

---@param args table
---@return self
function BaseTournamentsListing:init(args)
	self.args = args

	self:readConfig()

	return self
end

function BaseTournamentsListing:readConfig()
	local args = self.args
	self.config = {
		useParent = Logic.nilOr(Logic.readBoolOrNil(args.useParent), true),
		allowedPlacements = self:_allowedPlacements(),
	}
end

---@return string[]
function BaseTournamentsListing:_allowedPlacements()
	local placeConditions = self.args.placeConditions or DEFAULT_ALLOWED_PLACES

	return Array.map(mw.text.split(placeConditions, ','), String.trim)
end

---@return self
function BaseTournamentsListing:create()
	local data = self.args.data or self:_query()
	if Table.isNotEmpty(data) then
		self.data = data
	end
	for _, rowData in ipairs(self.data) do
		self.placements = self:_fetchPlacementData(rowData)
	end

	return self
end

---@return table
function BaseTournamentsListing:_query()
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = self:_buildConditions(),
		query = 'pagename, name, icon, icondark, organizers, startdate, enddate, status, locations, series, '
			.. 'prizepool, participantsnumber, game, liquipediatier, liquipediatiertype, extradata, publishertier, type',
		order = self.args.order,
		limit = self.args.limit or DEFAULT_LIMIT,
		offset = self.config.offset,
	})
end

---@return string
function BaseTournamentsListing:_buildConditions()

	local conditions = Conditions.base(self.args)

	if self.args.additionalConditions then
		return conditions .. self.args.additionalConditions
	end

	return conditions
end

---@param tournamentData table
---@return {qualified: table[]?, [1]: table[]?, [2]: table[]?}
function BaseTournamentsListing:_fetchPlacementData(tournamentData)
	local placements = {}

	local conditions = Conditions.placeConditions(tournamentData, self.config)
			.. (self.args.additionalPlaceConditions or '')

	local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions,
		query = 'opponentname, opponenttype, opponenttemplate, opponentplayers, placement, extradata',
		order = 'placement asc',
		limit = 50,
	})

	if self.config.showQualifierColumnOverWinnerRunnerup then
		if Table.isEmpty(queryData) then
			return {qualified = {Opponent.tbd(Opponent.team)}}
		end
		return {qualified = Array.map(queryData, Opponent.fromLpdbStruct)}
	end

	for _, item in ipairs(queryData) do
		local place = tonumber(mw.text.split(item.placement, '-')[1])
		if not place and item.placement == 'W' then
			place = 1
		elseif not place and item.placement == 'L' then
			place = 2
		end

		if place then
			if not placements[place] then
				placements[place] = {}
			end

			local opponent = Opponent.fromLpdbStruct(item)
			if not opponent then
				mw.logObject({pageName = tournamentData.pagename, place = item.placement},
					'Invalid Prize Pool Data returned from')
			elseif Opponent.isTbd(opponent) then
				opponent = Opponent.tbd(Opponent.team)
			end
			table.insert(placements[place], opponent)
		end
	end

	if Table.isEmpty(placements[1]) then
		placements[1] = {Opponent.tbd(Opponent.team)}
	end

	if Table.isEmpty(placements[2]) then
		placements[2] = {Opponent.tbd(Opponent.team)}
	end

	return placements
end


return BaseTournamentsListing
