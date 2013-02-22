{info, warn, error, debug} = require 'console-logger'

Implementations = {}
Protocols = {}
THIS = 'this'
CONS = '*cons*'

DEFAULT_PROTOCOLS = ['IDom', 'INucleus']

{partial, is_array} = require 'libprotein'


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
    [_, _, meta] = get_method ns, method_name
    meta or {}

get_meta_key = (prop, ns, method_name) -> (get_meta ns, method_name)[prop]

is_async = partial get_meta_key, 'async'

is_vararg = partial get_meta_key, 'vararg'

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

    if Protocols[protocol] and Implementations[protocol]
        [cons] = Protocols[protocol].filter (m) -> m[0] is CONS
        if cons
            meta = get_meta protocol, CONS
            if meta.concerns?.before
                concerns = if is_array meta.concerns.before
                    meta.concerns.before
                else
                    [meta.concerns.before]

                # sorry for mutability FIXME later
                xopts = [opts]
                for f in concerns
                    xopts.push (f xopts...)

                opts = xopts

        q = Implementations[protocol] (if is_array opts then opts else [opts])...

        for own name, fun of q
            fun.meta or= {}
            fun.meta.name = name
            fun.meta.protocol = protocol
            fun.meta.arity = get_arity protocol, name

            for k, v of (get_meta protocol, name)
                fun.meta[k] = v


        q
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
