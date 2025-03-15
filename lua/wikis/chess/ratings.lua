local Array = require('Module:Array')
local Variables = require('Module:Variables')

local Language = mw.language.new('en')

local p = {}

function p.format(rating)
	if rating then
		local date = rating.year .. '-' .. string.format('%02d', rating.month) .. '-01'
		return rating.elo .. ' <small>(' .. Language:formatDate('F Y', date) .. ')</small>'
	end
end

function p.fromDatapoint(datapoint)
	return {
		elo = tonumber(datapoint.information),
		year = datapoint.extradata.year,
		month = datapoint.extradata.month,
	}
end

function p.playerIds(pagename)
	pagename = pagename:gsub(' ', '_')
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		limit = 1,
		query = 'extradata',
		conditions = '[[pagename::' .. pagename .. ']]'
	})
	return #data == 1 and data[1].extradata.rating_ids or {}
end

function p.getAll(ids, mode, config)
	-- Handle ID conditions.
	if type(ids) ~= 'table' then
		ids = {ids}
	elseif #ids == 0 then
		return {}
	end
	local nameConditions = table.concat(
		Array.map(ids, function (id, _) return '[[name::' .. id .. ']]' end),
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
	local ratings = Array.map(data, p.fromDatapoint)
	return ratings
end

function p.get(ids, mode, config)
	config.limit = 1
	return p.getAll(ids, mode, config)[1]
end

function p.getRecent(ids, mode)
	local config = {order = 'date desc'}
	return p.get(ids, mode, config)
end

function p.getPeak(ids, mode)
	local config = {order = 'information desc, date asc'}
	return p.get(ids, mode, config)
end

function p.getTournament(ids)
	local mode = Variables.varDefault('tournament_mode', '')
	local date = Variables.varDefault('tournament_startdate', '')
	local config = {
		order = 'date desc',
		conditions = {'([[date::' .. date .. ']] OR [[date::<' .. date .. ']])'}
	}
	return p.get(ids, mode, config)
end

return p
