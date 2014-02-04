{info, warn, error, debug} = (require 'console-logger').ns 'libprotocol'

# TODO storage service
# eg, put to local storage, update conditionally etc
PROTO =
    Implementations: {}
    Protocols: {}

THIS = 'this'
CONS = '*cons*'

PROTOCOL_CACHE = window._libprotocol_cache

{partial, is_array} = require 'libprotein'


get_protocol = (p) ->
    uncache_protocol p

    if PROTO.Protocols.hasOwnProperty p
        PROTO.Protocols[p]
    else
        throw "No such registered protocol: '#{p}'"

register_protocol = (name, p) ->
    unless PROTO.Protocols.hasOwnProperty p
        # debug "Registering new protocol '#{name}'"
        PROTO.Protocols[name] = p
    else
        throw "Protocol already registered: '#{name}'"

get_method = (ns, method_name) ->
    m = PROTO.Protocols[ns]?.filter ([mn]) -> mn is method_name
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
#    unless PROTO.Implementations.hasOwnProperty protocol
#        # debug "Registering an implementation for the protocol '#{protocol}'"
#    else
#        # FIXME
#        # debug "Redefining existing implementation of protocol '#{protocol}'"

    PROTO.Implementations[protocol] = impl

register_exports = (exports) ->
    if exports.protocols?.definitions
        for protocol, definition of exports.protocols.definitions
            register_protocol protocol, definition

    if exports.protocols?.implementations
        for protocol, impl of exports.protocols.implementations
            register_protocol_impl protocol, impl

discover_protocols = ->
    #debug "Starting PROTO.Protocols discovery"
    if PROTOCOL_CACHE
        info "Protocol cache available, skipping discovery"
    else
        modules = try
            require.modules()
        catch e
            # for backwards compatibility, remove this after 30/07/2013
            window.bootstrapper.modules

        for modname of modules
            register_exports (require modname)

unique = (arr) ->
    a = {}
    for i in arr
        a[i] = true

    (k for own k of a)

uncache_protocol = (protocol) ->
    if PROTOCOL_CACHE 
        unless PROTO.Protocols[protocol] and PROTO.Implementations[protocol]
            # sorry for mutability
            mods = []
            for cache in PROTOCOL_CACHE
                if cache[protocol] isnt undefined
                    mods = mods.concat cache[protocol]
    
            mods = unique mods
    
            mods.map (modname) ->
                register_exports (require modname)

dispatch_impl = (protocol, opts=undefined) ->
    unless PROTO.Protocols[protocol] and PROTO.Implementations[protocol]
        uncache_protocol protocol
        discover_protocols() # this is required for recursive protocol discovery

    if PROTO.Protocols[protocol] and PROTO.Implementations[protocol]
        [cons] = PROTO.Protocols[protocol].filter (m) -> m[0] is CONS
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

        q = PROTO.Implementations[protocol] (if is_array opts then opts else [opts])...

        for own name, fun of q
            fun.meta or= {}
            fun.meta.name = name
            fun.meta.protocol = protocol
            fun.meta.arity = get_arity protocol, name

            for k, v of (get_meta protocol, name)
                fun.meta[k] = v


        q
    else
        debug "Cant find implementations for protocol #{protocol}"
        null


dump_impls = ->
    debug "Currently registered PROTO.Implementations:", PROTO.Implementations


module.exports = {
    register_protocol_impl
    register_protocol
    get_protocol
    dispatch_impl
    dump_impls
    is_async
    is_vararg
    get_arity
    discover_protocols
}
