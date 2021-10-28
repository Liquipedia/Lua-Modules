local String = require('Module:String')
local Variables = require('Module:Variables')
local LinkIcons = require('Module:MatchExternalLinks/Starcraft')

local Custom = {
	parseOpponentInput = {},
	display = {},
}

--functions to get the display
function Custom.display.solo(opp)
	error('You need to specify "Custom.display" vis "Module:Module:GroupTableLeague/Custom"')
end

function Custom.display.team(opp, date)
	error('You need to specify "Custom.display" vis "Module:Module:GroupTableLeague/Custom"')
end

--functions to parse opponent input
function Custom.parseOpponentInput.solo(param, opponentIndex, opponentArg, args, opponents)
	local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args[param .. opponentIndex .. 'link'] or
		Variables.varDefault(opponentArg .. '_page', opponentArg)
	)

	opponentListEntry = {
		opponent = opponent,
		opponentArg = opponentArg,
		flag = args[param .. opponentIndex .. 'flag'] or Variables.varDefault(opponentArg .. '_flag', ''),
		note = args[param .. opponentIndex .. 'note'] or args[param .. opponentIndex .. 'note'] or '',
	}

	opponents[#opponents + 1] = opponent

	local aliasList = mw.text.split(args[param .. opponentIndex .. 'alias'] or '', ',')

	return opponentListEntry, aliasList, opponents
end

function Custom.parseOpponentInput.team(param, opponentIndex, opponentArg, args, opponents)
	local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
		TeamTemplates._teampage((opponentArg or '') ~= '' and opponentArg or 'tbd')
	)

	opponentListEntry = {
		opponent = opponent,
		opponentArg = opponentArg,
	}

	opponents[#opponents + 1] = opponent

	local aliasList = mw.text.gsplit(args[param .. opponentIndex .. 'alias'] or '', ',')

	return opponentListEntry, aliasList, opponents
end

--function to determine the following from args.type
----tableType (determines the display of the opponents)
----mode (used in the lpdb query conditions)
local _DEFAULT_TYPE = 'team'
local _TYPE_TO_MODE = {
	['solo'] = 'solo',
	['team'] = 'team',
}
local _ALLOWED_TYPES = {
	['solo'] = 'solo',
	['team'] = 'team',
}
local _TYPE_TO_PARAMS = {
	['solo'] = {'player', 'p'},
	['team'] = {'team', 't'},
}
function Custom.convertType(tableType)
	tableType = _ALLOWED_TYPES[string.lower(tableType or _DEFAULT_TYPE)] or _DEFAULT_TYPE
	return tableType, _TYPE_TO_MODE[tableType], _TYPE_TO_PARAMS[tableType]
end

function Custom.lpdbConditions(args, opponents, mode, baseConditions, dateConditions)
	local lpdbConditions = baseConditions

	local oppConditions = ''
	if type(opponents) == 'table' and opponents[1] then
		local oppNumber = #opponents
		oppConditions = oppConditions .. 'AND ('
		for key = 1, oppNumber - 1 do
			for key2 = key + 1, oppNumber do
				if key > 1 or key2 > 2 then
					oppConditions = oppConditions .. ' OR '
				end
				oppConditions = oppConditions .. '[[opponent::' .. opponents[key] .. ']] AND [[opponent::' .. opponents[key2] .. ']]'
			end
		end
		oppConditions = oppConditions .. ') '
	end

	if not String.isEmpty(dateConditions) then
		lpdbConditions = lpdbConditions .. dateConditions
	end

	if not String.isEmpty(oppConditions) then
		lpdbConditions = lpdbConditions .. oppConditions
	end

	return lpdbConditions, baseConditions
end

function Custom.getHeaderIcons(args)
	local links = {
		preview = args.preview,
		lrthread = args.lrthread,
		vod = args.vod,
		vod1 = args.vod1,
		vod2 = args.vod2,
		vod3 = args.vod3,
		vod4 = args.vod4,
		vod5 = args.vod5,
		vod6 = args.vod6,
		vod7 = args.vod7,
		vod8 = args.vod8,
		vod9 = args.vod9,
		interview = args.interview,
		interview2 = args.interview2,
		interview3 = args.interview3,
		interview4 = args.interview4,
		recap = args.recap,
		review = args.review
	}
	if #links > 0 then
		return mw.html.create('span')
			:addClass('plainlinks vodlink')
			:css('float', 'right')
			:node(LinkIcons.MatchExternalLinks({links = links}))
	end
	return ''
end

return Custom
