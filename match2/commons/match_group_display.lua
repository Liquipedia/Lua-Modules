local Helper = require('Module:MatchGroup/Display/Helper')

local MatchGroupDisplay = {}

function MatchGroupDisplay.bracket(frame)
    local args = require('Module:Arguments').getArgs(frame)
    return MatchGroupDisplay.luaBracket(frame, args)
end

function MatchGroupDisplay.luaBracket(frame, args)
    mw.log("drawing from lua")
    local BracketDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('bracket')
    return BracketDisplay.luaGet(frame, args)
end

function MatchGroupDisplay.matchlist(frame)
    local args = require('Module:Arguments').getArgs(frame)
    return MatchGroupDisplay.luaMatchlist(frame, args)
end

function MatchGroupDisplay.luaMatchlist(frame, args, matches)
    local MatchlistDisplay = require('Module:Brkts/WikiSpecific').getMatchGroupModule('matchlist')
    return MatchlistDisplay.luaGet(frame, args, matches)
end

-- display MatchGroup (Bracket/MatchList) from ID
function MatchGroupDisplay.Display(frame)
    local args = require('Module:Arguments').getArgs(frame)
    args[1] = args.id or args[1] or ''
    local bracketId = args[1]

    local MatchGroupUtil = require('Module:MatchGroup/Util')
    local matches = MatchGroupUtil.fetchMatches(bracketId)
    if #matches == 0 then
        error('No Data found for bracketId=' .. bracketId)
    end
    local matchGroupType = matches[1].bracketData.type

    local MatchGroupModule = require('Module:Brkts/WikiSpecific').getMatchGroupModule(matchGroupType)
    return MatchGroupModule.luaGet(frame, args)
end

function MatchGroupDisplay.DisplayDev(frame)
    require('Module:DevFlags').matchGroupDev = true
    return MatchGroupDisplay.Display(frame)
end

return MatchGroupDisplay
