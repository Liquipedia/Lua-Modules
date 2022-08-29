---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local OpponentDisplay = require('Module:OpponentDisplay')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local htmlCreate = mw.html.create

local _TBD_ICON = mw.ext.TeamTemplate.teamicon('tbd')

local CustomMatchSummary = {}

local _GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local wrapper = htmlCreate('div')
		:addClass('brkts-popup')
		:css('flex-wrap', 'unset') -- temporary workaround

	local function renderOpponent(opponentIndex)
		return OpponentDisplay.BlockOpponent({
			flip = opponentIndex == 1,
			opponent = match.opponents[opponentIndex],
			overflow = 'wrap',
			teamStyle = 'short',
		})
			:addClass(match.opponents[opponentIndex].type ~= 'solo'
				and 'brkts-popup-header-opponent'
				or 'brkts-popup-header-opponent-solo-with-team')
	end

	local function renderSoloOpponentTeam(opponentIndex)
		local opponent = match.opponents[opponentIndex]
		if opponent.type == 'solo' then
			local teamExists = mw.ext.TeamTemplate.teamexists(opponent.template or '')
			local display = teamExists
				and mw.ext.TeamTemplate.teamicon(opponent.template, match.date)
				or _TBD_ICON
			return htmlCreate('div'):wikitext(display)
				:addClass('brkts-popup-header-opponent-solo-team')
		else
			return ''
		end
	end

	-- header
	local header = htmlCreate('div'):addClass('brkts-popup-header-dev')
		:node(renderSoloOpponentTeam(1))
		:node(renderOpponent(1))
		:node(renderOpponent(2))
		:node(renderSoloOpponentTeam(2))
	wrapper:node(header):node(CustomMatchSummary._breakNode())

	-- body
	local body = htmlCreate('div'):addClass('brkts-popup-body')
	body = CustomMatchSummary._addFlexRow(body, {DisplayHelper.MatchCountdownBlock(match)})
	for _, game in ipairs(match.games) do
		if game.map then
			local mapDisplay = '[[' .. game.map .. ']]'
			local modeIcon = MapModes.get({ mode = game.mode, date = match.date, size = 15})
			if modeIcon ~= '' then
				modeIcon = modeIcon .. '&nbsp;'
			end
			if game.resultType == 'np' then
				mapDisplay = '<s>' .. mapDisplay .. '</s>'
			end
			mapDisplay = modeIcon .. mapDisplay
			local centerNode = htmlCreate('div')
					:addClass('brkts-popup-spaced')
					:node(htmlCreate('div'):node(mapDisplay))
			local gameElements = {
				htmlCreate('div')
					:addClass('brkts-popup-spaced')
					:node(game.winner == 1 and _GREEN_CHECK or _NO_CHECK)
					:node(htmlCreate('div'):node(game.scores[1] or '')),
				centerNode,
				htmlCreate('div')
					:addClass('brkts-popup-spaced')
					:node(htmlCreate('div'):node(game.scores[2] or ''))
					:node(game.winner == 2 and _GREEN_CHECK or _NO_CHECK)
			}

			local gameHeader = game.header or ''
			if gameHeader ~= '' then
				table.insert(gameElements, 1, CustomMatchSummary._breakNode())
				table.insert(gameElements, 1, htmlCreate('div')
					:node(gameHeader)
					:css('font-weight','bold')
					:css('font-size','85%')
					:css('margin','auto'))
			end
			if game.comment then
				table.insert(gameElements, CustomMatchSummary._breakNode())
				table.insert(gameElements, htmlCreate('div')
					:node(game.comment)
					:css('margin','auto')
					:css('max-width', '60%'))
			end
			body = CustomMatchSummary._addFlexRow(body, gameElements, 'brkts-popup-body-game')
		end
	end

	wrapper:node(body):node(CustomMatchSummary._breakNode())

	-- comment
	if match.comment then
		local comment = htmlCreate('div')
			:addClass('brkts-popup-comment')
			:css('white-space','normal')
			:css('font-size','85%')
			:node(match.comment)
		wrapper:node(comment):node(CustomMatchSummary._breakNode())
	end

	-- footer
	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	local footerSet = false
	local footer = htmlCreate('div')
		:addClass('brkts-popup-footer')
	local footerSpacer = htmlCreate('div')
		:addClass('brkts-popup-spaced')
	if match.vod then
		footerSet = true
		footerSpacer:node(VodLink.display{
			vod = match.vod,
		})
	end
	for index, vod in pairs(vods) do
		footerSet = true
		footerSpacer:node(VodLink.display{
			gamenum = index,
			vod = vod,
		})
	end
	if footerSet then
		footer:node(footerSpacer)
		wrapper:node(footer)
	end
	return wrapper
end

function CustomMatchSummary._addFlexRow(wrapper, contentElements, class, style)
	local node = htmlCreate('div'):addClass('brkts-popup-body-element')
	if not Logic.isEmpty(class) then
		node:addClass(class)
	end
	for key, val in pairs(style or {}) do
		node:css(key, val)
	end
	for _, element in ipairs(contentElements) do
		node:node(element)
	end
	return wrapper:node(node)
end

function CustomMatchSummary._breakNode()
	return htmlCreate('div')
		:addClass('brkts-popup-break')
end

return CustomMatchSummary
