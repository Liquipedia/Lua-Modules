local MatchGroupDisplay = {}

function MatchGroupDisplay.bracket(frame)
	local args = require('Module:Arguments').getArgs(frame)
	return MatchGroupDisplay.luaBracket(frame, args)
end

function MatchGroupDisplay.customBracket(frame, args, matches)
	if not args then
		args = require('Module:Arguments').getArgs(frame)
	end
	if not matches or #matches == 0 then
		args[1] = args.id or args[1] or ''

		local MatchGroupUtil = require('Module:MatchGroup/Util')
		matches = MatchGroupUtil.fetchMatches(args[1])
		if #matches == 0 then
			error('No Data found for bracketId=' .. args[1])
		end
	end

	if (args.title or '') ~= '' then
		matches[1].bracketData.title = args.title
	end

	for ind, match in ipairs(matches) do
		local matchId = string.gsub(match.matchId, args[1] .. '_', '')
		local round, matchInRound = string.match(matchId, '^R(%d+)%-M(%d+)$')
		round = tonumber(round or '')
		matchInRound = tonumber(matchInRound or '')
		if round and matchInRound then
			matchId = 'R' .. round .. 'M' .. matchInRound
			if (args[matchId .. 'header'] or '') ~= '' then
				matches[ind].bracketData.header = args[matchId .. 'header']
			end
		end
	end

	return MatchGroupDisplay.luaBracket(frame, args, matches)
end

function MatchGroupDisplay.luaBracket(frame, args, matches)
	mw.log("drawing from lua")
	local BracketDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('bracket')
	return BracketDisplay.luaGet(frame, args, matches)
end

function MatchGroupDisplay.matchlist(frame)
	local args = require('Module:Arguments').getArgs(frame)
	return MatchGroupDisplay.luaMatchlist(frame, args)
end

function MatchGroupDisplay.customMatchlist(frame, args, matches)
	if not args then
		args = require('Module:Arguments').getArgs(frame)
	end
	if not matches or #matches == 0 then
		args[1] = args.id or args[1] or ''

		local MatchGroupUtil = require('Module:MatchGroup/Util')
		matches = MatchGroupUtil.fetchMatches(args[1])
		if #matches == 0 then
			error('No Data found for bracketId=' .. args[1])
		end
	end

	if (args.title or '') ~= '' then
		matches[1].bracketData.title = args.title
	end

	for ind, _ in ipairs(matches) do
		if (args['M' .. ind .. 'header'] or '') ~= '' then
			matches[ind].bracketData.header = args['M' .. ind .. 'header']
		end
	end

	return MatchGroupDisplay.luaMatchlist(frame, args, matches)
end

function MatchGroupDisplay.customMatchlistHeaderFromDate(frame)
	local countdown = require('Module:Countdown')._create
	local args = require('Module:Arguments').getArgs(frame)
	args[1] = args.id or args[1] or ''
	local bracketId = args[1]

	local MatchGroupUtil = require('Module:MatchGroup/Util')
	local matches = MatchGroupUtil.fetchMatches(bracketId)
	if #matches == 0 then
		error('No Data found for bracketId=' .. bracketId)
	end

	if (args.title or '') ~= '' then
		matches[1].bracketData.title = args.title
	end

	for ind, _ in ipairs(matches) do
		if (matches[ind].bracketData.header or '') == '' then
			matches[ind].bracketData.header = countdown({
				date = matches[ind].date,
				finished = tostring(matches[ind].finished or '')
			})
		end
	end

	return MatchGroupDisplay.luaMatchlist(frame, args, matches)
end

function MatchGroupDisplay.luaMatchlist(frame, args, matches)
	local MatchlistDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('matchlist')
	return MatchlistDisplay.luaGet(frame, args, matches)
end

-- display MatchGroup (Bracket/MatchList) from ID
function MatchGroupDisplay.Display(frame)
	local args = require('Module:Arguments').getArgs(frame)
	args[1] = args.id or args[1] or ''
	local bracketId = args[1]

	local MatchGroupUtil = require('Module:MatchGroup/Util')
	local matches = MatchGroupUtil.fetchMatches(bracketId)
	if #matches == 0 then
		error('No Data found for bracketId=' .. bracketId)
	end
	local matchGroupType = matches[1].bracketData.type

	local MatchGroupModule = require('Module:Brkts/WikiSpecific').getMatchGroupModule(matchGroupType)
	return MatchGroupModule.luaGet(frame, args)
end

function MatchGroupDisplay.DisplayDev(frame)
	require('Module:DevFlags').matchGroupDev = true
	return MatchGroupDisplay.Display(frame)
end

return MatchGroupDisplay
