---
-- @Liquipedia
-- page=Module:StreamPage/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local MatchTable = Lua.import('Module:MatchTable/Custom')
local MatchTicker = Lua.import('Module:MatchTicker')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchPageAdditionalSection = Lua.import('Module:Widget/Match/Page/AdditionalSection')
local MatchPageHeader = Lua.import('Module:Widget/Match/Page/Header')
local WidgetUtil = Lua.import('Module:Widget/Util')

local StreamPage = {}

---@param args {channel: string, provider: string}
---@return Widget?
function StreamPage.create(args)
	if String.isEmpty(args.channel) or String.isEmpty(args.provider) then
		return
	end

	local matches = StreamPage._getMatches(args)
	if #matches == 0 then
		return
	end
	local match = matches[1]

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		'__NOTOC__',
		StreamPage._panel(match),
		StreamPage.displayUpcomingMatches(args, match),
		{
			HtmlWidgets.H3{children = 'Player Information'},
			StreamPage._opponentPlayerTable(match.opponents)
		},
		{
			HtmlWidgets.H3{children = 'Head to Head'},
			MatchTable.results{
				limit = 5,
				edate = match.timestamp - 86400,
				showOpponent = true,
				tableMode = Opponent.team,
				team = match.opponents[1].name,
				vsteam = match.opponents[2].name,
			}
		}
	)}
end

---@param args table
---@param match MatchGroupUtilMatch
---@return Widget
function StreamPage.displayUpcomingMatches(args, match)
	local ticker = MatchTicker{
		additionalConditions = 'AND ([[stream_' .. args.provider .. '::' .. args.channel .. ']]' ..
								' OR [[stream_' .. args.provider .. '_en_1::' .. args.channel .. ']])' ..
								' AND ([[date::' .. match.timestamp .. ']] OR [[date::>' .. match.timestamp .. ']])',
		limit = 5,
		newStyle = true,
		ongoing = true,
		upcoming = true,
		wrapperClasses = {'new-match-style'},
	}
	return HtmlWidgets.Div{
		css = {float = 'right'},
		children = MatchPageAdditionalSection{
			header = 'Channel Schedule',
			children = ticker:query():create()
		}
	}
end

---@param opponents standardOpponent[]
---@return Html
function StreamPage._opponentPlayerTable(opponents)
	return HtmlWidgets.Div{
		classes = {'match-bm-players-wrapper'},
		children = Array.map(opponents, StreamPage._teamDisplay)
	}
end

---@private
---@param opponent standardOpponent
---@return Widget
function StreamPage._teamDisplay(opponent)
	return HtmlWidgets.Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'match-bm-players-team-header'},
				children = OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'icon'}
			},
			Array.map(opponent.players, StreamPage._playerDisplay)
		)
	}
end

---@param player standardPlayer
---@return Widget
function StreamPage._playerDisplay(player)
	local lpdbData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. (Page.pageifyLink(player.pageName) or '') .. ']]',
		limit = 1
	})[1]

	local playerData = {}
	local image
	if lpdbData then
		playerData = lpdbData
		image = playerData.image
		if String.isEmpty(image) then
			image = (playerData.extradata or {}).image
		end
	end
	if String.isEmpty(image) then
		image = 'Blank Player Image.png'
	end
	local imageDisplay = Image.display(image, nil, {class = 'img-fluid', size = '600px'})

	local nameDisplay = PlayerDisplay.InlinePlayer{
		player = player
	}

	return HtmlWidgets.Div{
		classes = {'match-bm-players-player', 'match-bm-players-player--col-2'},
		children = {imageDisplay, nameDisplay}
	}
end

---@param match MatchGroupUtilMatch
---@return Html
function StreamPage._panel(match)
	local countdownBlock = not DateExt.isDefaultTimestamp(match.timestamp) and HtmlWidgets.Div{
		css = {
			display = 'block',
			['text-align'] = 'center'
		},
		children = Countdown.create{
			date = DateExt.toCountdownArg(match.timestamp, match.timezoneId, match.dateIsExact),
			finished = match.finished,
			rawdatetime = Logic.readBool(match.finished),
		}
	} or nil
	local tournament = StreamPage._getTournamentData(match.parent) or {}
	Array.forEach(match.opponents, function (opponent, opponentIndex)
		---@cast opponent MatchPageOpponent
		opponent.iconDisplay = OpponentDisplay.InlineTeamContainer{
			style = 'icon',
			template = opponent.template,
		}
		opponent.teamTemplateData = TeamTemplate.getRaw(opponent.template)
		opponent.seriesDots = {}
	end)
	return MatchPageHeader{
		countdownBlock = countdownBlock,
		isBestOfOne = match.bestof == 1,
		mvp = match.extradata.mvp,
		opponent1 = match.opponents[1],
		opponent2 = match.opponents[2],
		parent = match.parent,
		phase = MatchGroupUtil.computeMatchPhase(match),
		stream = match.stream,
		tournamentName = match.tournament,
		highlighted = HighlightConditions.tournament(tournament)
	}
end

---@param parent string
---@return tournament?
function StreamPage._getTournamentData(parent)
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. parent .. ']]',
		limit = 1,
	})[1]
end

---@param args table
---@return MatchGroupUtilMatch[]
function StreamPage._getMatches(args)
	local conditions = {
		'([[stream_' .. args.provider .. '::' .. args.channel .. ']] OR [[stream_' .. args.provider .. '_en_1::' .. args.channel .. ']])',
		'[[finished::0]]',
		'[[date::!' .. DateExt.defaultDateTime .. ']]',
		'[[dateexact::1]]',
		--'[[status::!cancelled]]',
		--'[[status::!postponed]]',
		-- possibly a condition to make it only retrieve team matches?
	}

	local data = Array.map(mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = table.concat (conditions, ' AND '),
		order = 'date asc',
		limit = 25, --have to kick bye matches later on, hence more matches queried here
	}), MatchGroupUtil.matchFromRecord)

	if type(data) == 'table' and type(data[1]) == 'table' then
		return StreamPage._removeByeMatches(data)
	end

	return {}
end

---@param data MatchGroupUtilMatch[]
---@return MatchGroupUtilMatch[]
function StreamPage._removeByeMatches(data)
	local matches = {}
	for _, match in ipairs(data) do
		if StreamPage._matchHasNoBye(match) then
			table.insert(matches, match)
		end
		if #matches == 5 then
			break
		end
	end

	return matches
end

---@param match MatchGroupUtilMatch
---@return boolean
function StreamPage._matchHasNoBye(match)
	return not Array.any(match.opponents, Opponent.isBye)
end

return Class.export(StreamPage, {exports = {'create'}})
