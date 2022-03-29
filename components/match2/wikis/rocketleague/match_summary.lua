---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local _TBD_ICON = mw.ext.TeamTemplate.teamicon('tbd')

local CustomMatchSummary = {}

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local wrapper = mw.html.create('div')
		:addClass('brkts-popup')

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
			return mw.html.create('div'):wikitext(display)
				:addClass('brkts-popup-header-opponent-solo-team')
		else
			return ''
		end
	end

	-- header
	local header = mw.html.create('div'):addClass('brkts-popup-header-dev')
		:node(renderSoloOpponentTeam(1))
		:node(renderOpponent(1))
		:node(renderOpponent(2))
		:node(renderSoloOpponentTeam(2))
	wrapper:node(header):node(CustomMatchSummary._breakNode())

	-- body
	local body = mw.html.create('div'):addClass('brkts-popup-body')
	body = CustomMatchSummary._addFlexRow(body, {DisplayHelper.MatchCountdownBlock(match)})
	for _, game in ipairs(match.games) do
		if game.map then
			local centerNode = mw.html.create('div')
					:addClass('brkts-popup-spaced')
					:node(mw.html.create('div'):node('[[' .. game.map .. ']]'))
			if Logic.readBool(game.extradata.ot) then
				centerNode:node(mw.html.create('div'):node('- OT'))
				if not Logic.isEmpty(game.extradata.otlength) then
					centerNode:node(mw.html.create('div'):node('(' .. game.extradata.otlength .. ')'))
				end
			end
			local gameElements = {
				mw.html.create('div')
					:addClass('brkts-popup-spaced')
					:node(game.winner == 1 and
						'[[File:GreenCheck.png|14x14px|link=]]' or
						'[[File:NoCheck.png|link=]]')
					:node(mw.html.create('div'):node(game.scores[1] or '')),
				centerNode,
				mw.html.create('div')
					:addClass('brkts-popup-spaced')
					:node(mw.html.create('div'):node(game.scores[2] or ''))
					:node(game.winner == 2 and
						'[[File:GreenCheck.png|14x14px|link=]]' or
						'[[File:NoCheck.png|link=]]')
			}
			local gameHeader = game.header or ''
			if gameHeader ~= '' then
				table.insert(gameElements, 1, CustomMatchSummary._breakNode())
				table.insert(gameElements, 1, mw.html.create('div')
					:node(gameHeader)
					:css('font-weight','bold')
					:css('font-size','85%')
					:css('margin','auto'))
			end
			if game.extradata.timeout then
				local timeouts = Json.parseIfString(game.extradata.timeout)
				table.insert(gameElements, CustomMatchSummary._breakNode())
				table.insert(gameElements,
					mw.html.create('div')
						:addClass('brkts-popup-spaced')
						:node(Table.includes(timeouts, 1) and
							'[[File:Cooldown_Clock.png|14x14px|link=]]' or
							'[[File:NoCheck.png|link=]]')
				)
				table.insert(gameElements,
					mw.html.create('div')
						:addClass('brkts-popup-spaced')
						:node(mw.html.create('div'):node('Timeout'))
				)
				table.insert(gameElements,
					mw.html.create('div')
						:addClass('brkts-popup-spaced')
						:node(Table.includes(timeouts, 2) and
							'[[File:Cooldown_Clock.png|14x14px|link=]]' or
							'[[File:NoCheck.png|link=]]')
				)
			end
			local hasCommentLineBreakNode = false
			if game.extradata.t1goals then
				table.insert(gameElements, CustomMatchSummary._breakNode())
				hasCommentLineBreakNode = true
				local goals = mw.html.create('div')
					:wikitext('<abbr title=\"Team 1 Goaltimes\">' ..
						game.extradata.t1goals .. '</abbr>')
				table.insert(gameElements, mw.html.create('div')
					:node(goals)
					:css('max-width', '50%')
					:css('maxfont-size', '11px;'))
			end
			if game.comment then
				if not hasCommentLineBreakNode then
					table.insert(gameElements, CustomMatchSummary._breakNode())
				end
				hasCommentLineBreakNode = true
				table.insert(gameElements, mw.html.create('div')
					:node(game.comment)
					:css('margin','auto')
					:css('max-width', '60%'))
			end
			if game.extradata.t2goals then
				if not hasCommentLineBreakNode then
					table.insert(gameElements, CustomMatchSummary._breakNode())
				end
				local goals = mw.html.create('div')
					:cssText('float:right;margin-right:10px;')
					:wikitext('<abbr title=\"Team 2 Goaltimes\">' ..
						game.extradata.t2goals .. '</abbr>')
				table.insert(gameElements, mw.html.create('div')
					:node(goals)
					:css('max-width', '50%')
					:css('maxfont-size', '11px;'))
			end
			body = CustomMatchSummary._addFlexRow(body, gameElements, 'brkts-popup-body-game')
		end
	end
	wrapper:node(body):node(CustomMatchSummary._breakNode())

	-- casters
	if match.extradata.casters then
		local casters = Json.parseIfString(match.extradata.casters)
		for index, caster in pairs(casters) do
			casters[index] = '[[' .. caster .. ']]'
		end
		local casterRow = mw.html.create('div')
			:addClass('brkts-popup-comment')
			:css('white-space','normal')
			:css('font-size','85%')
			:wikitext('<b>Caster' .. (#casters > 1 and 's' or '') .. ':</b><br>')
			:wikitext(table.concat(casters, ', '))
		wrapper:node(casterRow):node(CustomMatchSummary._breakNode())
	end
	-- comment
	if match.comment then
		local comment = mw.html.create('div')
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
	local footer = mw.html.create('div')
		:addClass('brkts-popup-footer')
	local footerSpacer = mw.html.create('div')
		:addClass('brkts-popup-spaced')
	if not Logic.isEmpty(match.extradata.octane) then
		footerSet = true
		footerSpacer:node('[[File:Octane_gg.png|14x14px|link=http://octane.gg/matches/' ..
			match.extradata.octane ..
			'|Octane matchpage]]')
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
	local node = mw.html.create('div'):addClass('brkts-popup-body-element')
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
	return mw.html.create('div')
		:addClass('brkts-popup-break')
end

return CustomMatchSummary
