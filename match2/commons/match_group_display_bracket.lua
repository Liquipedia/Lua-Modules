local Bracket = {}

local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Json = require('Module:Json')
local MatchSummary = require('Module:MatchSummary')
local OpponentDisplay = require('Module:OpponentDisplay')
local Table = require('Module:Table')
local WikiSpecific = require('Module:Brkts/WikiSpecific')

local getArgs = require('Module:Arguments').getArgs
local utils = require('Module:LuaUtils')
local html = mw.html

local ZERO_WIDTH_SPACE = '&#8203;'
local COMPENSATABLE_SINGLES = 2
local NIL_EXTRADATA = {0, 0, 0, 0}
local INFINITE_HEIGHT = 10000

-- allowed values for configuring the bracket and their default values
local BRACKET_CONFIG_FORMAT = {
    emptyRoundTitles = 'boolean',
    headerHeight = 'number',
    hideMatchLine = 'boolean',
    hideRoundTitles = 'boolean',
    matchHeight = 'number',
    matchWidth = 'number',
    matchWidthMobile = 'number',
    qualifiedHeader = 'string',
    scoreWidth = 'number',
}

-- default bracket config
local BRACKET_CONFIG_DEFAULT = {
    emptyRoundTitles = false,
    headerHeight = 25,
    hideMatchLine = false,
    hideRoundTitles = false,
    matchHeight = 44,
    matchWidth = 150,
    matchWidthMobile = 90,
    qualifiedHeader = nil,
    scoreWidth = 20,
}

local _bracketConfig

local _frame
local _matches

function Bracket.get(frame)
    local args = getArgs(frame)
    return Bracket.luaGet(frame, args)
end

function Bracket.luaGet(frame, args)
    _frame = frame
    
    local bracketid = args[1]
    local matches = DisplayHelper.getMatches(bracketid)
    
    if (args.matchHeight or '') == '' then
        for id, match in utils.iter.spairs(matches) do
            args.matchHeight = WikiSpecific.get_matchHeight(match.match2opponents[1] or {}, match.match2opponents[1] or {}, args.matchHeight)
        end
    end

    local has3rd = false
    for id, match in utils.iter.spairs(matches) do
        if string.find(match.match2id or '', 'RxMTP') then
            has3rd = true 
            break
        end
    end

    _bracketConfig = _getBracketConfig(args)

    local matches, referencedIds = _mapMatches(matches, has3rd)
    _matches = matches

    out = html.create('div'):addClass('brkts-main')
    firsthead = true
    height = 0
    for id, match in utils.iter.spairs(matches) do
        if not referencedIds[match.id] then
            local extradata, node = unpack(match:buildBracket(firsthead))
            out:node(node)
            height = height + math.max(extradata[1], extradata[1] / 2 + match.minDisplayHeight)
            firsthead = false
        end
    end
    
    out:css('min-height', height .. 'px')

    return out
end

function _getBracketConfig(args)
    local globalConfig = Json.parse(tostring(mw.message.new('BracketConfig')))
    local config = {}
    for param, format in pairs(BRACKET_CONFIG_FORMAT) do
        local val = utils.misc.emptyOr(args[param], globalConfig[param], BRACKET_CONFIG_DEFAULT[param])
        if val ~= nil then
            if format == 'number' then
                config[param] = tonumber(val)
            elseif format == 'boolean' then
                config[param] = utils.misc.readBool(val)
            elseif format == 'string' then
                config[param] = tostring(val)
            end
        end
    end
    return config
end

-- define class match for easier recursive drawing
local BracketMatch = {}
BracketMatch.__index = BracketMatch

setmetatable(
    BracketMatch,
    {
        __call = function(cls, ...)
            return cls.new(...)
        end
    }
)

function BracketMatch.new(match, has3rd)
    local self = setmetatable({}, BracketMatch)

    -- set visual parameters
    self.matchHeight = _bracketConfig.matchHeight / 2
    self.lineHeight = self.matchHeight - 11
    self.padding = self.matchHeight / 2
    self.height = 2 * self.matchHeight + 2
    self.stepHeight = self.padding + 1
    self.headerHeight = _bracketConfig.headerHeight
    self.headerLineHeight = self.headerHeight - 11
    self.headerHeight2 = self.headerHeight + 10
    self.matchWidth = _bracketConfig.matchWidth + 2
    self.matchWidthMobile = _bracketConfig.matchWidthMobile + 2
    self.scoreWidth = _bracketConfig.scoreWidth

    -- set visual flags
    self.hideRoundTitles = utils.misc.readBool(_bracketConfig.hideRoundTitles)
    self.emptyRoundTitles = utils.misc.readBool(_bracketConfig.emptyRoundTitles)
    self.hideMatchLine = utils.misc.readBool(_bracketConfig.hideMatchLine)

    self.matchRaw = match
    local bracketdata =
        type(match.match2bracketdata) == 'table' and match.match2bracketdata or
        Json.parse(match.match2bracketdata or '{}')
    self.id = utils.misc.emptyOr(match.match2id)
    self.bracketid = match.match2bracketid

    -- TODO: solve this for more than 2 opponents
    self.opponent1Raw = match.match2opponents[1] or {}
    self.opponent2Raw = match.match2opponents[2] or {}
    self.opponent1 = self.opponent1Raw.name or 'TBD'
    self.opponent2 = self.opponent2Raw.name or 'TBD'
    self.opponent1score = self.opponent1Raw.score or -1
    self.opponent2score = self.opponent2Raw.score or -1
    self.opponent1template = self.opponent1Raw.template or 'tbd'
    self.opponent2template = self.opponent2Raw.template or 'tbd'
    self.opponent1players = self.opponent1Raw.match2players or {}
    self.opponent2players = self.opponent2Raw.match2players or {}
    self.opponent1type = self.opponent1Raw.type or 'team'
    self.opponent2type = self.opponent2Raw.type or 'team'
    self.finished = utils.misc.readBool(match.finished or false)
    self.games = match.match2games or {}
    self.winner = tonumber(match.winner)
    self.dateexact = utils.misc.readBool(match.dateexact)
    --self.date = Helper:parseDateString( match.date, self.dateexact )

    -- add participants data from games to opponents
    -- TODO: solve this for more than 2 opponents
    local opponentParticipants = {{}, {}}
    for index, game in ipairs(self.games) do
        local participants =
            type(game.participants) == 'table' and game.participants or Json.parse(game.participants or '{}')
        local gameparticipants = {{}, {}}
        for key, val in pairs(participants) do
            local opPl = utils.string.split(key, '_')
            if not gameparticipants[opPl[1]] then gameparticipants[opPl[1]] = {} end
            gameparticipants[opPl[1]]['p' .. opPl[2]] = val
        end
        local gameName = 'g' .. (index + 1)
        opponentParticipants[1][gameName] = gameparticipants[1]
        opponentParticipants[2][gameName] = gameparticipants[2]
    end

    self.opponent1Raw.participants = opponentParticipants[1]
    self.opponent2Raw.participants = opponentParticipants[2]

    -- parse bracketdata
    self.referencedIds = {}
    self.type = bracketdata.type or 'error'
    self.header = utils.misc.emptyOr(bracketdata.header or nil)
    self.skipround = bracketdata.skipround or 0
    if (self.skipround == 'true') then
        self.skipround = 1
    else
        self.skipround = tonumber(self.skipround) or 0
    end
    self.qualskip = bracketdata.qualskip or 0
    if (self.qualskip == 'true') then
        self.qualskip = 1
    else
        self.qualskip = tonumber(self.qualskip) or 0
    end
    self.qualwin = utils.misc.readBool(bracketdata.qualwin or 0)
    self.quallose = utils.misc.readBool(bracketdata.quallose or 0)
    self.upper = utils.misc.emptyOr(bracketdata.toupper or nil)
    self.lower = utils.misc.emptyOr(bracketdata.tolower or nil)
    self.qualwinLiteral = utils.misc.emptyOr(bracketdata.qualwinLiteral or '')
    self.qualloseLiteral = utils.misc.emptyOr(bracketdata.qualloseLiteral or '')
    self.bracketreset = utils.misc.emptyOr(bracketdata.bracketreset or nil)
    self.thirdplace = utils.misc.emptyOr(bracketdata.thirdplace or nil)
    self.opponent1Raw.displaytype = 'bracket'
    self.opponent2Raw.displaytype = 'bracket'

    -- set bracket specific visual parameters
    self.minDisplayHeight = 0
    if (self.thirdplace ~= nil) and has3rd then
        self.minDisplayHeight = 3 * self.matchHeight + 3 * self.padding + self.headerHeight + self.headerHeight2
    elseif (self.quallose) then
        self.minDisplayHeight = 3 * self.matchHeight + self.headerHeight
    end

    -- store referenced ids
    if (self.upper ~= nil) then
        self.referencedIds[self.upper] = true
    end
    if (self.lower ~= nil) then
        self.referencedIds[self.lower] = true
    end
    if (self.bracketreset ~= nil) then
        self.referencedIds[self.bracketreset] = true
    end
    if (self.thirdplace ~= nil) then
        self.referencedIds[self.thirdplace] = true
    end
    return self
end

function BracketMatch:applyTree(matches)
    self.lower = matches[self.lower or 'none']
    self.upper = matches[self.upper or 'none']
    self.bracketreset = matches[self.bracketreset or 'none']
    self.thirdplace = matches[self.thirdplace or 'none']
end

function BracketMatch:buildBracket(firsthead, isupper, single, ishead, depth, maxdepth, singledepth, headerchild)
    local upper = _matches[self.upper]
    local lower = _matches[self.lower]

    isupper = utils.misc.emptyOr(isupper, true)
    single = utils.misc.emptyOr(single, 0)
    ishead = utils.misc.emptyOr(ishead, true)
    depth = utils.misc.emptyOr(depth, 1)
    maxdepth = utils.misc.emptyOr(maxdepth, nil)
    singledepth = utils.misc.emptyOr(singledepth, 0)
    headerchild = utils.misc.emptyOr(headerchild, false)

    -- third place match and bracket reset for header matches
    local thirdplace = nil
    local bracketreset = nil
    if (firsthead) then
        thirdplace = _matches[self.thirdplace]
        bracketreset = _matches[self.bracketreset]
    end

    -- adjust match data in case of bracket reset
    local matchRaw = self.matchRaw
    if bracketreset then
        self.winner = bracketreset.winner
        matchRaw.bracketreset = bracketreset.matchRaw
    end

    if (maxdepth == nil) then
        maxdepth = self:getBracketDepth()
    end

    -- hide headers if hideRoundTitles flag is set
    if (self.hideRoundTitles) then
        self.header = nil
    elseif (self.emptyRoundTitles and self.header ~= nil) then
        self.header = ''
    end

    headerchild = self.header ~= nil or headerchild
    local wassingle = single ~= 0
    local isend = (upper == nil and lower == nil)
    local isfull = (upper ~= nil and lower ~= nil)
    local issingle = not isend and not isfull

    singledepth =
        wassingle and singledepth + single or
        (isupper and math.max(0, singledepth - COMPENSATABLE_SINGLES) or 0)

    local endSpacerDiv = html.create('div'):addClass('brkts-round-wrapper')
    for i = 1, maxdepth - depth do
        endSpacerDiv:node(html.create('div'):addClass('brkts-match-spacer'):css('height', self.matchHeight .. 'px'))
    end
    local endSpacer = {NIL_EXTRADATA, endSpacerDiv}
    local nilSpacer = {NIL_EXTRADATA, nil}

    local newdepth = depth + 1 + self.skipround

    local vals1, s1 =
        unpack(
        upper ~= nil and
            upper:buildBracket(
                firsthead,
                true,
                (lower ~= nil and 1 or 0) - 1,
                false,
                newdepth,
                maxdepth,
                singledepth,
                headerchild
            ) or
            nilSpacer
    )
    local height1, singleDepth1, endSingledepth1, midCorrection1 = unpack(vals1)
    local vals2, s2 =
        unpack(
        lower ~= nil and
            lower:buildBracket(
                firsthead,
                false,
                (upper ~= nil and -1 or 0) + 1,
                false,
                newdepth,
                maxdepth,
                singledepth,
                issingle and headerchild
            ) or
            (upper ~= nil and nilSpacer or endSpacer)
    )
    local height2, singleDepth2, endSingledepth2, midCorrection2 = unpack(vals2)

    local ownHeight =
        self.height + self.padding + (headerchild and self.headerHeight2 or 0) +
        math.max(singledepth, self.qualwin and self.quallose and 1 or 0) * self.stepHeight
    local endSingleDepth = isend and singledepth or (upper == nil and endSingledepth2 or 0)
    local uppermid = height1 / 2 - midCorrection1
    local upperinset = height1 - uppermid
    local lowermid = height2 / 2 + midCorrection2

    -- adjust mid position for two child matches/one child match/no child matches
    local midCorrection = 0
    if (isfull) then
        midCorrection = (uppermid - lowermid) / 2
    elseif (issingle) then
        midCorrection = -self.stepHeight
    elseif (isend) then
        midCorrection =
            (headerchild and self.headerHeight2 / 2 or 0) +
            (singledepth - (self.qualwin and self.quallose and 1 or 0)) * self.stepHeight / 2
    end

    midCorrection = midCorrection + midCorrection1 + midCorrection2
    maxHeight = math.max(ownHeight, height1 + height2)
    lineheight = maxHeight / 2 + midCorrection - self.padding - upperinset
    local marginTop = maxHeight / 2 
        - self.height / 2 
        - (headerchild and self.headerHeight + 8 or 0) 
        + midCorrection

    local op1, op2 = unpack(_createOpponentData(self, bracketreset))
    local opponent1node, opponent1hash, tbd1 = unpack(op1)
    local opponent2node, opponent2hash, tbd2 = unpack(op2)
    
    local hasDetails = WikiSpecific.matchHasDetails(self)

    local extendUpperTop = self.matchHeight - INFINITE_HEIGHT

    local headerText = self.header
    if (not utils.misc.isEmpty(self.header) and (utils.table.includes({'$', '!'}, self.header:sub(1, 1)))) then
        options = _getHeaderOptions(self.header)
        headerText = options[1]
        for i, option in ipairs(options) do
            headerText = headerText .. tostring(html.create('div'):addClass('brkts-header-option'):node(option))
        end
    end

    local header =
        (self.header == nil) and '' or
        html.create('div'):addClass(
            'brkts-header-div brkts-header' ..
                (isend and ' brkts-header-end' or (self.skipround > 0 and ' brkts-header-skip-' .. self.skipround or ''))
        ):css('position', 'initial'):css('display', 'block'):node(self.emptyRoundTitles and '' or headerText .. ZERO_WIDTH_SPACE):cssText(
            'height:' .. self.headerHeight .. 'px;line-height:' .. self.headerLineHeight .. 'px;'
        )

    local match =
        html.create('div'):addClass(
        'brkts-match brkts-match-popup-wrapper' .. (wassingle and ' brkts-match-single' or '')
    ):node(
        html.create('div'):addClass('brkts-teamscore' .. (not tbd1 and ' brkts-opponent-hover' or '')):node(
            html.create('div'):addClass('brkts-team' .. (self.hideMatchLine and '' or ' brkts-team-upper')):node(
                opponent1node
            ):cssText('height:' .. self.matchHeight .. 'px;')
        ):node(
            html.create('div'):addClass('brkts-extend' .. ((isupper or wassingle) and ' brkts-extend-upper' or '')):cssText(
                (isupper or wassingle) and ('top:' .. extendUpperTop .. 'px') or ''
            )
        ):attr('aria-label', opponent1hash)
    ):node(
        html.create('div'):addClass('brkts-teamscore' .. (not tbd2 and ' brkts-opponent-hover' or '')):node(
            html.create('div'):addClass('brkts-team brkts-team-lower'):node(opponent2node):cssText(
                'height:' .. self.matchHeight .. 'px;'
            )
        ):node(
            html.create('div'):addClass('brkts-extend' .. ((isupper or wassingle) and ' brkts-extend-lower' or '')):cssText(
                (isupper or wassingle) and ('top:' .. extendUpperTop .. 'px') or ''
            )
        ):attr('aria-label', opponent2hash)
    ):node(
        not hasDetails and '' or
            html.create('div'):addClass('brkts-match-info'):node(html.create('div'):addClass('brkts-match-info-icon')):node(
                html.create('div'):addClass('brkts-match-info-popup'):css('max-height', '80vh'):css('overflow', 'auto'):node(
                    MatchSummary.luaGet(_frame, DisplayHelper.flattenArgs(matchRaw))
                ):cssText('display:none')
            )
    )

    local thirdplacematch = ''
    local thirdPlaceHeaderNode
    if thirdplace then
        local headerOptionsTP = _getHeaderOptions('tp')
        local headerTextTP = headerOptionsTP[1]     
        for i, option in ipairs(headerOptionsTP) do
            headerTextTP = headerTextTP .. tostring(html.create('div'):addClass('brkts-header-option'):node(option))
        end

        local thirdplaceheight = 2 * self.matchHeight + self.padding + self.headerHeight2

        local op1TP, op2TP = unpack(_createOpponentData(thirdplace))
        local opponent1nodeTP, opponent1hashTP, tbd1TP = unpack(op1TP)
        local opponent2nodeTP, opponent2hashTP, tbd2TP = unpack(op2TP)

        local hasDetailsTP = WikiSpecific.matchHasDetails(thirdplace)
        
        thirdPlaceHeaderNode = html.create('div')
            :addClass('brkts-header brkts-header-div brkts-3rd-header')
            :node(headerTextTP)
            :cssText('height:' .. self.headerHeight .. 'px;')
            :css('display', 'block')
            :css('position', 'initial')
            :css('margin-top', '28px')
        thirdplacematch =
            html.create('div'):addClass('brkts-match brkts-match-popup-wrapper brkts-3rd-place-wrapper')
            --:css('margin-left', 'calc(var(--line-horizontal-length) - 2px)')
            :css('margin-left', '8px')
            :css('left', 'initial')
            :css('display', 'block')
            :node(
            html.create('div'):addClass('brkts-teamscore' .. (not tbd1TP and ' brkts-opponent-hover' or '')):node(
                html.create('div'):addClass('brkts-team' .. (self.hideMatchLine and '' or ' brkts-team-upper')):node(
                    tostring(opponent1nodeTP) .. ZERO_WIDTH_SPACE
                ):cssText('height' .. self.matchHeight .. 'px;')
            ):node(
                html.create('div'):addClass('brkts-extend' .. ((isupper or wassingle) and ' brkts-extend-upper' or '')):cssText(
                    (isupper or wassingle) and ('top:' .. extendUpperTop .. 'px') or ''
                )
            ):attr('aria-label', opponent1hashTP)
        ):node(
            html.create('div'):addClass('brkts-teamscore' .. (not tbd2TP and ' brkts-opponent-hover' or '')):node(
                html.create('div'):addClass('brkts-team brkts-team-lower'):node(tostring(opponent2nodeTP) .. ZERO_WIDTH_SPACE):cssText(
                    'height' .. self.matchHeight .. 'px;'
                )
            ):node(
                html.create('div'):addClass('brkts-extend' .. ((isupper or wassingle) and ' brkts-extend-lower' or '')):cssText(
                    (isupper or wassingle) and ('top:' .. extendUpperTop .. 'px') or ''
                )
            ):attr('aria-label', opponent2hashTP)
        ):node(
            hasDetailsTP and
                html.create('div'):addClass('brkts-match-info'):node(
                    html.create('div'):addClass('brkts-match-info-icon')
                ):node(
                    html.create('div'):addClass('brkts-match-info-popup'):css('max-height', '80vh'):css('overflow', 'auto'):node(
                        MatchSummary.luaGet(_frame, DisplayHelper.flattenArgs(thirdplace.matchRaw))
                    ):cssText('display:none')
                ) or
                ''
        )
    end

    local skiproundConnector =
        self.skipround > 0 and
        html.create('div'):addClass('brkts-line-container'):node(
            html.create('div'):addClass('brkts-line-horizontal-long')
        ):node(
            html.create('div'):addClass('brkts-line-spacer brkts-line-spacer-upper'):cssText(
                'height:' .. self.padding .. 'px'
            )
        ):node(
            html.create('div'):addClass('brkts-line-spacer brkts-line-spacer-lower'):cssText(
                'height:' .. self.padding .. 'px'
            )
        ):node(html.create('div'):addClass('brkts-line-horizontal-long')) or
        ''
    skiproundConnector = tostring(skiproundConnector):rep(self.skipround)
    local qualskipConnector =
        self.qualskip > 0 and
        html.create('div'):addClass('brkts-line-container'):node(
            html.create('div'):addClass('brkts-line-horizontal-long')
        ) or
        ''
    qualskipConnector = tostring(qualskipConnector):rep(self.qualskip)

    -- qualified header
    local qualText = _bracketConfig.qualifiedHeader
    if (firsthead and ishead and self.qualwin and utils.misc.isEmpty(qualText)) then
        local qualOptions = _getHeaderOptions('q')
        qualText = qualOptions[1]
        for i, option in ipairs(qualOptions) do
            qualText = qualText .. tostring(html.create('div'):addClass('brkts-header-option'):node(option))
        end
    end

    -- literals for qualifiers
    local getQualwinLiteral = function()
        return OpponentDisplay.luaGet(
            _frame,
            {displaytype = 'bracket-qualified', type = 'literal', name = self.qualwinLiteral}
        )
    end
    local getQualloseLiteral = function()
        return OpponentDisplay.luaGet(
            _frame,
            {displaytype = 'bracket-qualified', type = 'literal', name = self.qualloseLiteral}
        )
    end

    -- TODO
    local getOpponent1QualifiedNode = function()
        return OpponentDisplay.luaGet(_frame, _addDisplayTypeAndMatchHeight(DisplayHelper.flattenArgs(self.opponent1Raw), 'bracket-qualified'))
    end
    local getOpponent2QualifiedNode = function()
        return OpponentDisplay.luaGet(_frame, _addDisplayTypeAndMatchHeight(DisplayHelper.flattenArgs(self.opponent2Raw), 'bracket-qualified'))
    end

    local qualwinContainer =
        (ishead and self.qualwin) and
        html.create('div'):addClass('brkts-header-wrapper'):css('display', 'block'):node(
            firsthead and not self.hideRoundTitles and
                html.create('div'):addClass('brkts-header-div brkts-header brkts-header-qual-skip-' .. self.qualskip):node(
                    (self.emptyRoundTitles and '' or qualText) .. ZERO_WIDTH_SPACE
                ):cssText('height:' .. self.headerHeight .. 'px;line-height:' .. self.headerLineHeight .. 'px;') or
                ''
        ):node(
            html.create('div'):addClass('brkts-qualified-container'):node(
                html.create('div'):addClass('brkts-line-container'):node(
                    html.create('div'):addClass('brkts-line-horizontal-single')
                )
            ):node(qualskipConnector):node(
                html.create('div'):addClass(
                    'brkts-qualified' .. ((not tbd1 and not tbd2) and self.finished and ' brkts-opponent-hover' or '')
                ):node(
                    (self.winner == 1) and getOpponent1QualifiedNode() or
                        (self.winner == 2 and getOpponent2QualifiedNode() or getQualwinLiteral())
                ):cssText('height' .. self.matchHeight .. 'px'):attr(
                    'aria-label',
                    self.winner == 1 and opponent1hash or opponent2hash
                )
            ):cssText('margin-top:' .. _pxFix(maxHeight / 2 + midCorrection - self.padding - 8) .. 'px;')
        ):node(
            self.quallose and
                html.create('div'):addClass('brkts-qualified-container'):node(
                    html.create('div'):addClass('brkts-line brkts-line-qualified'):cssText(
                        'height:' .. (self.matchHeight + 13) .. 'px;top:' .. (-self.padding - 8) .. 'px'
                    )
                ):node(
                    html.create('div'):addClass('brkts-line-container'):node(
                        html.create('div'):addClass('brkts-line-horizontal-single')
                    )
                ):node(qualskipConnector):node(
                    html.create('div'):addClass(
                        'brkts-qualified' ..
                            ((not tbd1 and not tbd2) and self.finished and ' brkts-opponent-hover' or '')
                    ):node(
                        self.winner == 1 and getOpponent2QualifiedNode() or
                            (self.winner == 2 and getOpponent1QualifiedNode() or getQualwinLiteral())
                    ):cssText('margin-top:2px;height:' .. self.matchHeight .. 'px'):attr(
                        'aria-label',
                        self.winner == 1 and opponent2hash or opponent1hash
                    )
                ):cssText('position: absolute;') or
                ''
        ):cssText('height:' .. maxHeight .. 'px;') or
        ''

    local out =
        html.create('div'):addClass('brkts-match-wrapper'):css('display', 'block'):node(isend and '' or skiproundConnector):node(
        isend and '' or
            html.create('div'):addClass('brkts-line-container'):node(
                html.create('div'):addClass('brkts-line-horizontal')
            ):node(
                html.create('div'):addClass('brkts-line-spacer brkts-line-spacer-upper'):cssText(
                    'height:' .. self.padding .. 'px'
                )
            ):node(
                html.create('div'):addClass('brkts-line-spacer brkts-line-spacer-lower'):cssText(
                    'height:' .. self.padding .. 'px'
                )
            ):node(html.create('div'):addClass('brkts-line-horizontal'))
    ):node(match):node(
        (ishead and not self.qualwin) and '' or
            html.create('div'):addClass('brkts-line-container'):node(
                html.create('div'):addClass(
                    (wassingle or self.qualwin) and 'brkts-line-horizontal-single' or 'brkts-line-horizontal'
                )
            )
    ):cssText('margin-top:' .. _pxFix(marginTop) .. 'px')

    out =
        html.create('div'):addClass('brkts-header-wrapper' .. (bracketreset ~= nil and ' brkts-br-wrapper' or '')):css('display', 'block'):node(
        header
    ):node(out):node(thirdPlaceHeaderNode):node(thirdplacematch):cssText('height:' .. maxHeight .. 'px;')

    out =
        html.create('div'):addClass('brkts-round-wrapper' .. (wassingle and ' brkts-round-wrapper-single' or '')):css('align-items', 'flex-start'):node(
        html.create('div'):addClass('brkts-round'):node(s1):node(s2)
    ):node(
        not isfull and '' or
            html.create('div'):addClass('brkts-line-container2'):node(
                html.create('div'):addClass('brkts-line'):cssText(
                    'height:' .. lineheight .. 'px;margin-top:' .. upperinset .. 'px;'
                )
            ):node(
                html.create('div'):addClass('brkts-line'):cssText(
                    'height:' .. lineheight .. 'px;margin-top:' .. (2 * self.padding) .. 'px;'
                )
            )
    ):node(out):node(qualwinContainer)

    if ishead then
        out =
            html.create('div'):addClass('brkts-bracket'):cssText(
            '--match-height:' ..
                self.matchHeight ..
                    'px;--match-width:' ..
                        self.matchWidth ..
                            'px;--match-width-mobile:' ..
                                self.matchWidthMobile .. 'px;--score-width:' .. self.scoreWidth .. 'px;'
        ):node(out)
    end

    return {{maxHeight, singledepth, endSingleDepth, midCorrection}, out}
end

function BracketMatch:getBracketDepth()
    local upper = _matches[self.upper or 'none']
    local lower = _matches[self.lower or 'none']
    local upperdepth = upper ~= nil and upper:getBracketDepth() or 0
    local lowerdepth = lower ~= nil and lower:getBracketDepth() or 0

    return 1 + self.skipround + math.max(upperdepth, lowerdepth)
end

function _pxFix(height)
    return height + (height == math.floor(height) and 0 or 0.2)
end

function _mapMatches(lpdbMatches, has3rd)
    local referencedIds = {}
    local matches = {}
    for i, matchData in ipairs(lpdbMatches) do
        local match = BracketMatch(matchData, has3rd)
        matches[match.id] = match
        for id, val in pairs(match.referencedIds) do
            referencedIds[id] = val
        end
    end
    return matches, referencedIds
end

function _addDisplayTypeAndMatchHeight(args, displayType)
    args.displaytype = displayType
    args.matchHeight = _bracketConfig.matchHeight
    return args
end

function _getHeaderOptions(headerCode)
    local args = utils.string.split(headerCode:gsub('$', '!'), '!')
    index = 1
    if (utils.misc.isEmpty(args[1])) then
        index = 2
    end
    local options =
        utils.string.split(mw.message.new('brkts-header-' .. args[index]):params(args[index + 1] or ''):plain(), ',')
    return options
end

function _createOpponentData(match, bracketReset)
    local opponent1data = match.opponent1Raw
    local opponent2data = match.opponent2Raw

    -- append score templates of bracket reset
    if bracketReset then
        local bracketResetData1 = bracketReset.opponent1Raw
        local bracketResetData2 = bracketReset.opponent2Raw
        opponent1data.score2 = bracketResetData1.score
        opponent2data.score2 = bracketResetData2.score
        opponent1data.status2 = bracketResetData1.status
        opponent2data.status2 = bracketResetData2.status
        opponent1data.placement2 = bracketResetData1.placement
        opponent2data.placement2 = bracketResetData2.placement
    end

    -- handle TBD
    local tbd1 =
        match.opponent1template == 'tbd' or match.opponent1 == 'TBD' or
        utils.string.startsWith(opponent1data.type, 'literal')
    local tbd2 =
        match.opponent2template == 'tbd' or match.opponent2 == 'TBD' or
        utils.string.startsWith(opponent2data.type, 'literal')

    -- nodes for opponents
    opponent1node = OpponentDisplay.luaGet(_frame, _addDisplayTypeAndMatchHeight(DisplayHelper.flattenArgs(opponent1data), 'bracket'))
    opponent2node = OpponentDisplay.luaGet(_frame, _addDisplayTypeAndMatchHeight(DisplayHelper.flattenArgs(opponent2data), 'bracket'))

    -- hash opponent name, template and players for making them uniquely identifyable
    -- players are only hashed for non-team opponent types like solo/duo
    opponent1hash = DisplayHelper.getOpponentHighlightKey(opponent1data)
    opponent2hash = DisplayHelper.getOpponentHighlightKey(opponent2data)

    return {
        {opponent1node, opponent1hash, tbd1},
        {opponent2node, opponent2hash, tbd2}
    }
end

return Bracket
