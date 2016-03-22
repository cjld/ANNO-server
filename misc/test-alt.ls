require! {
    \alt
}

alt = new alt

class Actions
    ->
        @generate-actions [
            \doSetStore
        ]
        @dep-map = {}
        @dep-funcs = []
        @gen-dep [\a,\b], (data) ->
            if data.a? and data.b?
                return c:data.a+data.b

        @gen-dep [\c], (data) ->
            if data.c?
                return d:data.c+1

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
        data = store.get-state!
        merge-data = {}
        for i of call-ids
            newdata = @dep-funcs[i] data
            merge-data <<< newdata
        if merge-data !== {}
            @set-store merge-data
        return it



actions = alt.create-actions Actions

import-exist = (a, b) ->
    updated = false
    for k,v of b
        if a[k]?
            a[k] = v
            updated = true
    return updated

class BasicStore
    ->
        @bind-actions actions

    import-initial: (main-store, keys) !->
        data = main-store.get-state!
        for i in keys
            if data[i]?
                this[i] = data[i]
            else
                throw "No such key: #{i}"


    on-do-set-store: ->
        return import-exist this, it

class Store extends BasicStore
    ->
        super ...
        @a = 1
        @b = 2
        @c = 0
        @d = 322

store = alt.create-store Store

# SubStore
class SubStore extends BasicStore
    ->
        super ...
        @import-initial store, [\a,\b]

sub-store = alt.create-store SubStore

store.listen ->
    console.log "store:", it
sub-store.listen ->
    console.log "sub-store:", it

actions.set-store a:1
actions.set-store a:2
actions.set-store b:3
