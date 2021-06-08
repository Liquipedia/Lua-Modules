local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local LuaUtils = require('Module:LuaUtils')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local String = require('Module:String')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local html = mw.html

local Bracket = {propTypes = {}, types = {}}

-- Called by MatchGroup/Display
function Bracket.luaGet(_, args)
    return Bracket.BracketContainer({
        bracketId = args[1],
        config = Bracket.configFromArgs(args),
    })
end

function Bracket.configFromArgs(args)
    return {
        headerHeight = tonumber(args.headerHeight),
        headerMargin = tonumber(args.headerMargin),
        hideRoundTitles = LuaUtils.misc.readBool(args.hideRoundTitles),
        lineWidth = tonumber(args.lineWidth),
        matchMargin = tonumber(args.matchMargin),
        matchWidth = tonumber(args.matchWidth),
        matchWidthMobile = tonumber(args.matchWidthMobile),
        opponentHeight = tonumber(args.opponentHeight),
        qualifiedHeader = args.qualifiedHeader,
        roundHorizontalMargin = tonumber(args.roundHorizontalMargin),
        scoreWidth = tonumber(args.scoreWidth),
    }
end

Bracket.types.BracketConfig = TypeUtil.struct({
    MatchSummaryContainer = 'function',
    OpponentEntry = 'function',
    headerHeight = 'number',
    headerMargin = 'number',
    hideRoundTitles = 'boolean',
    lineWidth = 'number',
    matchHasDetails = 'function',
    matchMargin = 'number',
    matchWidth = 'number',
    matchWidthMobile = 'number',
    opponentHeight = 'number',
    qualifiedHeader = 'string?',
    roundHorizontalMargin = 'number',
    scoreWidth = 'number',
})
Bracket.types.BracketConfigOptions = TypeUtil.struct(
    Table.mapValues(Bracket.types.BracketConfig.struct, TypeUtil.optional)
)

--[[
Display component for a tournament bracket. The bracket is specified by ID. 
The component fetches the match data from LPDB or page variables.
]]
Bracket.propTypes.BracketContainer = {
    bracketId = 'string',
    config = TypeUtil.optional(Bracket.types.BracketConfigOptions),
}
function Bracket.BracketContainer(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.BracketContainer)
    return Bracket.Bracket({
        config = props.config,
        matchesById = MatchGroupUtil.fetchMatchesTable(props.bracketId),
    })
end

--[[
Display component for a tournament bracket. Match data is specified in the 
input.
]]
Bracket.propTypes.Bracket = {
    matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
    config = TypeUtil.optional(Bracket.types.BracketConfigOptions),
}
function Bracket.Bracket(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.Bracket)

    local defaultConfig = DisplayHelper.getGlobalConfig()
    local propsConfig = props.config or {}

    local config = {
        MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
        OpponentEntry = propsConfig.OpponentEntry or Bracket.DefaultOpponentEntry,
        headerHeight = propsConfig.headerHeight or defaultConfig.headerHeight,
        headerMargin = propsConfig.headerMargin or defaultConfig.headerMargin,
        hideRoundTitles = propsConfig.hideRoundTitles or false,
        lineWidth = propsConfig.lineWidth or defaultConfig.lineWidth,
        matchHasDetails = propsConfig.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
        matchMargin = propsConfig.matchMargin or math.floor(defaultConfig.opponentHeight / 4),
        matchWidth = propsConfig.matchWidth or defaultConfig.matchWidth,
        matchWidthMobile = propsConfig.matchWidthMobile or defaultConfig.matchWidthMobile,
        opponentHeight = propsConfig.opponentHeight or defaultConfig.opponentHeight,
        qualifiedHeader = propsConfig.qualifiedHeader or defaultConfig.qualifiedHeader,
        roundHorizontalMargin = propsConfig.roundHorizontalMargin or defaultConfig.roundHorizontalMargin,
        scoreWidth = propsConfig.scoreWidth or defaultConfig.scoreWidth,
    }

    local layoutsByMatchId, headMatchIds = Bracket.computeBracketLayout(props.matchesById, config)

    local bracketNode = html.create('div'):addClass('brkts-bracket')
        :css('--match-width', config.matchWidth .. 'px')
        :css('--match-width-mobile', config.matchWidthMobile .. 'px')
        :css('--score-width', config.scoreWidth .. 'px')
        :css('--round-horizontal-margin', config.roundHorizontalMargin .. 'px')

    for _, matchId in ipairs(headMatchIds) do
        local nodeProps = {
            config = config,
            layoutsByMatchId = layoutsByMatchId,
            matchId = matchId,
            matchesById = props.matchesById,
        }
        bracketNode
            :node(Bracket.NodeHeader(nodeProps))
            :node(Bracket.NodeBody(nodeProps))
    end

    return html.create('div'):addClass('brkts-main brkts-main-dev')
        :node(bracketNode)
end

Bracket.types.Layout = TypeUtil.struct({
    height = 'number',
    lowerMarginTop = 'number',
    matchHeight = 'number',
    matchMarginTop = 'number',
    mid = 'number',
    showHeader = 'boolean',
})

--[[
Computes certain layout properties of nodes in the bracket tree.
]]
function Bracket.computeBracketLayout(matchesById, config)
    -- Map match ids to their upper round matches
    local upperMatchIds = {}
    for matchId, match in pairs(matchesById) do
        for _, x in ipairs(match.bracketData.lowerMatches) do
            upperMatchIds[x.matchId] = matchId
        end
    end

    -- Computes the layout of a match and everything to its left.
    local computeNodeLayout = FnUtil.memoizeY(function(matchId, computeNodeLayout)
        local match = matchesById[matchId]
        local lowerLayouts = Array.map(
            match.bracketData.lowerMatches,
            function(x) return computeNodeLayout(x.matchId) end
        )

        -- Compute partial sums of heights of lower round matches
        local heightSums = LuaUtils.math.partialSums(
            Array.map(lowerLayouts, function(layout) return layout.height end)
        )

        -- Show a connector line without joints if there is a single lower round 
        -- match advancing an opponent that is placed near the middle of this match.
        local singleStraightLine
        if #lowerLayouts == 1 then
            local opponentIx = match.bracketData.lowerMatches[1].opponentIx
            singleStraightLine = 
                #match.opponents % 2 == 0 
                    and (opponentIx == #match.opponents / 2 or opponentIx == #match.opponents / 2 + 1)
                or #match.opponents % 2 == 1
                    and opponentIx == math.floor(#match.opponents / 2) + 1
        else
            singleStraightLine = false
        end

        -- Don't show the header if it's disabled. Also don't show the header 
        -- if it is the first match of a round and if a higher round match can
        -- show it instead.
        local isFirstChild = upperMatchIds[matchId] and matchId == matchesById[upperMatchIds[matchId]].bracketData.lowerMatches[1].matchId
        local showHeader = match.bracketData.header
            and not config.hideRoundTitles 
            and not isFirstChild

        local headerFullHeight = showHeader
            and config.headerMargin + config.headerHeight + math.max(config.headerMargin - config.matchMargin, 0)
            or 0
        local matchHeight = #match.opponents * config.opponentHeight

        -- Align the match with its lower round matches
        local matchTop
        if singleStraightLine then
            -- Single straight line: Align the connecting line with the middle 
            -- of the opponent it connects into.
            local opponentIx = match.bracketData.lowerMatches[1].opponentIx

            matchTop = lowerLayouts[1].mid 
                - ((opponentIx - 1) + 0.5) * config.opponentHeight

        elseif 0 < #lowerLayouts then 
            if #lowerLayouts % 2 == 0 then
                -- Even number of lower round matches: Align this match to the 
                -- midpoint of the middle two lower round matches.
                
                local aMid = heightSums[#lowerLayouts / 2] + lowerLayouts[#lowerLayouts / 2].mid
                local bMid = heightSums[#lowerLayouts / 2 + 1] + lowerLayouts[#lowerLayouts / 2 + 1].mid
                matchTop = (aMid + bMid) / 2 - matchHeight / 2

            else
                -- Odd number of lower round matches: Align this match to the 
                -- middle one.
                local middleLowerLayout = lowerLayouts[math.floor(#lowerLayouts / 2) + 1]
                matchTop = heightSums[math.floor(#lowerLayouts / 2) + 1] + middleLowerLayout.mid
                    - matchHeight / 2
            end
        else
            -- No lower matches
            matchTop = 0
        end

        -- Vertical space between lower rounds and top of body
        local lowerMarginTop = matchTop < 0 and -matchTop or 0
        -- Vertical space between match and top of body
        local matchMarginTop = 0 < matchTop and matchTop or 0

        -- Ensure matchMarginTop is at least config.matchMargin
        if matchMarginTop < config.matchMargin then
            lowerMarginTop = lowerMarginTop + config.matchMargin - matchMarginTop
            matchMarginTop = config.matchMargin
        end

        -- Distance between middle of match and top of round
        local mid = headerFullHeight + matchMarginTop + matchHeight / 2

        -- Height of this round, including the header but excluding the 3rd place match and qualifier rounds.
        local height = headerFullHeight 
            + math.max(
                lowerMarginTop + heightSums[#heightSums], 
                matchMarginTop + matchHeight + config.matchMargin
            )
        
        return {
            height = height,
            lowerMarginTop = lowerMarginTop,
            matchHeight = matchHeight,
            matchMarginTop = matchMarginTop,
            mid = mid,
            showHeader = showHeader,
        }
    end)

    local layoutsByMatchId = {}
    for matchId, _ in pairs(matchesById) do
        layoutsByMatchId[matchId] = computeNodeLayout(matchId)
    end

    -- Matches without upper matches
    local headMatchIds = {}
    for matchId, _ in pairs(matchesById) do
        if not upperMatchIds[matchId] 
            and not LuaUtils.string.endsWith(matchId, 'RxMTP') 
            and not LuaUtils.string.endsWith(matchId, 'RxMBR') then
            table.insert(headMatchIds, matchId)
        end
    end
    table.sort(headMatchIds)

    return layoutsByMatchId, headMatchIds
end

--[[
Display component for the headers of a node in the bracket tree. Draws a row of 
headers for the match, everything to the left of it, and for the qualification 
spots.
]]
Bracket.propTypes.NodeHeader = {
    config = Bracket.types.BracketConfig,
    layoutsByMatchId = TypeUtil.table('string', Bracket.types.Layout),
    matchId = 'string',
    matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
}
function Bracket.NodeHeader(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.NodeHeader)
    local match = props.matchesById[props.matchId]
    local layout = props.layoutsByMatchId[props.matchId]
    local config = props.config
    
    if not layout.showHeader then
        return nil
    end

    local headerNode = html.create('div'):addClass('brkts-round-header')
        :css('margin', config.headerMargin .. 'px 0 ' .. math.max(0, config.headerMargin - config.matchMargin) .. 'px')

    -- Traverse the bracket to find the other headers in the same row
    local bracketDatas = {}
    local matchId = props.matchId
    while matchId do
        local bracketData = props.matchesById[matchId].bracketData
        table.insert(bracketDatas, 1, bracketData)
        matchId = 0 < #bracketData.lowerMatches and bracketData.lowerMatches[1].matchId or nil
    end

    for ix, bracketData in ipairs(bracketDatas) do
        headerNode:node(
            Bracket.MatchHeader({
                header = bracketData.header,
                height = config.headerHeight,
            })
                :addClass(bracketData.bracketResetMatchId and 'brkts-br-wrapper' or nil)
                :css('--skip-round', bracketData.skipRound)
        )
    end

    if match.bracketData.qualWin then
        headerNode:node(
            Bracket.MatchHeader({
                header = config.qualifiedHeader or '!q',
                height = config.headerHeight,
            })
                :addClass('brkts-qualified-header')
                :css('--qual-skip', match.bracketData.qualSkip)
        )
    end

    return headerNode
end

--[[
Display component for a header to a match.
]]
Bracket.propTypes.MatchHeader = {
    height = 'number',
    header = 'string',
}
function Bracket.MatchHeader(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.MatchHeader)

    local options = DisplayHelper.expandHeader(props.header)

    local headerNode = html.create('div'):addClass('brkts-header brkts-header-div')
        :css('height', props.height .. 'px')
        :css('line-height', props.height - 11 .. 'px')
        :node(options[1])

    for _, option in ipairs(options) do
        headerNode:node(
            html.create('div'):addClass('brkts-header-option'):node(option)
        )
    end

    return headerNode
end

--[[
Display component for a node in the bracket tree, which consists of a match and 
all the lower round matches leading up to it. Also includes qualification spots 
and line connectors between lower round matches, the current match, and 
qualification spots.
]]
Bracket.propTypes.NodeBody = {
    config = Bracket.types.BracketConfig,
    layoutsByMatchId = TypeUtil.table('string', Bracket.types.Layout),
    matchId = 'string',
    matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
}
function Bracket.NodeBody(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.NodeBody)
    local match = props.matchesById[props.matchId]
    local layout = props.layoutsByMatchId[props.matchId]
    local config = props.config

    -- Matches from lower rounds
    local lowerNode
    if 0 < #match.bracketData.lowerMatches then
        lowerNode = html.create('div'):addClass('brkts-round-lower')
            :css('margin-top', layout.lowerMarginTop .. 'px')
        for _, x in ipairs(match.bracketData.lowerMatches) do
            local childProps = Table.merge(props, {matchId = x.matchId})
            lowerNode
                :node(Bracket.NodeHeader(childProps))
                :node(Bracket.NodeBody(childProps))
        end
    end

    -- Include results from bracketResetMatch
    local bracketResetMatch = match.bracketData.bracketResetMatchId
        and props.matchesById[match.bracketData.bracketResetMatchId]
    if bracketResetMatch then
        match = MatchGroupUtil.mergeBracketResetMatch(match, bracketResetMatch)
    end

    -- Current match
    local matchNode = Bracket.Match({
        MatchSummaryContainer = config.MatchSummaryContainer,
        OpponentEntry = config.OpponentEntry,
        match = match,
        matchHasDetails = config.matchHasDetails,
        opponentHeight = config.opponentHeight,
    })
        :css('margin-top', layout.matchMarginTop .. 'px')
        :css('margin-bottom', config.matchMargin .. 'px')

    -- Third place match
    local thirdPlaceMatch = match.bracketData.thirdPlaceMatchId 
        and props.matchesById[match.bracketData.thirdPlaceMatchId]
    local thirdPlaceHeaderNode
    local thirdPlaceMatchNode
    if thirdPlaceMatch then
        thirdPlaceHeaderNode = Bracket.MatchHeader({
            header = '!tp',
            height = config.headerHeight,
        })
            :css('margin-top', 20 + config.headerMargin .. 'px')
            :css('margin-bottom', config.headerMargin .. 'px')
        thirdPlaceMatchNode = Bracket.Match({
            MatchSummaryContainer = config.MatchSummaryContainer,
            OpponentEntry = config.OpponentEntry,
            match = thirdPlaceMatch,
            matchHasDetails = config.matchHasDetails,
            opponentHeight = config.opponentHeight,
        })
    end

    local centerNode = html.create('div'):addClass('brkts-round-center')
        :addClass(bracketResetMatch and 'brkts-br-wrapper' or nil)
        :node(matchNode)
        :node(thirdPlaceHeaderNode)
        :node(thirdPlaceMatchNode)

    -- Qualifier entries
    local qualWinNode
    if match.bracketData.qualWin then
        local opponent = match.winner 
            and match.opponents[match.winner]
            or MatchGroupUtil.createOpponent({
                type = 'literal', 
                name = match.bracketData.qualWinLiteral or '',
            })
        qualWinNode = Bracket.Qualified({
            OpponentEntry = config.OpponentEntry,
            height = config.opponentHeight,
            opponent = opponent,
        })
            :css('margin-top', layout.matchMarginTop + layout.matchHeight / 2 - config.opponentHeight / 2 .. 'px')
            :css('margin-bottom', config.matchMargin .. 'px')
    end

    local qualLoseNode
    if match.bracketData.qualLose then
        local opponent = Bracket.getRunnerUpOpponent(match)
            or MatchGroupUtil.createOpponent({
                type = 'literal', 
                name = match.bracketData.qualLoseLiteral or '',
            })
        qualLoseNode = Bracket.Qualified({
            OpponentEntry = config.OpponentEntry,
            height = config.opponentHeight,
            opponent = opponent,
        })
            :css('margin-top', config.matchMargin + 6 .. 'px')
            :css('margin-bottom', config.matchMargin .. 'px')
    end

    local qualNode
    if qualWinNode or qualLoseNode then
        qualNode = html.create('div'):addClass('brkts-round-qual')
            :node(qualWinNode)
            :node(qualLoseNode)
    end

    return html.create('div'):addClass('brkts-round-body')
        :node(lowerNode)
        :node(lowerNode and Bracket.NodeLowerConnectors(props) or nil)
        :node(centerNode)
        :node(qualNode and Bracket.NodeQualConnectors(props) or nil)
        :node(qualNode)
end

--[[
Display component for a match in a bracket. Draws one row for each opponent, 
and an icon for the match summary popup.
]]
Bracket.propTypes.Match = {
    OpponentEntry = 'function',
    MatchSummaryContainer = 'function',
    match = MatchGroupUtil.types.Match,
    matchHasDetails = 'function',
    opponentHeight = 'number',
}
function Bracket.Match(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.Match)
    local matchNode = html.create('div'):addClass('brkts-match brkts-match-popup-wrapper')

    for ix, opponent in ipairs(props.match.opponents) do
        local canHighlight = DisplayHelper.opponentIsHighlightable(opponent)
        local opponentEntryNode = props.OpponentEntry({
            displayType = 'bracket',
            height = props.opponentHeight,
            opponent = opponent, 
        })
            :addClass('brkts-opponent-entry')
            :addClass(canHighlight and 'brkts-opponent-hover' or nil)
            :addClass(ix == #props.match.opponents and 'brkts-opponent-entry-last' or nil)
            :css('height', props.opponentHeight .. 'px')
            :attr('aria-label', canHighlight and DisplayHelper.makeOpponentHighlightKey2(opponent) or nil)
        matchNode:node(opponentEntryNode)
    end

    if props.matchHasDetails(props.match) then
        local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
            bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
            matchId = props.match.matchId,
        })

        local matchSummaryPopupNode = html.create('div'):addClass('brkts-match-info-popup')
            :node(matchSummaryNode)

        matchNode
            :node(
                html.create('div'):addClass('brkts-match-info-icon')
                    :css('top', #props.match.opponents * props.opponentHeight / 2 - 6 - 1 .. 'px')
            )
            :node(matchSummaryPopupNode)
    end

    return matchNode
end

--[[
Display component for a qualification spot.
]]
Bracket.propTypes.Qualified = {
    OpponentEntry = 'function',
    height = 'number',
    opponent = MatchGroupUtil.types.Opponent,
}
function Bracket.Qualified(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.Qualified)

    local canHighlight = DisplayHelper.opponentIsHighlightable(props.opponent)
    local opponentEntryNode = props.OpponentEntry({
        displayType = 'bracket-qualified',
        height = props.height,
        opponent = props.opponent, 
    })
        :addClass('brkts-opponent-entry')
        :addClass(canHighlight and 'brkts-opponent-hover' or nil)
        :css('height', props.height .. 'px')
        :attr('aria-label', canHighlight and DisplayHelper.makeOpponentHighlightKey2(props.opponent) or nil)
    
    return html.create('div'):addClass('brkts-qualified')
        :node(opponentEntryNode)
end

-- Connector lines between a match and its lower matches
Bracket.propTypes.NodeLowerConnectors = Bracket.propTypes.NodeBody
function Bracket.NodeLowerConnectors(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.NodeLowerConnectors)
    local match = props.matchesById[props.matchId]
    local layout = props.layoutsByMatchId[props.matchId]
    local config = props.config
    local lowerMatches = match.bracketData.lowerMatches

    local lowerLayouts = Array.map(
        lowerMatches,
        function(x) return props.layoutsByMatchId[x.matchId] end
    )

    -- Compute partial sums of heights of lower round matches
    local heightSums = LuaUtils.math.partialSums(
        Array.map(lowerLayouts, function(layout) return layout.height end)
    )

    -- Compute joints of connectors
    local jointIxs = {}
    local jointIxAbove = 0
    for ix = math.ceil(#lowerMatches / 2), 1, -1 do
        jointIxAbove = jointIxAbove + 1
        jointIxs[lowerMatches[ix].opponentIx] = jointIxAbove
    end
    local jointIxBelow = 0
    -- middle lower match is repeated if odd
    for ix = math.floor(#lowerMatches / 2) + 1, #lowerMatches, 1 do
        jointIxBelow = jointIxBelow + 1
        jointIxs[lowerMatches[ix].opponentIx] = jointIxBelow
    end
    local jointCount = math.max(jointIxAbove, jointIxBelow)

    --
    local lowerConnectorsNode = mw.html.create('div')
        :addClass('brkts-round-lower-connectors')
        :css('--skip-round', match.bracketData.skipRound)

    -- Draw connectors between lower round matches and this match
    for ix, x in ipairs(lowerMatches) do
        local lowerLayout = lowerLayouts[ix]
        local leftTop = layout.lowerMarginTop + heightSums[ix] + lowerLayout.mid
        local rightTop = layout.matchMarginTop + ((x.opponentIx - 1) + 0.5) * config.opponentHeight
        local jointLeft = (config.roundHorizontalMargin - 2) * jointIxs[x.opponentIx] / (jointCount + 1)

        local segment1Node = html.create('div'):addClass('brkts-line')
            :css('height', config.lineWidth .. 'px')
            :css('width', jointLeft + config.lineWidth / 2 .. 'px')
            :css('left', '0')
            :css('top', leftTop - config.lineWidth / 2 .. 'px')

        local segment2Node = html.create('div'):addClass('brkts-line')
            :css('height', math.abs(leftTop - rightTop) .. 'px')
            :css('width', config.lineWidth .. 'px')
            :css('top', math.min(leftTop, rightTop) .. 'px')
            :css('left', jointLeft - config.lineWidth / 2 .. 'px')

        local segment3Node = html.create('div'):addClass('brkts-line')
            :css('height', config.lineWidth .. 'px')
            :css('left', jointLeft - config.lineWidth / 2 .. 'px')
            :css('right', '0')
            :css('top', rightTop - config.lineWidth / 2 .. 'px')

        lowerConnectorsNode
            :node(segment1Node)
            :node(segment2Node)
            :node(segment3Node)
    end

    -- Draw line stubs for opponents not connected to a lower round match
    for opponentIx, opponent in ipairs(match.opponents) do
        local rightTop = layout.matchMarginTop + ((opponentIx - 1) + 0.5) * config.opponentHeight
        if not jointIxs[opponentIx] then
            local stubNode = html.create('div'):addClass('brkts-line')
                :css('height', config.lineWidth .. 'px')
                :css('left', 10 .. 'px')
                :css('right', '0')
                :css('top', rightTop - config.lineWidth / 2 .. 'px')
            lowerConnectorsNode:node(stubNode)
        end
    end

    return lowerConnectorsNode
end

-- Connector lines between a match and its qualified spots
Bracket.propTypes.NodeQualConnectors = Bracket.propTypes.NodeBody
function Bracket.NodeQualConnectors(props)
    DisplayUtil.assertPropTypes(props, Bracket.propTypes.NodeQualConnectors)
    local match = props.matchesById[props.matchId]
    local layout = props.layoutsByMatchId[props.matchId]
    local config = props.config

    local qualConnectorsNode = mw.html.create('div')
        :addClass('brkts-round-qual-connectors')
        :css('--qual-skip', match.bracketData.qualSkip)

    -- Qualified winner connector
    local leftTop = layout.matchMarginTop + layout.matchHeight / 2
    local lineNode = html.create('div'):addClass('brkts-line')
        :css('height', config.lineWidth .. 'px')
        :css('right', '0')
        :css('left', '0')
        :css('top', leftTop - config.lineWidth / 2 .. 'px')
    qualConnectorsNode:node(lineNode)

    -- Qualified loser connector
    if match.bracketData.qualLose then
        local rightTop = leftTop + config.opponentHeight / 2 + config.matchMargin + 6 + config.opponentHeight / 2
        local jointRight = 11

        local segment1Node = html.create('div'):addClass('brkts-line')
            :css('width', config.lineWidth .. 'px')
            :css('height', rightTop - leftTop .. 'px')
            :css('right', jointRight - config.lineWidth / 2 .. 'px')
            :css('top', leftTop .. 'px')

        local segment2Node = html.create('div'):addClass('brkts-line')
            :css('height', config.lineWidth .. 'px')
            :css('right', '0')
            :css('width', jointRight + config.lineWidth / 2 .. 'px')
            :css('top', rightTop - config.lineWidth / 2 .. 'px')

        qualConnectorsNode:node(segment1Node):node(segment2Node)
    end

    return qualConnectorsNode
end

function Bracket.getRunnerUpOpponent(match)
    -- 2 opponents: the runner up is the one that is not the winner, assuming 
    -- there is a winner
    if #match.opponents == 2 then
        return match.winner
            and match.opponents[2 - match.winner]
            or nil

    -- >2 opponents: wait for the match to be finished, then look at the placement field
    -- TODO remove match.finished requirement
    else
        return match.finished
            and Array.find(match.opponents, function(match) return match.placement == 2 end)
            or nil
    end
end

--[[
Display component for an opponent in a match. Shows the name and flag of the 
opponent, and their score. 

This is the default opponent entry component. Specific wikis may override this 
by passing in a different props.OpponentEntry in the Bracket component.
]]
function Bracket.DefaultOpponentEntry(props)
    local opponent = props.opponent

    local OpponentDisplay = require('Module:DevFlags').matchGroupDev and LuaUtils.lua.requireIfExists('Module:OpponentDisplay/dev')
        or LuaUtils.lua.requireIfExists('Module:OpponentDisplay')
        or {}
    
    if OpponentDisplay.BracketOpponentEntry then
        return OpponentDisplay.BracketOpponentEntry({
            displayType = props.displayType,
            height = props.height,
            opponent = opponent,
        })
    elseif OpponentDisplay.luaGet then
        --temp fix so that opponent extradata is available if data is inherited from storage vars
        opponent._rawRecord.extradata = Json.parseIfString(opponent._rawRecord.extradata) or opponent._rawRecord.extradata or {}
        
        local opponentEntryAny = OpponentDisplay.luaGet(
            mw.getCurrentFrame(),
            Table.mergeInto(DisplayHelper.flattenArgs(opponent._rawRecord), {
                displaytype = props.displayType,
                matchHeight = 2 * props.height,
            })
        )
        return type(opponentEntryAny) == 'string'
            and html.create('div'):wikitext(opponentEntryAny)
            or opponentEntryAny
    else
        return html.create('div')
    end
end

return Class.export(Bracket)
