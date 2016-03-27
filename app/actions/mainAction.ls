
class Actions
    ->
        @generate-actions [
            \doSetStore
        ]
        @dep-map = {}
        @dep-funcs = []

    set-main-store: (main-store) ->
        @store = main-store
        return 0

    gen-dep: (dep-vals, func) ->
        @dep-funcs.push func
        func-id = @dep-funcs.length - 1
        for i in dep-vals
            if not @dep-map[i]
                @dep-map[i] = [func-id]
            else
                @dep-map[i].push func-id
        return 0

    set-store: ->
        @do-set-store it
        call-ids = {}
        for k of it
            unless @dep-map[k]
                continue
            for i in @dep-map[k]
                call-ids[i] = true
        unless @store?
            throw "please set-main-store first."
        data = @store.get-state!
        merge-data = {}
        for i of call-ids
            newdata = @dep-funcs[i] data
            merge-data <<< newdata
        if merge-data !== {}
            @set-store merge-data
        return it

import-exist = (a, b) ->
    updated = false
    for k,v of b
        if a.has-own-property k
            a[k] = v
            updated = true
    return updated

inject-func = (obj, key, func) ->
    pre-func = obj[key]
    if pre-func
        obj[key] = ->
            func ...
            pre-func ...
    else
        # console.log "inject failed.", &
        obj[key] = func

# return {actions, store, BasicStore, Store}
create-main-actions = (alt, actions-class, default-values) ->
    actions = alt.create-actions actions-class

    class BasicStore
        (keys) ->
            @bind-actions actions
            if keys?
                @import-initial store, keys

        import-initial: (main-store, keys) !->
            data = main-store.get-state!
            for i in keys
                if data.has-own-property i
                    this[i] = data[i]
                else
                    throw "No such key: #{i}"

        on-do-set-store: ->
            return import-exist this, it

    class Store extends BasicStore
        ->
            super ...
            this <<< default-values

    store = alt.create-store Store
    actions.store = store
    # fix set store not found in alt.create-store
    actions.set-store = Actions.prototype.set-store

    store.connect-to-component = (comp, keys) ->
        name = comp.constructor.name
        class SpecialStore extends BasicStore
            ->
                super ...
                @import-initial store, keys
        console.log "create store #{name}"
        sp-store = alt.get-store name
        unless sp-store
            sp-store = alt.create-store SpecialStore, name
        unless comp.state?
            comp.state = {}
        comp.state <<< sp-store.get-state!
        listen-func = ->
            # console.log name, it
            comp.set-state it

        inject-func comp, \componentDidMount, ->
            sp-store.listen listen-func
        inject-func comp, \componentWillUnmount, ->
            sp-store.unlisten listen-func

        return sp-store

    return {actions, store, BasicStore, Store}

export Actions
export create-main-actions
