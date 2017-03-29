require! {
    \../alt
    \./libs/mainAction : {Actions, create-main-actions}
    \promise
}


rand-float-from-sth = (s) ->
    md5s = md5 s
    return parseInt(md5s, 16) / Math.pow(16, md5s.length)

def-vals =
    userCount: 0
    hasUpdate: false

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
            # dirty here FIXME
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
                    if i.color == undefined
                        c = new paper.Color \red
                        c.hue = 255 * rand-float-from-sth i.title
                        typeMap[i.title].color = c.toCSS!
            return {typeMap}

        @gen-dep [\currentItem], (data) ->
            {currentItem} = data
            if currentItem and currentItem.type == \item
                actions.prefetchImage currentItem

    connect-socket: ->
        if not window.socket then
            window.socket = io!
            socket.on \user-count, ~> @set-store userCount:it

    checkUpdate: ->
        if not inElectron then return
        fs = localRequire \fs
        os = localRequire \os
        binname = "anno_worker.exe"
        binpath = "ANNOTATE-win32-x64"
        if os.platform! == \linux
            binname = "anno_worker"
            binpath = "ANNOTATE-linux-x64"

        p1 = new promise (resolve, reject) ->
            fs.readFile "./resources/app/libs/md5.txt", (err, data) ->
                if err then reject err
                resolve data.to-string!.split(' ')[0]
        p2 = new promise (resolve, reject) ->
            $.ajax do
                method: \GET
                url: "/release/#{binpath}/resources/app/libs/md5.txt"
                error: -> reject it
                success: -> resolve it
        promise.all [p1, p2] .done (md5s) ~>
            if md5s[0] != md5s[1]
                @set-store hasUpdate: true

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

    prefetchImage: (currentItem) ->
        $ .ajax do
            method: \GET
            url: \/api/prefetch-objects
            data: currentItem{parent,_id}
            error: ->
                #toastr.error it.response-text
                console.error it.response-text
            success: ~>
                #items = {[i._id, i] for i in it}
                for i in it
                    if i.url
                        img = new Image
                        img.src = i.url
                #@set-store {items}


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
