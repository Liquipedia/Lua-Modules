local Arguments = require('Module:Arguments')
local DateExt = require('Module:Date/Ext')
local Countdown = require('Module:Countdown')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local NextMatch = {}

function NextMatch.run(frame)
	local args = Arguments.getArgs(frame)

	if not args[1] then return args.default or '' end

	local pageConditions = {}
	for _, page in ipairs(args) do
		page = page:gsub(' ', '_')
		table.insert(pageConditions, '[[pagename::' .. page .. ']]')
	end

	local now = os.time(os.date("!*t"))
	local yesterday = now - 24 * 3600

	local conditions = {
		'[[finished::0]]',
		'[[date::>' .. yesterday .. ']]',
		'(' .. table.concat(pageConditions, ' OR ') .. ')',
	}

	if not Logic.readBool(args.notExact) then
		table.insert(conditions, '[[dateexact::1]]')
	end

	local match = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = table.concat(conditions, ' AND '),
		query = 'date, stream',
		order = 'date asc',
		limit = 1,
	})[1] or {}

	-- fallback for wikis still not having match2 (e.g. formula1)
	if Logic.isEmpty(match) then
		match = mw.ext.LiquipediaDB.lpdb('match', {
			conditions = table.concat(conditions, ' AND '),
			query = 'date, stream',
			order = 'date asc',
			limit = 1,
		})[1] or {}
	end

	if not match.date then return args.default or '' end

	local countdownArgs = {}
	if Logic.readBool(args.showStreams) then
		countdownArgs = match.stream or {}
	end
	Table.mergeInto(countdownArgs, args)
	countdownArgs.date = DateExt.toCountdownArg(match.date)
	countdownArgs.rawcountdown = true

	if Logic.readBool(args.matchWrapper) then
		return mw.html.create('span')
			:addClass('match-countdown')
			:wikitext(Countdown._create(countdownArgs))
	end

	return Countdown._create(countdownArgs)
end

return NextMatch
