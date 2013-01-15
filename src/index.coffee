say = (a...) -> console.log.apply console, a

Implementations = {}
Protocols = {}
THIS = 'this'

DEFAULT_PROTOCOLS = ['IDom', 'IMath']


get_protocol = (p) ->
    if Protocols.hasOwnProperty p
        Protocols[p]
    else
        throw "No such registered protocol: '#{p}'"


get_default_protocols = ->
    DEFAULT_PROTOCOLS


register_protocol = (name, p) ->
    unless Protocols.hasOwnProperty p
        say "Registering new protocol '#{name}'"
        Protocols[name] = p
    else
        throw "Such protocol is already registered: '#{name}'"


is_async = (ns, method_name) ->
    m = Protocols[ns]?.filter ([mn]) -> mn is method_name
    if m
        [name, args, async] = m[0]
        async is 'async'
    else
        null

get_arity = (ns, method_name) ->
    m = Protocols[ns]?.filter ([mn]) -> mn is method_name
    if m
        [name, argums, async] = m[0]
        argums.length
    else
        throw "Arity requested for unknown method #{ns}/#{method_name}"

register_protocol_impl = (protocol, impl) ->
    unless get_protocol protocol
        throw "Can't register implementation for an unknown protocol: '#{protocol}'"

    unless Implementations.hasOwnProperty protocol
        say "Registering an implementation for the protocol '#{protocol}'"
    else
        say "Redefining existing implementation of protocol '#{protocol}'"

    Implementations[protocol] = impl


discover_impls = ->
    bootstrapper = require 'bootstrapper'

    for modname of bootstrapper.modules
        exports = require modname

        if exports.protocols and exports.protocols.definitions
            for protocol, definition of exports.protocols.definitions
                register_protocol protocol, definition

        if exports.protocols and exports.protocols.implementations
            for protocol, impl of exports.protocols.implementations
                register_protocol_impl protocol, impl

dispatch_impl = (protocol, node, rest...) ->
    unless Protocols[protocol] and Implementations[protocol]
        discover_impls()

    if Implementations[protocol]
        Implementations[protocol](node)
    else
        null


dump_impls = ->
    say "Currently registered implementations:", Implementations


module.exports = {
    register_protocol_impl
    register_protocol
    get_default_protocols
    get_protocol
    dispatch_impl
    dump_impls
    is_async
    get_arity
    discover_impls
}
