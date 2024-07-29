---
-- @Liquipedia
-- wiki=osu
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class OsuMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local VETOES = {
	[0] = '',
	[1] = 'ban,ban,ban,decider',
	[2] = 'ban,ban,pick,ban',
	[3] = 'ban,pick,ban,decider',
	[5] = 'ban,pick,pick,decider',
	[7] = 'ban,pick,pick,pick,decider',
	[9] = 'ban,pick,pick,pick,pick,decider',
	[11] = 'ban,pick,pick,pick,pick,pick,decider',
	[13] = 'ban,pick,pick,pick,pick,pick,pick,decider',
}

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local indent = '  '
	local showScore = args.score == 'true'
	local mapVeto = args.mapVeto == 'true'
	local protectVeto = args.protect == 'true'
	local streams = args.streams == 'true'
	local casters = args.casters == 'true'
	local mplinks = args.mplinks == 'true'
	local lines = {}
	table.insert(lines, '{{Match|bestof=' .. bestof)
	table.insert(lines, indent .. '|date=')

	if casters then
		table.insert(lines, indent .. '|caster1=|caster2=')
	end

	if streams then
		table.insert(lines, indent .. '|twitch=|youtube=|vod=')
	end

	if mplinks then
		table.insert(lines, indent .. '|mplink=|mplink2=|mplink3=')
	end

	for i = 1, opponents do
		table.insert(lines, indent .. '|opponent' .. i .. '=' .. WikiCopyPaste._getOpponent(mode, showScore))
	end

	if mapVeto and VETOES[bestof] then
		local types = VETOES[bestof]
		if protectVeto then
			types = 'protect,' .. types
		end

		local vetotypes = mw.text.split(types, ',', true)
		table.insert(lines, indent .. '|mapveto={{MapVeto')
		table.insert(lines, indent .. indent .. '|firstpick=')
		table.insert(lines, indent .. indent .. '|types=' .. types)
		Array.forEach(vetotypes,
			function(vetotype, index)
				if vetotype == 'protect' or vetotype == 'ban' or vetotype == 'pick' then
					table.insert(lines, indent .. indent .. '|t1map' .. index .. '=|t2map' .. index .. '=')
				elseif vetotype == 'decider' then
					table.insert(lines, indent .. indent .. '|decider=')
				end
			end
		)
		table.insert(lines, indent .. '}}')
	end
	for i = 1, bestof do
		table.insert(lines, indent .. '|map' .. i .. '={{Map|map=|mode=|score1=|score2=|winner=')
		lines[#lines] = lines[#lines] .. '}}'
	end
	table.insert(lines,'}}')

	return table.concat(lines, '\n')
end

--subfunction used to generate the code for the Opponent template, depending on the type of opponent
function WikiCopyPaste._getOpponent(mode, showScore)
	local score = showScore and '|score=' or ''

	if mode == 'team' then
		return '{{TeamOpponent|' .. score .. '}}'
	elseif mode == 'solo' then
		return '{{SoloOpponent||flag=' .. (score or '') .. '}}'
	elseif mode == 'literal' then
		return '{{LiteralOpponent|}}'
	end
end

return WikiCopyPaste
