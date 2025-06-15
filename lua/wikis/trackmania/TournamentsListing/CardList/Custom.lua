---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Info = require('Module:Info')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')

local CustomTournamentsListing = Class.new()

local DEFAULT_START_YEAR = Info.startYear
local DEFAULT_END_YEAR = tonumber(os.date('%Y'))
local ALLOWED_PLACES = '1,2,1-2,2-3,1-3,1-4,1-5,1-6,1-7,1-8,W,L'
local NON_QUALIFIER = '!Qualifier'

---@param args table
---@return Html?
function CustomTournamentsListing.run(args)
	args = args or {}

	if Logic.readBool(args.byYear) then
		args.byYear = nil
		return CustomTournamentsListing.byYear(args)
	end

	args.game = Game.toIdentifier{game = args.game, useDefault = false}
	args.noLis = true
	args.allowedPlacements = ALLOWED_PLACES
	args.tiertype = args.tiertype or NON_QUALIFIER

	local tournamentsListing = TournamentsListing(args)

	return tournamentsListing:create():build()
end

---@param args table
---@return Html?
function CustomTournamentsListing.byYear(args)
	args = args or {}

	args.order = 'enddate desc'

	local subPageName = mw.title.getCurrentTitle().subpageText
	local fallbackYearData = {}
	if subPageName:find('%d%-%d') then
		fallbackYearData = mw.text.split(subPageName, '-')
	end

	local startYear = tonumber(args.startYear) or tonumber(fallbackYearData[1]) or DEFAULT_START_YEAR
	local endYear = tonumber(args.endYear) or tonumber(fallbackYearData[2]) or DEFAULT_END_YEAR

	local display = mw.html.create()
	for year = endYear, startYear, -1 do
		args.year = year

		local tournaments = CustomTournamentsListing.run(args)
		if tournaments then
			display
				:wikitext('\n===' .. year .. '===\n')
				:node(CustomTournamentsListing.run(args))
		end
	end

	return display
end

return Class.export(CustomTournamentsListing, {exports = {'run', 'byYear'}})
