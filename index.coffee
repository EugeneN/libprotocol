{info, warn, error, debug} = require 'console-logger'

Implementations = {}
Protocols = {}
THIS = 'this'

DEFAULT_PROTOCOLS = ['IDom', 'INucleus']

{partial} = require 'libprotein'


get_protocol = (p) ->
    if Protocols.hasOwnProperty p
        Protocols[p]
    else
        throw "No such registered protocol: '#{p}'"

get_default_protocols = -> DEFAULT_PROTOCOLS

register_protocol = (name, p) ->
    unless Protocols.hasOwnProperty p
        info "Registering new protocol '#{name}'"
        Protocols[name] = p
    else
        throw "Such protocol is already registered: '#{name}'"

get_method = (ns, method_name) ->
    m = Protocols[ns]?.filter ([mn]) -> mn is method_name
    if m.length is 1
        m[0]
    else
        error "No such method:", ns, method_name
        throw "No such method"

get_meta = (ns, method_name) ->
    [_, _, meta...] = get_method ns, method_name
    meta

is_any = (prop, ns, method_name) -> prop in (get_meta ns, method_name)

is_async = partial is_any, 'async'

is_vararg = partial is_any, 'vararg'

get_arity = (ns, method_name) ->
    [_, argums, _...] = get_method ns, method_name
    argums.length

register_protocol_impl = (protocol, impl) ->
    unless get_protocol protocol
        throw "Can't register implementation for an unknown protocol: '#{protocol}'"

    unless Implementations.hasOwnProperty protocol
        info "Registering an implementation for the protocol '#{protocol}'"
    else
        info "Redefining existing implementation of protocol '#{protocol}'"

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

dispatch_impl = (protocol, opts=undefined) ->
    unless Protocols[protocol] and Implementations[protocol]
        discover_impls()

    if Implementations[protocol]
        Implementations[protocol] opts
    else
        null


dump_impls = ->
    info "Currently registered implementations:", Implementations


module.exports = {
    register_protocol_impl
    register_protocol
    get_default_protocols
    get_protocol
    dispatch_impl
    dump_impls
    is_async
    is_vararg
    get_arity
    discover_impls
}
