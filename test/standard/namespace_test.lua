local Namespace = require('namespace')

local _Title = {}
function _Title.getCurrentTitle()
    local simpleClass = {}
    function simpleClass.inNamespace(id)
        return 'test'
    end

    return simpleClass
end

mw = {
    title = _Title,
    site = {
        namespaces = {
            {
                name = 'Talk',
                id = '1'
            },
            {
                name = 'User',
                id = '2'
            },
            {
                name = 'User Talk',
                id = '3'
            },
            {
                name = 'Liquipedia',
                id = '4'
            },
            {
                name = 'Data',
                id = '136'
            },
            {
                name = 'Module talk',
                id = '829'
            }
        }
    }
}

assert(Namespace.isMain())
assert(Namespace.idFromName('bs') == nil)
assert(Namespace.idFromName() == nil)
assert(0, Namespace.idFromName(''))
assert(2, Namespace.idFromName('User'))
assert(4, Namespace.idFromName('Liquipedia'))
assert(136, Namespace.idFromName('Data'))
assert(829, Namespace.idFromName('Module talk'))
