local Matchlist = {}

local DisplayHelper = require("Module:MatchGroup/Display/Helper")
local OpponentDisplay = require("Module:OpponentDisplay")
local MatchSummary = require("Module:MatchSummary")
local Json = require("Module:Json")
local HasDetails = require("Module:Brkts/WikiSpecific").matchHasDetails

local getArgs = require("Module:Arguments").getArgs
local utils = require("Module:LuaUtils")
local html = mw.html

local _frame

function Matchlist.get(frame)
	local args = getArgs(frame)
	
	local bracketid = args[1];
	
	local matches = _getMatches(bracketid)
	
	return Matchlist.luaGet(frame, args, matches)
end

-- draw the table
function Matchlist.luaGet(frame, args, matches)
	_frame = frame
	
	if not matches then
		local bracketid = args[1]
		matches = _getMatches(bracketid)
	end
	
	--set main div, with customizable width and with attachable option (to e.g. grouptables)
	local main = html.create("div"):addClass("brkts-main"):cssText(args.attached == 'true' and 'padding-left:0px;padding-right:0px' or '')
	local width = string.gsub(args.width or 300, 'px', '')
	width = (tonumber(width) or 300) .. 'px'
	
	--determine class for the tableWrapper (collaps options)
	local main_class = 'brkts-matchlist wikitable wikitable-bordered matchlist'
	if args.nocollapse ~= 'true' then
		main_class = main_class .. ' collapsible'
		if args.collapsed == 'true' then
			main_class = main_class .. ' collapsed'
		end
	end
	
	--set tableWrapper with attachable option (to e.g. grouptables) and with collaps options
	local tableWrapper = html.create("table")
		:addClass(main_class)
		:cssText(args.attached == 'true' and 'margin-bottom:-1px;margin-top:-2px' or '')
		:css("width", width)
	tableWrapper:node(tableBody)
	
	-- add matches
	for index, match in ipairs(matches) do
		local bracketdata = match.match2bracketdata or {}
		if type(bracketdata) == "string" then
			bracketdata = Json.parse(bracketdata)
		end
		match.extradata = Json.stringify(match.extradata or {})
		
		-- add title
		if index == 1 then
			local temp = _drawTitle(bracketdata.title or "Match List")
			if not utils.misc.isEmpty(bracketdata.header) then
				temp:tag('tr'):node(_drawHeader(bracketdata.header))
			end
			tableWrapper:node(temp)
		end
		
		-- add header
		if index ~= 1 and not utils.misc.isEmpty(bracketdata.header) then
			tableWrapper:node(_drawHeader(bracketdata.header))
		end
		
		tableWrapper:node(_drawMatch(match))
	end
	
	return main:node(tableWrapper)
end

-- draw table row containing the table title
function _drawTitle(title)
	return html.create("th")
		:addClass("brkts-matchlist-title")
		:attr("colspan", "5")
		:node(html.create("center")
			:wikitext(title)
		)
end

-- draw table row containing match from match data
function _drawMatch(match)
	
	local winner = tonumber(match.winner)
	if match.resulttype == 'draw' then
		winner = 0
	end
	local default_opponent = {
		name = "",
		template = ""
	}
	
	local opponent1data = match.match2opponents[1] or default_opponent
	local opponent2data = match.match2opponents[2] or default_opponent
	local opponent1key = DisplayHelper.getOpponentHighlightKey(opponent1data)
	local opponent2key = DisplayHelper.getOpponentHighlightKey(opponent2data)
	
	local tbd1 =
		match.opponent1template == 'tbd' or match.opponent1 == 'TBD' or
		utils.string.startsWith(opponent1data.type, 'literal')
	local tbd2 =
		match.opponent2template == 'tbd' or match.opponent2 == 'TBD' or
		utils.string.startsWith(opponent2data.type, 'literal')

	local hasDetails = HasDetails(match)
	
	return html.create("tr")
		:addClass("brtks-matchlist-row brkts-match-popup-wrapper")
		:css("cursor", "pointer")
		:node(html.create("td")
			:addClass("brkts-matchlist-slot brkts-opponent-hover" .. (tonumber(match.winner) == 1 and " brkts-matchlist-slot-winner" or tonumber(match.winner) == 0 and " brkts-matchlist-slot-bold bg-draw" or ""))
			:attr("aria-label", not tbd1 and opponent1key or nil)
			:attr("width", "40%")
			:attr("align", "right")
			:node(OpponentDisplay.luaGet(_frame, _addDisplayType(_flattenArgs(opponent1data), "matchlist-left")))
		)
		:node(html.create("td")
			:addClass("brkts-matchlist-slot brkts-opponent-hover" .. ((tonumber(match.winner) == 1 or tonumber(match.winner) == 0) and " brkts-matchlist-slot-bold" or ""))
			:attr("aria-label", not tbd1 and opponent1key or nil)
			:attr("width", "10.8%")
			:attr("align", "center")
			:node(OpponentDisplay.luaGet(_frame, _addDisplayType(_flattenArgs(opponent1data), "matchlist-left-score")))
		)
		:node(
			not hasDetails and "" or
			html.create("td")
				:addClass("brkts-match-info brkts-empty-td")
				:node(
					html.create("div")
						:addClass("brkts-match-info-icon")
				)
				:node(
					html.create("div")
						:addClass("brkts-match-info-popup")
						:node(MatchSummary.luaGet(_frame, _flattenArgs(match)))
						:css("display", "none")
				)
			)
		:node(html.create("td")
			:addClass("brkts-matchlist-slot brkts-opponent-hover" .. ((tonumber(match.winner) == 2 or tonumber(match.winner) == 0) and " brkts-matchlist-slot-bold" or ""))
			:attr("aria-label", not tbd2 and opponent2key or nil)
			:attr("width", "10.8%")
			:attr("align", "center")
			:node(OpponentDisplay.luaGet(_frame, _addDisplayType(_flattenArgs(opponent2data), "matchlist-right-score")))
		)
		:node(html.create("td")
			:addClass("brkts-matchlist-slot brkts-opponent-hover" .. (tonumber(match.winner) == 2 and " brkts-matchlist-slot-winner" or tonumber(match.winner) == 0 and " brkts-matchlist-slot-bold bg-draw" or ""))
			:attr("aria-label", not tbd2 and opponent2key or nil)
			:attr("width", "40%")
			:attr("align", "left")
			:node(OpponentDisplay.luaGet(_frame, _addDisplayType(_flattenArgs(opponent2data), "matchlist-right")))
		)
end

function _drawHeader(header)
	return html.create("th")
		:addClass("brkts-matchlist-header")
		:attr("colspan", "5")
		:node(html.create("center")
			:wikitext(header)
		)
end

-- get matches from LPDB or from a var
function _getMatches(bracketid)
	local varData = utils.mw.varGet("match2bracket_" .. bracketid)
	if varData ~= nil then
		return Json.parse(varData)
	else
		local res = mw.ext.LiquipediaDB.lpdb("match2", {
				conditions = "([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::" .. bracketid .. "]]",
				order = "match2id ASC"
			})
		
		return res
	end
end

function _flattenArgs(args, prefix)
	local out = {}
	prefix = prefix or ""
	for key, val in pairs(args) do
		if tonumber(key) ~= nil then
			key = tonumber(key)
			if utils.string.endsWith(prefix, "s_") then
				prefix = prefix:sub(1, prefix:len() - 2)
			end
		end
		if type(val) == "table" then
			local newArgs = _flattenArgs(val, prefix .. key .. "_")
			for newKey, newVal in pairs(newArgs) do
				out[newKey] = newVal
			end
		else
			out[prefix .. key] = tostring(val)
		end	
	end
	return out
end

function _addDisplayType(args, displayType)
	args.displaytype = displayType
	return args
end
	
return Matchlist
