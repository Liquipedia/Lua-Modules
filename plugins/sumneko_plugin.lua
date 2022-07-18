--@Author Rath
--Made for Liquipedia
--For use with sumneko-lua vscode/neovim extension

local liquipedia = {}

local importFunctions = {}
importFunctions.functions = {'require', 'mw%.loadData', 'Lua%.import', 'Lua%.requireIfExists', 'Lua%.loadDataIfExists'}
importFunctions.prefixModules = {table = 'standard.', math = 'standard.', string = 'standard.'}

function importFunctions._row(name)
    local normModuleName =
        name
            :gsub('Module:', '') -- Remove starting Module:
            :gsub('^%u', string.lower) -- Lower case first letter
            :gsub('%u', '_%0') -- Prefix uppercase letters with an underscore
            :gsub('/', '_') -- Change slash to underscore
            :gsub('__', '_') -- Never have two underscores in a row
            :lower() -- Lowercase everything

    if importFunctions.prefixModules[normModuleName] then
        normModuleName = importFunctions.prefixModules[normModuleName] .. normModuleName
    end

    return ' ---@module \'' .. normModuleName ..'\''
end

function importFunctions.annotate(text, funcName, diffs)
    for module, positionEndOfRow in text:gmatch(funcName .. '%s*%(?%s*[\'"](.-)[\'"]%s*%)?.-()\r?\n') do
        table.insert(diffs, {start = positionEndOfRow, finish = positionEndOfRow, text = importFunctions._row(module)})
    end
end

function liquipedia.annotate(text, diffs)
    for _, funcName in pairs(importFunctions.functions) do
        importFunctions.annotate(text, funcName, diffs)
    end
end

-- luacheck: push ignore
-- setting non-standard global variable 'OnSetText' (but it's mandatory)
function OnSetText(uri, text)
-- luacheck: pop ignore
    if text:sub(1, 3) ~= '---' then
        return nil
    end

    local diffs = {}

    liquipedia.annotate(text, diffs)

    return diffs
end
