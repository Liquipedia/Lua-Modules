local MatchSummary = require('Module:MatchSummary/Base')
local Json = require('Module:Json')
local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Template = require('Module:Template')
local LuaUtils = require("Module:LuaUtils")
local Table = require('Module:Table')

local config = LuaUtils.lua.moduleExists("Module:Match/Config") and require("Module:Match/Config") or {}
local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20

local Agents = Class.new(
    function(self)
        self.root = mw.html.create('div')
        self.root   :addClass('hide-mobile')
        self.text = ''
    end
)

function Agents:setLeft()
    self.root   :css('float', 'left')
                :css('margin-left', '10px')

    return self
end

function Agents:setRight()
    self.root   :css('float', 'right')
                :css('margin-right', '10px')

    return self
end

function Agents:add(frame, agent)
    if LuaUtils.misc.isEmpty(agent) then
        return self
    end

    self.text = self.text .. Template.safeExpand(frame, 'AgentBracket/' .. agent)
    return self
end

function Agents:create()
    self.root:wikitext(self.text)
    return self.root
end

local Score = Class.new(
    function(self)
        self.root = mw.html.create('div')
        self.table = self.root:tag('table'):css('line-height', '20px')
    end
)

function Score:setLeft()
    self.root   :css('float', 'left')
                :css('margin-left', '5px')

    return self
end

function Score:setRight()
    self.root   :css('float', 'right')
                :css('margin-right', '5px')

    return self
end

function Score:setMapScore(score)
    self.top = mw.html.create('tr')
    self.bottom = mw.html.create('tr')

    local mapScore = mw.html.create('td')
    mapScore:attr('rowspan', '2')
            :css('font-size', '16px')
            :css('width', '25px')
            :wikitext(score or '')
    self.top:node(mapScore)

    return self
end

function Score:setFirstRoundScore(side, score)
    local roundScore = mw.html.create('td')
    roundScore  :addClass('bracket-popup-body-match-sidewins')
                :css('color', self:_getSideColor(side))
                :wikitext(score)
    self.top:node(roundScore)
    return self
end

function Score:setSecondRoundScore(side, score)
    local roundScore = mw.html.create('td')
    roundScore  :addClass('bracket-popup-body-match-sidewins')
                :css('color', self:_getSideColor(side))
                :wikitext(score)
    self.bottom:node(roundScore)
    return self
end

function Score:_getSideColor(side)
	if side == 'atk' then
		return '#c04845'
	elseif side == 'def' then
		return '#46b09c'
	end
end

function Score:create()
    self.table:node(self.top):node(self.bottom)
    return self.root
end

local CustomMatchSummary = {}

-- Suboptimal to have this be global, but alas
local vods = {}

function CustomMatchSummary.get(frame)
    return CustomMatchSummary.luaGet(frame, require('Module:Arguments').getArgs(frame))
end

function CustomMatchSummary.luaGet(frame, args)
    local matchSummary = MatchSummary:init('480px')
    matchSummary:header(CustomMatchSummary._createHeader(frame, args))
                :body(CustomMatchSummary._createBody(frame, args))

  	local matchExtradata = Json.parse(args.extradata or "{}")

    if not LuaUtils.misc.isEmpty(matchExtradata.comment) then
        matchSummary:comment(MatchSummary.Comment():content(matchExtradata.comment))
    end

    if Table.size(vods) > 0 then
        local footer = MatchSummary.Footer()

        for index, vod in pairs(vods) do
            footer:addElement(Template.safeExpand(frame, 'vodlink', {
                gamenum = index,
                vod = vod,
                source = vod.url
            }))
        end

        matchSummary:footer(footer)
    end
    
    return matchSummary:create()
end

function CustomMatchSummary._createHeader(frame, args)
    local header = MatchSummary.Header()
    header  :left(CustomMatchSummary._createLeftOpponent(frame, args))
            :right(CustomMatchSummary._createRightOpponent(frame, args))

    return header
end

function CustomMatchSummary._createBody(frame, args)
    local body = MatchSummary.Body()

    local streamElement = mw.html.create('center')
    streamElement   :wikitext(CustomMatchSummary._createStreamCountdown(frame, args))
                    :css('display', 'block')
                    :css('margin', 'auto')
    body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(streamElement))

    local matchPageElement = mw.html.create('center')
    matchPageElement   :wikitext('[[Match:ID_' .. args['match2id'] .. '|Match Page]]')
                    :css('display', 'block')
                    :css('margin', 'auto')
    body:addRow(MatchSummary.Row():css('font-size', '85%'):addElement(matchPageElement))

  	for index = 1, MAX_NUM_MAPS do
		local game = "match2game" .. index .. '_'
		local map = args[game .. "map"]
		if not LuaUtils.misc.isEmpty(map) then
            body:addRow(CustomMatchSummary._createMap(frame, args, game, map))
        end

        local vod = args[game .. "vod"]
        if not LuaUtils.misc.isEmpty(vod) then
            vods[index] = vod
        end
    end

    return body
end

function CustomMatchSummary._createMap(frame, args, game, map)
    local row = MatchSummary.Row()

    local winner = args[game .. "winner"]
    local extradata, err = Json.parse(args[game .. "extradata"])
    local participants = args[game .. 'participants']
    local team1Agents, team2Agents

    if participants ~= nil then
        participants = Json.parse(participants)

        team1Agents = Agents():setLeft()
        team2Agents = Agents():setRight()

        for player = 1, 5 do
            local playerStats = participants['1_' .. player]
            if playerStats ~= nil then
                team1Agents:add(frame, playerStats['agent'])
            end
        end

        for player = 1, 5 do
            local playerStats = participants['2_' .. player]
            if playerStats ~= nil then
                team2Agents:add(frame, playerStats['agent'])
            end
        end

    end

    local score1, score2

    if extradata ~= nil then
        score1 = Score():setLeft()
        score2 = Score():setRight()

        score1:setMapScore(args[game .. 'score1'])
        score2:setMapScore(args[game .. 'score2'])

        score1:setFirstRoundScore(extradata.op1startside, extradata.half1score1)
        score1:setSecondRoundScore(
            CustomMatchSummary._getOppositeSide(extradata.op1startside), extradata.half2score1)

        score2:setFirstRoundScore(
            CustomMatchSummary._getOppositeSide(extradata.op1startside), extradata.half1score2)
        score2:setSecondRoundScore(extradata.op1startside, extradata.half2score2)
    end

    row:addElement(CustomMatchSummary._createCheckMark(tonumber(winner) == 1))
    if team1Agents ~= nil then
        row:addElement(team1Agents:create())
    end
    row:addElement(score1:create())

    local centerNode = mw.html.create('div')
    centerNode  :addClass('brkts-popup-spaced')
                :wikitext('[[' .. map .. ']]')
                :css('width', '100px')
                :css('text-align', 'center')

    if args[game .. 'resulttype'] == 'np' then
        centerNode:addClass('brkts-popup-spaced-map-skip')
    end

    row:addElement(centerNode)
    row:addElement(score2:create())

    if team2Agents ~= nil then
        row:addElement(team2Agents:create())
    end
    row:addElement(CustomMatchSummary._createCheckMark(tonumber(winner) == 2))

    if not LuaUtils.misc.isEmpty(extradata.comment) then
        row:addElement(MatchSummary.Break():create())
        local comment = mw.html.create('div')
        comment :wikitext(extradata.comment)
                :css('margin', 'auto')
        row:addElement(comment)
    end

    row:addClass('brkts-popup-body-game')
    return row
end

function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

function CustomMatchSummary._createCheckMark(isWinner)
    local container = mw.html.create('div')
    container:addClass('brkts-popup-spaced')

    if isWinner then
        container:node('[[File:GreenCheck.png|14x14px|link=]]')
        return container
    end

    container:node('[[File:NoCheck.png|link=]]')
    return container
end

function CustomMatchSummary._createStreamCountdown(frame, args)
  	local stream = Json.parse(args.stream or "{}")
  	stream.date = mw.getContentLanguage():formatDate('r', args.date)
	stream.finished = LuaUtils.misc.readBool(args.finished) and "true" or ""

    return Template.safeExpand(frame, 'countdown', stream)
end

function CustomMatchSummary._createLeftOpponent(frame, args)
    local container = mw.html.create('div')
    container   :addClass('brkts-popup-header-left')
                :css('justify-content', 'flex-end')
                :css('display', 'flex')
                :css('width', '45%')

    local prefix = 'match2opponent1_'
    local opponent = CustomMatchSummary._renderOpponent(
        prefix .. 'type',
        function()
            return Template.safeExpand(frame, 'Team2Short', { args[prefix .. 'template'] or 'TBD' })
        end,
        function()
            return Template.safeExpand(frame, 'Player2', { args[prefix .. 'match2player1_name'], flag = args[prefix .. 'match2player1_flag'] })
        end
    )

    container:node(opponent)
    return container
end

function CustomMatchSummary._createRightOpponent(frame, args)
    local container = mw.html.create('div')
    container:addClass('brkts-popup-header-right')

    local prefix = 'match2opponent2_'
    local opponent = CustomMatchSummary._renderOpponent(
        prefix .. 'type',
        function()
            return Template.safeExpand(frame, 'TeamShort', { args[prefix .. 'template'] or 'TBD' })
        end,
        function()
            return Template.safeExpand(frame, 'Player', { args[prefix .. 'match2player1_name'], flag = args[prefix .. 'match2player1_flag'] })
        end
    )

    container:node(opponent)
    return container
end

function CustomMatchSummary._renderOpponent(opponentType, renderTeam, renderPlayer)
    if opponentType == 'solo' then
        return renderPlayer()
    end

    return renderTeam()
end

return CustomMatchSummary
