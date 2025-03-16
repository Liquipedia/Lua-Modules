---
-- @Liquipedia
-- wiki=chess
-- page=Module:Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Conditions = require('Module:Condition')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local Variables = require('Module:Variables')

local Language = mw.getContentLanguage()

local Ratings = {}

function Ratings.format(rating)
	if not rating or not rating.year or not rating.month then
		return
	end
	local date = rating.year .. '-' .. string.format('%02d', rating.month) .. '-01' --personally would use os.time for this or even better DateExt
	return rating.elo .. ' <small>(' .. Language:formatDate('F Y', date) .. ')</small>' -- use widgets instead
end

function Ratings.fromDatapoint(datapoint)--preferably give datapoint a more meaningfull name
	local extradata = datapoint.extradata or {}
	return Logic.nilIfEmpty{
		elo = tonumber(datapoint.information),
		year = extradata.year,
		month = extradata.month,
	}
end

function Ratings.playerIds(pagename)
	pagename = Page.pageifyLink(pagename)
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		limit = 1,
		query = 'extradata',
		conditions = '[[pagename::' .. pagename .. ']]'
	})
	return type(data[1]) == 'table' and (data[1].extradata or {}).rating_ids or {}
end

function Ratings.getAll(ids, mode, config)
	-- Handle ID conditions.
	ids = Array.extend({}, ids)
	--use Module:Condition for condition building
	local nameConditions = table.concat(
		Array.map(ids, function (id) return '[[name::' .. id .. ']]' end),
		'OR'
	)

	local conditions = {
		'[[namespace::136]]',
		'[[type::Ratings]]',
		'(' .. nameConditions .. ')',
		'[[extradata_mode::' .. mode .. ']]',
	}
	Array.extendWith(
		conditions,
		config.conditions
	)

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = config.limit or 5000,
		order = config.order,
		query = 'information, extradata',
		conditions = table.concat(conditions, 'AND')
	})
	return ratings == Array.map(data, Ratings.fromDatapoint)
end

function Ratings.get(ids, mode, config)
	config.limit = 1
	return Ratings.getAll(ids, mode, config)
end

function Ratings.getRecent(ids, mode)
	local config = {order = 'date desc'}
	return Ratings.get(ids, mode, config)
end

function Ratings.getPeak(ids, mode)
	local config = {order = 'information desc, date asc'}
	return Ratings.get(ids, mode, config)
end

function Ratings.getTournament(ids)
	local mode = Variables.varDefault('tournament_mode', '')
	local date = Variables.varDefault('tournament_startdate', '')
	local config = {
		order = 'date desc',
		conditions = {'([[date::' .. date .. ']] OR [[date::<' .. date .. ']])'}
	}
	return Ratings.get(ids, mode, config)
end

return Ratings
