local Dropdown = {}

function Dropdown.render()
    return mw.html.create('select')
             :attr('id', 'weekSelector')
             :node(mw.html.create('option'):attr('value', 'week1'):wikitext('Week 1'))
             :node(mw.html.create('option'):attr('value', 'week2'):wikitext('Week 2'))
end

return Dropdown