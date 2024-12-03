---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Strarcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Standings = Lua.import('Module:Standings/Base')

---@class StarcraftStandings: BaseStandings
local CustomStandings = Class.new(Standings)

CustomStandings.LINKS_DATA = {
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	interview = {icon = 'File:Interview32.png', text = 'Interview'},
	review = {icon = 'File:Reviews32.png', text = 'Review'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'Live Report Thread'},
	h2h = {icon = 'File:Match Info Stats.png', text = 'Head-to-head statistics'},
}
CustomStandings.LINKS_DATA.preview2 = CustomStandings.LINKS_DATA.preview
CustomStandings.LINKS_DATA.interview2 = CustomStandings.LINKS_DATA.interview
CustomStandings.LINKS_DATA.recap = CustomStandings.LINKS_DATA.review

local DEFAULT_TIEBREAKERS = {
	'dq',
	'points',
	'matchScore',
	'gameScore',
	'ml.matchScore',
	'ml.gameScore',
	'finalTiebreak',
}

---@param frame Frame
---@return Html
function CustomStandings.DisplayStanding(frame)
	local args = Arguments.getArgs(frame)
	return CustomStandings.displayStandingFromLpdb(args)
end

---@param frame Frame
---@return Html
function CustomStandings.DisplayStageStandings(frame)
	local args = Arguments.getArgs(frame)
	return CustomStandings.displayStageStandingsFromLpdb(args)
end

---@param frame Frame
---@return Html
function CustomStandings.GroupTableLeague(frame)
	local args = Arguments.getArgs(frame)
	return CustomStandings.run(args)
end

---@param frame Frame
---@return Html
function CustomStandings.SwissTableLeague(frame)
	local args = Arguments.getArgs(frame)
	args.type = 'swiss'
	return CustomStandings.run(args)
end

---@param args table
---@return Html
function CustomStandings.run(args)
	local standings = CustomStandings(args)

	local startDate = Variables.varDefault('tournament_startdate')
	if (not startDate or '2022-03-20' <= startDate) then
		standings:setDefaultTieBreakers(DEFAULT_TIEBREAKERS)
	end

	return standings:read():process():store():build()
end

return CustomStandings
