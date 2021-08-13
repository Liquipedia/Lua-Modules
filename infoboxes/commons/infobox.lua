---
-- @author Vogan for Liquipedia
--
--

local Class = require('Module:Class')
local Links = require('Module:Links')
local Table = require('Module:Table')
local Cell = function()
    return require('Module:Infobox/Cell')
end

local Infobox = Class.new()

--- Inits the Infobox instance
function Infobox:create(frame, gameName)
    self.frame = frame
    self.root = mw.html.create('div')
    self.adbox = mw.html.create('div')  :addClass('fo-nttax-infobox-adbox')
                                        :addClass('wiki-bordercolor-light')
                                        :node(self.frame:preprocess('<adbox />'))
    self.content = mw.html.create('div')    :addClass('fo-nttax-infobox')
                                            :addClass('wiki-bordercolor-light')
    self.root   :addClass('fo-nttax-infobox-wrapper')
                :addClass('infobox-' .. gameName)
    return self
end

function Infobox:name(name)
    local pagename = name or mw.title.getCurrentTitle().text
    local infoboxHeader = mw.html.create('div'):addClass('infobox-header')
    infoboxHeader:wikitext(pagename)
    infoboxHeader   :addClass('infobox-header')
                    :addClass('wiki-backgroundcolor-light')
                    :node(self:_createInfoboxButtons())
    self.content:node(mw.html.create('div'):node(infoboxHeader))
    return self
end

function Infobox:image(fileName, default)
    if (fileName == nil or fileName == '') and (default == nil or default == '') then
        return self
    end

    local infoboxImage = mw.html.create('div'):addClass('infobox-image')
    local fullFileName = '[[File:' .. (fileName or default) .. '|center|600px]]'
    infoboxImage:wikitext(self.frame:preprocess('{{#metaimage:' .. (fileName or '') .. '}}') .. fullFileName)
    self.content:node(mw.html.create('div'):node(infoboxImage))
    return self
end

function Infobox:header(infoDescription, shouldBeVisible)
    if shouldBeVisible == nil or shouldBeVisible == false then
        return self
    end

    local header = mw.html.create('div')
    header  :addClass('infobox-header')
            :addClass('wiki-backgroundcolor-light')
            :addClass('infobox-header-2')
            :wikitext(infoDescription)
    self.content:node(mw.html.create('div'):node(header))
    return self
end

--- Build a cell using Module:Infobox/Cell
function Infobox:cell(description, content)
    if content == nil or content == '' then
        return self
    end

    local cell = Cell() :new(description)
                        :options({})
                        :content(content)
                        :make()

    Infobox:fcell(cell)
    return self
end

function Infobox:fcell(cell)
    if cell == nil or cell == '' then
        return self
    end

    if cell['is_a'] ~= nil then
        return error('Infobox:fcell received a Cell object, have you forgotten to call make()?')
    end

    self.content:node(cell)
    return self

end

function Infobox:chronology(links)
    if links == nil or Table.size(links) == 0 then
        return self
    end

    self.chronologyContent = mw.html.create('div')
    self:_createChronologyRow(links['previous'], links['next'])

    local index = 2
    local previous = links['previous' .. index]
    local next = links['next' .. index]
    while (previous ~= nil or next ~= nil) do
        self:_createChronologyRow(previous, next)

        previous = links['previous' .. index]
        next = links['next' .. index]
    end

    return self
end

function Infobox:_createChronologyRow(previous, next)
    local doesPreviousExist = previous ~= nil and previous ~= ''
    local doesNextExist = next ~= nil and next ~= ''

    if not doesPreviousExist and not doesNextExist then
        return self
    end

    local node = mw.html.create('div')

    if doesPreviousExist then 
        local previousWrapper = mw.html.create('div')
        previousWrapper :addClass('infobox-cell-2')
                        :addClass('infobox-text-left')

        local previousArrow = mw.html.create('div')
        previousArrow   :addClass('infobox-arrow-icon')
                        :css('float', 'left')
                        :wikitext('[[File:Arrow sans left.svg|link=' .. previous .. ']]')

        previousWrapper :node(previousArrow)
                        :wikitext('&nbsp;[[' .. previous .. ']]') 

        node:node(previousWrapper)
    end

    if doesNextExist then
        local nextWrapper = mw.html.create('div')
        nextWrapper :addClass('infobox-cell-2')
                    :addClass('infobox-text-right')

        local nextArrow = mw.html.create('div')
        nextArrow       :addClass('infobox-arrow-icon')
                        :css('float', 'right')
                        :wikitext('[[File:Arrow sans right.svg|link=' .. next .. ']]')

        nextWrapper :wikitext('[[' .. next .. ']]&nbsp;') 
                    :node(nextArrow)

        node:node(nextWrapper)
    end

    self.chronology:node(node)
    return self
end

function Infobox:_createInfoboxButtons()
    local rootFrame
    local currentFrame = mw.getCurrentFrame()
    while currentFrame ~= nil do
        rootFrame = currentFrame
        currentFrame = currentFrame:getParent()
    end

    local moduleTitle = rootFrame:getTitle()

    local buttons = mw.html.create('span')
    buttons:addClass('infobox-buttons')
    buttons:node(
        mw.text.nowiki('[') .. '[' .. mw.site.server ..
        tostring(mw.uri.localUrl( mw.title.getCurrentTitle().prefixedText, 'action=edit&section=0' )) ..
        ' e]' .. mw.text.nowiki(']')
    )
    buttons:node(
        mw.text.nowiki('[') ..
        '[[' .. moduleTitle ..
        '/doc|h]]' .. mw.text.nowiki(']')
    )

    return buttons
end

function Infobox:links(links)
    local infoboxLinks = mw.html.create('div')
    infoboxLinks    :addClass('infobox-center')
                    :addClass('infobox-icons')

    for key, value in pairs(links) do
		local iconString = Infobox.getIconString(key)
        local link = '[' .. Links.makeFullLink(key, value) .. ' <i class="lp-icon lp-' .. iconString .. '></i>]'
        infoboxLinks:wikitext(' ' .. link)
    end

    self.content:node(mw.html.create('div'):node(infoboxLinks))
    return self
end

function Infobox.getIconString(key)
	return string.gsub(key, '%d$', '')
end

function Infobox:centeredCell(content)
    if content == nil then
        return self
    end

    local infoboxCenteredCell = mw.html.create('div'):addClass('infobox-center')
    infoboxCenteredCell:wikitext(content)
    self.content:node(mw.html.create('div'):node(infoboxCenteredCell))
    return self
end

function Infobox:customCell(contents)
    if type(contents) ~= 'table' or contents == {} then
        return self
    end

    local div = mw.html.create('div')
    local number = #contents
    for _, content in ipairs(contents) do 
        local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number .. ' infobox-center')
        infoboxCustomCell:wikitext(content)
        div:node(infoboxCustomCell)
    end

    self.content:node(div)
    return self
end

function Infobox:categories(...)
    local input = {...}
    for i = 1, #input do
        local category = input[i]
        if category ~= nil and category ~= '' then
            self.root:wikitext('[[Category:' .. category .. ']]')
        end
    end
    return self
end

function Infobox:bottom(wikitext)
    self.bottomContent = wikitext
    return self
end

--- Returns completed infobox
function Infobox:build()
    self.root:node(self.content)

    if self.bottomContent ~= nil then
        self.root:node(self.bottomContent)
    end

    self.root:node(self.adbox)
    return self.root
end

return Infobox
