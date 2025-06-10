---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local TeamRanking = require('Module:TeamRanking')

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class RocketleagueInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	team.args.rating, team.args.ratingRank = CustomTeam.fetchRating(team.pagename)

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{
				name = '[[Portal:Rating|LPRating]]',
				content = {
					args.rating and args.ratingRank and math.floor(args.rating + 0.5) .. ' (Rank #'.. args.ratingRank ..')'
						or 'Not enough data'
				}
			},
			Cell{
				name = '[[RankingTableRLCS|RLCS Points]]',
				content = {TeamRanking.run{
					ranking = args.ranking_name,
					team = self.caller.pagename
				}}
			}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.rating = self.args.rating
	lpdbData.extradata.tier = string.lower(args.tier or '')

	return lpdbData
end

---@param findTeam string
---@return number?
---@return integer?
function CustomTeam.fetchRating(findTeam)
	local latestSnap = mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'extradata',
			limit = 1,
			order = 'date DESC',
			conditions = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]] AND [[name::rating]]'
		}
	)[1]
	if not latestSnap then
		return
	end

	if not latestSnap.extradata.table[findTeam] then
		return
	end

	for rank, team in ipairs(latestSnap.extradata.ranks) do
		if team == findTeam then
			return latestSnap.extradata.table[findTeam].rating, rank
		end
	end
end

return CustomTeam
