require! {
    \../alt
    \./libs/mainAction : {Actions, create-main-actions}
}

def-vals =
    loadingCounter: true
    counter: {}

    loadingItems: true
    items: {}

    selects: {}
    showedItems: []

    tabType: \total

    page: 1
    fatherId: undefined
    currentItem: undefined
    ancestors: []

    config: {}
    typeMap: {}

class MainActions extends Actions
    ->
        super ...

        # update showed-items
        @gen-dep [\items], (data) ->
            {items} = data
            tabType = store.get-state!.tabType
            showed-items = [v for k,v of items].filter ~>
                if tabType == \total
                    return 1
                state = it.state
                state ?= "un-annotated"
                return state == tabType
            return {showed-items}

        # update items
        @gen-dep [\fatherId, \page, \tabType], ~>
            # dirty here
            actions.fetchContent!
            actions.findAncestor!
            return {}

        @gen-dep [\tabType], ~>
            actions.fetchItems!
            return {}

        @gen-dep [\config], ~>
            typeMap = {}
            for k,v of it.config.types
                for i in v.types
                    typeMap[i.title] = i.{src, color}
            return {typeMap}

    connect-socket: ->
        if not window.socket then
            window.socket = io!

    fetchContent: ->
        @resetSelects!
        @fetchCounter!
        @fetchItems!

    fetchCounter: ->
        @set-store loadingCounter:true
        $ .ajax do
            method: \POST
            url: \/api/counter
            data: {parent:store.get-state!.fatherId}
            error: ->
                toastr.error it.response-text
            success: ~>
                @set-store counter:it
            complete: ~>
                @set-store loadingCounter:false

    find-objects: (cond, cb) ->
        $ .ajax do
            method: \POST
            url: \/api/find-objects
            data: cond
            error: ->
                toastr.error it.response-text
            success: cb

    findAncestor: ->
        ancestors = []
        @config = undefined
        my-func = ~>
            i = it[0]
            if i
                if i.config and not @config
                    try
                        @config = JSON.parse i.config
                        if store.get-state!.config !== @config
                            @set-store {config: @config}
                    catch error
                ancestors.push(i)
                if ancestors.length == 1
                    @set-store currentItem:i
            if i and i.parent
                @find-objects {_id:i.parent}, my-func
            else
                @set-store {ancestors}
        if store.get-state!.fatherId?
            @find-objects {_id:store.get-state!.fatherId}, my-func
        else
            @set-store {ancestors, currentItem:undefined}

    fetchItems: ->
        @set-store loadingItems:true
        state = store.get-state!
        $ .ajax do
            method: \POST
            url: \/api/list-objects
            data: {parent:state.fatherId, page:state.page, state:state.tabType}
            error: ->
                toastr.error it.response-text
            success: ~>
                items = {[i._id, i] for i in it}
                @set-store {items}
            complete: ~>
                @set-store loadingItems:false

    deleteItems: (items) ->
        if not Array.isArray items
            items = [ k for k,v of items when v ]
        $ .ajax do
            method: \POST
            url: \/api/delete-items
            data: {items}
            error: ->
                toastr.error it.response-text
            success: ~>
                toastr.info it
                @fetchContent!
                @set-store selects:{}
            complete: ~>

    resetSelects: ->
        @set-store selects:{}

    selectToggle: ->
        {selects} = @store.get-state!
        if not Array.isArray it
            then it = [it]
        for i in it
            if selects[i]?
                delete selects[i]
            else
                selects[i] = true
        @set-store {selects}

    selectShowed: ->
        {showed-items} = @store.get-state!
        selects = { [i._id, true] for i in showed-items }
        @set-store {selects}

{actions, store, BasicStore} = create-main-actions alt, MainActions, def-vals

module.exports = {actions, store}
