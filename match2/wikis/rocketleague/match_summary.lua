local Countdown = require('Module:Countdown')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Logic = require("Module:Logic")

local htmlCreate = mw.html.create

local p = {}

function p.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchesTable(args.bracketId)[args.matchId]

	local wrapper = htmlCreate("div")
		:addClass("brkts-popup")

	local stream = Table.merge(match.stream, {
		date = mw.getContentLanguage():formatDate('r', match.date),
		finished = match.finished and 'true' or nil,
	})

	function p._renderOpponent(opponentIndex)
		local opponent = match.opponents[opponentIndex]
		if opponent.type == "team" or opponent.type == "literal" then
			local template = opponentIndex == 1 and "Team2Short" or "TeamShort"
			return Template.safeExpand(
				mw.getCurrentFrame(),
				template,
				{ opponent.template or "TBD" }
			)
		elseif opponent.type == "solo" then
			local template = opponentIndex == 1 and "Player2" or "Player"
			return Template.safeExpand(
				mw.getCurrentFrame(),
				template,
				{ name = opponent.players[1].name, flag = opponent.players[1].flag }
			)
		end
	end

	-- header
	local header = htmlCreate("div")
		:addClass("brkts-popup-header")
		:node(htmlCreate("div")
			:addClass("brkts-popup-header-left")
			:css("justify-content","flex-end")
			:css("display","flex")
			:css("width","45%")
			:wikitext(p._renderOpponent(1)))
		:node(htmlCreate("div")
			:addClass("brkts-popup-header-right")
			:wikitext(p._renderOpponent(2)))
	wrapper:node(header):node(p._breakNode())

	-- body
	local body = htmlCreate("div"):addClass("brkts-popup-body")
	body = p._addFlexRow(body, {
			htmlCreate("center"):wikitext(Countdown._create(stream))
				:css("display","block")
				:css("margin","auto")
		},
		nil,
		{ ["font-size"] = "85%" })
	for _, game in ipairs(match.games) do
		if game.map then
			local centerNode = htmlCreate("div")
					:addClass("brkts-popup-spaced")
					:node(htmlCreate("div"):node("[[" .. game.map .. "]]"))
			if Logic.readBool(game.extradata.ot) then
				centerNode:node(htmlCreate("div"):node("- OT"))
				if not Logic.isEmpty(game.extradata.otlength) then
					centerNode:node(htmlCreate("div"):node("(" .. game.extradata.otlength .. ")"))
				end
			end
			local gameElements = {
				htmlCreate("div")
					:addClass("brkts-popup-spaced")
					:node(game.winner == 1 and
						  "[[File:GreenCheck.png|14x14px|link=]]" or
						  "[[File:NoCheck.png|link=]]")
					:node(htmlCreate("div"):node(game.score or "")),
				centerNode,
				htmlCreate("div")
					:addClass("brkts-popup-spaced")
					:node(htmlCreate("div"):node(game.score2 or ""))
					:node(game.winner == 2 and
						  "[[File:GreenCheck.png|14x14px|link=]]" or
						  "[[File:NoCheck.png|link=]]")
			}
			if game.comment then
				table.insert(gameElements, p._breakNode())
				table.insert(gameElements, htmlCreate("div")
					:node(game.comment)
					:css("margin","auto"))
			end
			body = p._addFlexRow(body, gameElements, "brkts-popup-body-game")
		end
	end
	wrapper:node(body):node(p._breakNode())

	-- comment
	if match.comment then
		local comment = htmlCreate("div")
			:addClass("brkts-popup-comment")
			:css("white-space","normal")
			:css("font-size","85%")
			:node(match.comment)
		wrapper:node(comment):node(p._breakNode())
	end

	-- footer
	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	local footerSet = false
	local footer = htmlCreate("div")
		:addClass("brkts-popup-footer")
	local footerSpacer = htmlCreate("div")
		:addClass("brkts-popup-spaced")
	if not Logic.isEmpty(match.extradata.octane) then
		footerSet = true
		footerSpacer:node("[[File:Octane_gg.png|14x14px|link=http://octane.gg/match/" ..
			match.extradata.octane ..
			"|Octane matchpage]]")
	end
	for index, vod in pairs(vods) do
		footerSet = true
		footerSpacer:node(Template.safeExpand(mw.getCurrentFrame(), "vodlink", {
			gamenum = index,
			vod = vod,
			source = '' -- todo: provide source
		}))
	end
	if footerSet then
		footer:node(footerSpacer)
		wrapper:node(footer)
	end
	return wrapper
end

function p._addFlexRow(wrapper, contentElements, class, style)
	local node = htmlCreate("div"):addClass("brkts-popup-body-element")
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

function p._breakNode()
	return htmlCreate("div")
		:addClass("brkts-popup-break")
end

return p
