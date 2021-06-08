local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local Json = require('Module:Json')
local LuaUtils = require('Module:LuaUtils')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local html = mw.html

local Matchlist = {propTypes = {}, types = {}}

-- Called by MatchGroup/Display
function Matchlist.luaGet(_, args)
    return Matchlist.MatchlistContainer({
        bracketId = args[1],
        config = Matchlist.configFromArgs(args),
    })
end

Matchlist.configFromArgs = function(args)
    return {
        attached = LuaUtils.misc.readBool(args.attached),
        collapsed = LuaUtils.misc.readBool(args.collapsed),
        collapsible = not LuaUtils.misc.readBool(args.nocollapse),
        width = tonumber(string.gsub(args.width or '', 'px', ''), nil),
    }
end

Matchlist.types.MatchlistConfig = TypeUtil.struct({
    MatchSummaryContainer = 'function',
    Opponent = 'function',
    Score = 'function',
    attached = 'boolean',
    collapsed = 'boolean',
    collapsible = 'boolean',
    matchHasDetails = 'function',
    width = 'number',
})
Matchlist.types.MatchlistConfigOptions = TypeUtil.struct(
    Table.mapValues(Matchlist.types.MatchlistConfig.struct, TypeUtil.optional)
)

--[[
Display component for a tournament matchlist. The matchlist is specified by ID. 
The component fetches the match data from LPDB or page variables.
]]
Matchlist.propTypes.MatchlistContainer = {
    bracketId = 'string',
    config = TypeUtil.optional(Matchlist.types.MatchlistConfigOptions),
}
function Matchlist.MatchlistContainer(props)
    DisplayUtil.assertPropTypes(props, Matchlist.propTypes.MatchlistContainer)
    return Matchlist.Matchlist({
        config = props.config,
        matches = MatchGroupUtil.fetchMatches(props.bracketId),
    })
end

--[[
Display component for a tournament matchlist. Match data is specified in the 
input.
]] 
Matchlist.propTypes.Matchlist = {
    config = TypeUtil.optional(Matchlist.types.MatchlistConfigOptions),
    matches = TypeUtil.array(MatchGroupUtil.types.Match),
}
function Matchlist.Matchlist(props)
    DisplayUtil.assertPropTypes(props, Matchlist.propTypes.Matchlist)

    local propsConfig = props.config or {}
    local config = {
        MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
        Opponent = propsConfig.Opponent or Matchlist.DefaultOpponent,
        Score = propsConfig.Score or Matchlist.DefaultScore,
        attached = propsConfig.attached or false,
        collapsed = propsConfig.collapsed or false,
        collapsible = LuaUtils.misc.emptyOr(propsConfig.collapsible, true),
        matchHasDetails = propsConfig.matchHasDetails or DisplayHelper.defaultMatchHasDetails,
        width = propsConfig.width or 300,
    }

    local tableNode = html.create('table')
        :addClass('brkts-matchlist wikitable wikitable-bordered matchlist')
        :addClass(config.collapsible and 'collapsible' or nil)
        :addClass(config.collapsed and 'collapsed' or nil)
        :cssText(config.attached and 'margin-bottom:-1px;margin-top:-2px' or nil)
        :css('width', config.width .. 'px')
    
    for index, match in ipairs(props.matches) do
        local titleNode = index == 1
            and Matchlist.Title({title = match.bracketData.title or 'Match List'})
            or nil

        local headerNode = match.bracketData.header
            and Matchlist.Header({header = match.bracketData.header})
            or nil
        
        local matchNode = Matchlist.Match({
            MatchSummaryContainer = config.MatchSummaryContainer,
            Opponent = config.Opponent,
            Score = config.Score,
            match = match, 
            matchHasDetails = config.matchHasDetails
        })
        
        tableNode
            :node(titleNode)
            :node(headerNode)
            :node(matchNode)
    end
    
    return html.create('div'):addClass('brkts-main')
        :cssText(config.attached and 'padding-left:0px;padding-right:0px' or nil)
        :node(tableNode)
end

--[[
Display component for a match in a matchlist. Consists of two opponents, two 
scores, and a icon for the match summary popup.
]]
Matchlist.propTypes.Match = {
    MatchSummaryContainer = 'function',
    Opponent = 'function',
    Score = 'function',
    match = MatchGroupUtil.types.Match,
    matchHasDetails = 'function',
}
function Matchlist.Match(props)
    DisplayUtil.assertPropTypes(props, Matchlist.propTypes.Match)
    local match = props.match
    
    local renderOpponent = function(opponentIx)
        local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

        local canHighlight = DisplayHelper.opponentIsHighlightable(opponent)
        local opponentNode = props.Opponent({
            opponent = opponent,
            side = opponentIx == 1 and 'left' or 'right',
        })
        return html.create('td')
            :addClass('brkts-matchlist-slot')
            :addClass(canHighlight and 'brkts-opponent-hover' or nil)
            :addClass(match.winner == opponentIx and 'brkts-matchlist-slot-winner' or nil)
            :addClass(match.resultType == 'draw' and 'brkts-matchlist-slot-bold bg-draw' or nil)
            :attr('aria-label', canHighlight and DisplayHelper.makeOpponentHighlightKey2(opponent) or nil)
            :attr('width', '40%')
            :attr('align', opponentIx == 1 and 'right' or 'left')
            :node(opponentNode)
    end

    local renderScore = function(opponentIx)
        local opponent = match.opponents[opponentIx] or MatchGroupUtil.createOpponent({})

        local canHighlight = DisplayHelper.opponentIsHighlightable(opponent)
        local scoreNode = props.Score({
            opponent = opponent,
            side = opponentIx == 1 and 'left' or 'right',
        })
        return html.create('td')
            :addClass('brkts-matchlist-slot')
            :addClass(canHighlight and 'brkts-opponent-hover' or nil)
            :addClass((match.winner == opponentIx or match.resultType == 'draw') and 'brkts-matchlist-slot-bold' or nil)
            :attr('aria-label', canHighlight and DisplayHelper.makeOpponentHighlightKey2(opponent) or nil)
            :attr('width', '10.8%')
            :attr('align', 'center')
            :node(scoreNode)
    end

    local matchInfo
    if props.matchHasDetails(match) then
        local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
            bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
            matchId = props.match.matchId,
        })

        local matchSummaryPopupNode = html.create('div')
            :addClass('brkts-match-info-popup')
            :css('max-height', '80vh')
            :css('overflow', 'auto')
            :css('display', 'none')
            :node(matchSummaryNode)

        matchInfo = html.create('td')
            :addClass('brkts-match-info brkts-empty-td')
            :node(
                html.create('div')
                    :addClass('brkts-match-info-icon')
            )
            :node(matchSummaryPopupNode)
    end

    return html.create('tr')
        :addClass('brtks-matchlist-row brkts-match-popup-wrapper')
        :css('cursor', 'pointer')
        :node(renderOpponent(1))
        :node(renderScore(1))
        :node(matchInfo)
        :node(renderScore(2))
        :node(renderOpponent(2))
end

--[[
Display component for a title in a matchlist.
]]
Matchlist.propTypes.Title = {
    title = 'string',
}
function Matchlist.Title(props)
    DisplayUtil.assertPropTypes(props, Matchlist.propTypes.Title)
    return html.create('th')
        :addClass('brkts-matchlist-title')
        :attr('colspan', '5')
        :node(
            html.create('center')
                :wikitext(props.title)
        )
end

--[[
Display component for a header in a matchlist.
]]
Matchlist.propTypes.Header = {
    header = 'string',
}
function Matchlist.Header(props)
    DisplayUtil.assertPropTypes(props, Matchlist.propTypes.Header)
    return html.create('th')
        :addClass('brkts-matchlist-header')
        :attr('colspan', '5')
        :node(
            html.create('center')
                :wikitext(props.header)
        )
end

--[[
Display component for an opponent in a matchlist. 

This is the default implementation. Specific wikis may override this by passing 
in a different props.Opponent in the Matchlist component.
]]
function Matchlist.DefaultOpponent(props)
    local opponent = props.opponent

    --temp fix so that opponent extradata is available if data is inherited from storage vars
    opponent._rawRecord.extradata = Json.parseIfString(opponent._rawRecord.extradata) or {}
    for _, playerRecord in ipairs(opponent._rawRecord.match2players) do
        playerRecord.extradata = Json.parseIfString(playerRecord.extradata) or {}
    end
    
    local OpponentDisplay = require('Module:DevFlags').matchGroupDev and LuaUtils.lua.requireIfExists('Module:OpponentDisplay/dev')
        or LuaUtils.lua.requireIfExists('Module:OpponentDisplay')
        or {}
    return OpponentDisplay.luaGet(
        mw.getCurrentFrame(),
        Table.mergeInto(DisplayHelper.flattenArgs(opponent._rawRecord), {
            displaytype = props.side == 'left' and 'matchlist-left' or 'matchlist-right',
        })
    )
end


--[[
Display component for the score of an opponent in a matchlist. 

This is the default implementation. Specific wikis may override this by passing 
in a different props.Score in the Matchlist component.
]]
function Matchlist.DefaultScore(props)
    local opponent = props.opponent

    --temp fix so that opponent extradata is available if data is inherited from storage vars
    opponent._rawRecord.extradata = Json.parseIfString(opponent._rawRecord.extradata) or {}
    for _, playerRecord in ipairs(opponent._rawRecord.match2players) do
        playerRecord.extradata = Json.parseIfString(playerRecord.extradata) or {}
    end
    
    local OpponentDisplay = require('Module:DevFlags').matchGroupDev and LuaUtils.lua.requireIfExists('Module:OpponentDisplay/dev')
        or LuaUtils.lua.requireIfExists('Module:OpponentDisplay')
        or {}
    return OpponentDisplay.luaGet(
        mw.getCurrentFrame(),
        Table.mergeInto(DisplayHelper.flattenArgs(opponent._rawRecord), {
            displaytype = props.side == 'left' and 'matchlist-left-score' or 'matchlist-right-score',
        })
    )
end

return Class.export(Matchlist)
