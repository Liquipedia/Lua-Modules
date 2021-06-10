local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local LuaUtils = require('Module:LuaUtils')
local Table = require('Module:Table')

local DisplayHelper = {}

-- flattens a table so that nested tables become keys of the root table
-- this is required for Module:MatchSummary and Module:OpponentDisplay, as they
-- expect flattened input
-- a '_' (underscore) shows a key originates from a nested table
-- e.g. { key1 = { key2 = val } } becomes { key1_key2 = val }
-- Deprecated
function DisplayHelper.flattenArgs(args, prefix)
	local out = {}
	prefix = prefix or ''
	for key, val in pairs(args) do
		if tonumber(key) ~= nil then
			if LuaUtils.string.endsWith(prefix, 's_') then
				prefix = prefix:sub(1, prefix:len() - 2)
			end
		end
		if type(val) == 'table' then
			local newArgs = DisplayHelper.flattenArgs(val, prefix .. key .. '_')
			for newKey, newVal in pairs(newArgs) do
				out[newKey] = newVal
			end
		else
			out[prefix .. key] = tostring(val)
		end
	end
	return out
end

function DisplayHelper.opponentIsTBD(opponent)
	return opponent.type == 'literal'
		or opponent.type == 'team' and opponent.template == 'tbd'
		or opponent.name == 'TBD'
		or Array.any(opponent.players, function(player) return player.name == 'TBD' end)
end

-- Whether to allow highlighting an opponent via mouseover
function DisplayHelper.opponentIsHighlightable(opponent)
	if opponent.type == 'literal' then
		return opponent.name and opponent.name ~= 'TBD' or false
	elseif opponent.type == 'team' then
		return opponent.template and opponent.template ~= 'tbd' or false
	else
		return 0 < #opponent.players
	end
end

--[[
Builds a hash of the opponent that is used to visually highlight their progress 
in the bracket. 
]]
function DisplayHelper.makeOpponentHighlightKey2(opponent)
	if opponent.type == 'literal' then
		return opponent.name and string.lower(opponent.name) or ''
	elseif opponent.type == 'team' then
		return opponent.template or ''
	else
		return table.concat(Array.map(opponent.players or {}, function(player) return player.pageName or '' end), ',')
	end
end

-- Expands a header code by making a RPC call. 
function DisplayHelper.expandHeaderCode(headerCode)
	headerCode = headerCode:gsub('$', '!')
	local args = mw.text.split(headerCode, '!')
	local response = mw.message.new('brkts-header-' .. args[2])
		:params(args[3] or '')
		:plain()
	return mw.text.split(response, ',')
end

--[[ 
Expands a header code or comma demlimited string into an array of header texts 
of different lengths. Used for displaying different header texts depending on 
the screen width.

Examples:
DisplayHelper.expandHeader('!ux!2') -- returns {'Upper Semi-Finals', 'UB SF'}
DisplayHelper.expandHeader('Qualified,Qual.,Q') -- returns {'Qualified', 'Qual.', 'Q'}
]]
function DisplayHelper.expandHeader(header)
	local isCode = Table.includes({'$', '!'}, header:sub(1, 1))
	return isCode
		and DisplayHelper.expandHeaderCode(header) 
		or mw.text.split(header, ',')
end

--[[
Determines whether a match summary popup shall be enabled for a match.

This is the default policy for Bracket and Matchlist. Wikis may specify a 
different policy by setting props.matchHasDetails in the Bracket and Matchlist 
components.
]]
function DisplayHelper.defaultMatchHasDetails(match)
	return match.dateIsExact or 0 < #match.games
end

--[[
Display component showing the detailed summary of a match. The component will 
appear as a popup from the Matchlist and Bracket components. This is a 
container component, so it takes in the match ID and bracket ID as inputs, 
which it uses to fetch the match data from LPDB and page variables.

This is the default implementation. Specific wikis may override this by passing 
in a different props.MatchSummaryContainer in the Bracket and Matchlist 
components.
]]
DisplayHelper.DefaultMatchSummaryContainer = function(props)
	local DevFlags = require('Module:DevFlags')
	local MatchSummaryModule = DevFlags.matchGroupDev and LuaUtils.lua.requireIfExists('Module:MatchSummary/dev')
		or require('Module:MatchSummary')

	if MatchSummaryModule.getByMatchId then
		return MatchSummaryModule.getByMatchId(props)
	else
		error('DefaultMatchSummaryContainer: Expected MatchSummary.getByMatchId to be a function')
	end
end

--[[
Retrieves the wiki specific global bracket config specified in 
MediaWiki:BracketConfig.
]]
DisplayHelper.getGlobalConfig = FnUtil.memoize(function()
	local defaultConfig = {
		headerHeight = 25,
		headerMargin = 8,
		lineWidth = 2,
		matchHeight = 44, -- deprecated
		matchWidth = 150,
		matchWidthMobile = 90,
		opponentHeight = 23,
		roundHorizontalMargin = 20,
		scoreWidth = 20,
	}
	local rawConfig = Json.parse(tostring(mw.message.new('BracketConfig')))
	local config = {}
	for paramName, defaultValue in pairs(defaultConfig) do
		config[paramName] = tonumber(rawConfig[paramName]) or defaultValue
	end
	return config
end)

return DisplayHelper
