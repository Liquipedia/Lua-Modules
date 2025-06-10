---
-- @Liquipedia
-- page=Module:GetMatchGroupCopyPaste/wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BaseCopyPaste = Lua.import('Module:GetMatchGroupCopyPaste/wiki/Base')

---@class OsuMatch2CopyPaste: Match2CopyPasteBase
local WikiCopyPaste = Class.new(BaseCopyPaste)

local INDENT = BaseCopyPaste.Indent
local VETOES = {
	[5] = {'ban', 'pick', 'pick', 'decider'},
	[7] = {'ban', 'pick', 'pick', 'pick', 'decider'},
	[9] = {'ban', 'pick', 'pick', 'pick', 'pick', 'decider'},
	[11] = {'ban', 'pick', 'pick', 'pick', 'pick', 'pick', 'decider'},
	[13] = {'ban', 'pick', 'pick', 'pick', 'pick', 'pick', 'pick', 'decider'},
}

--returns the Code for a Match, depending on the input
---@param bestof integer
---@param mode string
---@param index integer
---@param opponents integer
---@param args table
---@return string
function WikiCopyPaste.getMatchCode(bestof, mode, index, opponents, args)
	local lines = Array.extend({},
		'{{Match|bestof=' .. bestof,
		INDENT .. '|date=',
		Logic.readBool(args.casters) and (INDENT .. '|caster1=|caster2=') or nil,
		Logic.readBool(args.streams) and (INDENT .. '|twitch=|youtube=|vod=') or nil,
		Logic.readBool(args.mplinks) and (INDENT .. '|mplink=|mplink2=|mplink3=') or nil,
		Array.map(Array.range(1, opponents), function(opponentIndex)
			return INDENT .. '|opponent' .. opponentIndex .. '=' .. BaseCopyPaste.getOpponent(mode, Logic.readBool(args.score))
		end),
		WikiCopyPaste._getVetoes(args, bestof),
		Array.map(Array.range(1, bestof), function(mapIndex)
			return INDENT .. '|map' .. mapIndex .. '={{Map|map=|mode=|score1=|score2=|winner=}}'
		end),
		'}}'
	)

	return table.concat(lines, '\n')
end

---@param args table
---@param bestof integer
---@return string[]?
function WikiCopyPaste._getVetoes(args, bestof)
	if not Logic.readBool(args.mapVeto) or not VETOES[bestof] then return nil end
	local vetoTypes = Array.extend(Logic.readBool(args.protect) and 'protect' or nil, VETOES[bestof])

	return Array.extend({},
		INDENT .. '|mapveto={{MapVeto',
		INDENT .. INDENT .. '|firstpick=',
		INDENT .. INDENT .. '|types=' .. table.concat(vetoTypes, ','),
		Array.map(vetoTypes, function(vetoType, vetoIndex)
			if vetoType == 'decider' then
				return INDENT .. INDENT .. '|decider='
			end
			return INDENT .. INDENT .. '|t1map' .. vetoIndex .. '=|t2map' .. vetoIndex .. '='
		end),
		INDENT .. '}}'
	)
end

return WikiCopyPaste
