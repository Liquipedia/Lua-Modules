local wikiCopyPaste = require('Module:GetMatchGroupCopyPaste/wiki/Base')

--allowed opponent types on the wiki
local MODES = { ['solo'] = 'solo', ['team'] = 'team' }

--default opponent type (used if the entered mode is not found  in the above table)
local DefaultMode = 'team'

--returns the cleaned opponent type
function wikiCopyPaste.getMode(mode)
	return MODES[string.lower(mode or '')] or DefaultMode
end

--subfunction used to generate the code for the Map template
--sets up as many maps as specified via the bestoff param
function wikiCopyPaste._getMaps(bestof)
	local map = '{{Map\n\t\t|map=\n\t\t|score1=|score2=\n\t\t|ot=|otlength=\n\t\t|vod=\n\t}}'
	local out = ''
	for _ = 1, bestof do
		out = out .. '\t' .. map .. '\n'
	end

	out = out .. '\t|finished=\n\t|date=\n'

	return out
end

--returns the Code for a Match, depending on the input
--for more customization please change stuff here^^
function wikiCopyPaste.getMatchCode(bestof, mode, index,  opponents, args)
	local out = tostring(mw.message.new('BracketConfigMatchTemplate'))
	if out == '⧼BracketConfigMatchTemplate⧽' then
		out = '{{Match\n\t'
		for i = 1, opponents do
			out = out .. '\n\t|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode)
		end
		out = out .. '\n\t|finished=\n\t|tournament=\n\t}}'
	else
		out = string.gsub(out, '<nowiki>', '')
		out = string.gsub(out, '</nowiki>', '')
		for i = 1, opponents do
			out = string.gsub(out, '|opponent' .. i .. '=' , '|opponent' .. i .. '=' .. wikiCopyPaste._getOpponent(mode))
		end

		out = string.gsub(out, '|map1=.*\n' , '<<maps>>')
		out = string.gsub(out, '|map%d+=.*\n' , '')
		out = string.gsub(out, '<<maps>>' , wikiCopyPaste._getMaps(bestof))
	end

	return out .. '\n'
end

return wikiCopyPaste
