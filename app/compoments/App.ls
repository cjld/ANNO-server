require! {
    \react : React
    \react-router : {Link}
    \react-dom : ReactDOM
    \./../models/Object : my-object
    \../alt
    \../actions/mainAction : {Actions, create-main-actions}
}

def-vals =
    loadingCounter: true
    counter: {}

    loadingItems: true
    items: {}

    selects: {}
    showedItems: []

    tabType: \total

    fatherId: undefined

class MainActions extends Actions
    ->
        super ...

        # update showed-items
        @gen-dep [\tabType, \items], (data) ->
            {tabType, items} = data
            showed-items = [v for k,v of items].filter ~>
                if tabType == \total
                    return 1
                return it.state == tabType
            return {showed-items}

        # update items
        @gen-dep [\fatherId], ~>
            # dirty here
            console.log \father-id, store.get-state!.father-id
            actions.fetchContent!
            return {}

    fetchContent: ->
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

    fetchItems: ->
        @set-store loadingItems:true
        $ .ajax do
            method: \POST
            url: \/api/list-objects
            data: {parent:store.get-state!.fatherId}
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

class Navbar extends React.Component
    render: ->
        onlineUserCount = 108
        navList = [ \Explore \Datasets \Stats \Category \Whatever ]
        navs = navList.map (it) ->
            ``<a href={it.toLowerCase()} className="item" key={it}>
                {it}
            </a>
            ``
        ``<div className="ui menu">
                    <a className="header item" href="/">ANNOTATE
                        <div className="floating ui red circular mini label" style={{top:'20%'}}>
                            {onlineUserCount}
                        </div>
                    </a>
                    <div className="item">
                        <div className="ui small left labeled right icon input">
                            <div className="ui label">Whole datasets</div>
                            <input type="text" placeholder="Search"/>
                            <i className="search icon"></i>
                        </div>
                    </div>
                    {navs}
                    <div className="ui right floated text menu">
                        <div className="item">
                            <div className="ui buttons">
                                <div className="ui green button">
                                    Sign up
                                </div>
                                <div className="or"></div>
                                <div className="ui button">
                                    Sign in
                                </div>

                            </div>
                        </div>
                    </div>
                </div>
        ``

class Footer extends React.Component
    render: ->
        ``<div className="footer">
            <div className="ui divider">
            </div>
            <div className="ui disabled basic inverted center aligned segment">
                <b>Annotate</b>, © 2016 Dun Liang.
            </div>
        </div>
        ``

class Guider extends React.Component
    ->
        super ...
        @state =
            *   displayType: \grid # grid list block
                ajaxing: false
                select-all-state: false
                # modal type, edit or add
                modalType: \add

    componentDidMount: ->
        self = this
        #dialog = $ \#addModal .dialog do
        #    auto-open: false
        #    modal: true
        dialog = $ \#addModal
        dialog.modal detachable:false

        del-dialog = $ \#delModal
        del-dialog.modal do
            detachable:false
            on-approve: ~>
                {selects} = store.get-state!
                actions.deleteItems selects


        $ \#addItemBtn .click ~>
            @set-state modalType:\add
            dialog.modal \show

        $ \#editItemBtn .click ~>
            {selects} = store.get-state!
            ids = Object.keys(selects)
            if ids.length != 1
                toastr.error "Please select only one item."
                return
            item = store.get-state!.items[ids[0]]
            for k,v of item
                # attribute selector
                dom = addItemForm.find "input[name='#{k}']"
                dom.val(v)

            @set-state modalType:\edit
            dialog.modal \show

        $ \#delItemBtn .click ->
            del-dialog.modal \show

        $ \#selectAllBtn .click ->
            self.set-state select-all-state: !self.state.select-all-state
            if self.state.select-all-state
                actions.selectShowed!
            else
                actions.resetSelects!

        addItemForm = $ \#addItemForm
        addItemForm.submit (e) ->
            e.prevent-default!
            inputs = addItemForm.find \input
            values = {}
            for input in inputs
                values[input.name] = $(input).val!

            if self.state.modalType == \edit
                id = Object.keys(store.get-state!.selects)[0]
                unless id? then return
                values._id = id
            self.set-state ajaxing: true
            $.ajax do
                method: \POST
                url: \/api/new-object
                data: values
                error: ->
                    toastr.error it.response-text
                success: ->
                    toastr.success it
                    dialog.modal \hide
                    addItemForm[0].reset!
                    actions.fetchContent!
                complete: ->
                    self.set-state ajaxing: false

    render: ->
        self = this
        displayBar = [ \grid \list \block ].map (it) ->
            ``<a
            className={"ui "+ (it==self.state.displayType?"active":"") +" item"}
            onClick={function(){self.setState({displayType:it})}}
            key={it}
            ><i className={it+" layout icon"}></i></a>
            ``
        availItems = []
        for key of my-object.tree
            if my-object.tree[key] == String
                availItems.push ``<div className="field" key={key}>
                  <label>{key}</label>
                  <input type="text" name={key} placeholder={key}/>
                </div>
                ``

        delModal = ``<div className="ui modal" id="delModal">
            <i className="close icon"></i>
            <div className="header">
                Delete Item
            </div>
            <div className="content">
                Are you sure you delete those items?
            </div>
            <div className="actions">
                <div className="ui approve button">OK</div>
                <div className="ui cancel button">Cancel</div>
            </div>
        </div>
        ``

        ``<div>
        {delModal}
        <div className="ui modal" id="addModal">
            <i className="close icon"></i>
            <div className="header">
                New Item
            </div>
            <div className="content">
                <form className={self.state.ajaxing?"ui loading form":"ui form"} id="addItemForm">

                    {availItems}

                    <button className="ui button" type="submit">Submit</button>
                </form>
            </div>
        </div>

            <div className="ui container">

                <div className="ui right floated small menu">
                    {displayBar}
                </div>

                <div className="ui right floated small menu">
                    <a className="ui item" id="selectAllBtn"><i className=
                    {self.state.selectAllState?"check circle icon":"check circle outline icon"}></i></a>
                    <a className="ui item" id="addItemBtn"><i className="green add circle icon"></i></a>
                    <a className="ui item" id="delItemBtn"><i className="red minus circle icon"></i></a>
                    <a className="ui item" id="editItemBtn"><i className="edit icon"></i></a>
                </div>

                <i className="big database icon"></i>

                <div className="ui huge breadcrumb">
                    <div className="divider">/</div>
                    <a href="#">Traffic-sign</a>
                    <div className="divider">/</div>
                    <a href="#">Prohibit</a>
                </div>

            </div>
            <div className="ui vertical segment">
                <big>simple description, all prohibit traffic sign in China.</big>
            </div>
        </div>
        ``

class Displayer extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \tabType
            \selects
            \showedItems
            \loadingItems
            \counter
        ]

    componentDidUpdate: ->
        node = $ ReactDOM.findDOMNode this
        node.find \.imgGalleryBoxOuter .popup inline:true

    render: ->
        self = this
        tabs =
            *   type: \total, iconstr:  "file archive outline icon"
            *   type: \annotated, iconstr:  "file icon"
            *   type: \un-annotated, iconstr:  "file outline icon"
            *   type: \issued, iconstr:  "warning sign icon"

        for i in tabs
            i.number = self.state.counter[i.type]

        tabsUI = tabs.map (it) ->
            ``<a href="#"
                className={(self.state.tabType==it.type?"active":"")+" item"}
                onClick={function(){actions.setStore({tabType:it.type})}}
                key={it.type}>
                <i className={it.iconstr}></i>
                <b>{it.number}</b>&nbsp;
                {it.type}
            </a>
            ``
        tabsUI = ``<div className="ui four item top attached tabular menu">
            {tabsUI}
        </div>
        ``
        infos = [ \category \description ]

        imgsUI = @state.showedItems.map (it, index) ->
            listUI = infos.map (info) ->
                ``<div className="item" key={info}>
                    <div className="header">
                        {info}
                    </div>
                    <div className="description">
                        {it[info]}
                    </div>
                </div>
                ``

            iconname = if self.state.selects[it._id]
                then "checkmark box icon"
                else "square outline icon"
            obj = it
            onClick = ->
                actions.selectToggle obj._id

            colorMap = {
                '' : ''
                \annotated : \green
                \un-annotated : \red
                \issued : \yellow
            }

            ``<div className="column" key={index}>
                <div className={"ui "+colorMap[it.state]+" segment imgGalleryBoxOuter"} style={{overflow:'hidden'}}>
                    <a className="ui left corner label" onClick={onClick}>
                        <i className={iconname}></i>
                    </a>
                    <Link className="imgGalleryBox" to={"/i/"+obj._id}>
                        <img className="ui bordered image" src={it.url} alt="" />
                    </Link>
                </div>
                <div className="ui special popup">
                    <div className="ui bulleted list">
                        {listUI}
                    </div>
                </div>
            </div>
            ``

        return ``<div>
        {tabsUI}
        <div className={"ui bottom attached "+(self.state.ajaxing?"loading":"")+" segment"}>
            <div className="ui three column grid">
                {imgsUI}
            </div>
            <div className="ui pagination secondary pointing menu">
              <a className="active item">
                1
              </a>
              <div className="disabled item">
                ...
              </div>
              <a className="item">
                10
              </a>
              <a className="item">
                11
              </a>
              <a className="item">
                12
              </a>
            </div>
        </div></div>
        ``

class MainPage extends React.Component
    render: ->
        ``<div className="ui container">
            <Guider />
            <Displayer />
        </div>
        ``

class App extends React.Component

    componentDidMount: ->
        actions.set-store fatherId:@props.params.itemId
        console.log \app-did-mount, @props.params.itemId

    componentWillUpdate: ->
        actions.set-store fatherId:it.params.itemId
        console.log \app-will-update, it.params.itemId

    render: ->
        ``<div>
            <Navbar />
            <MainPage />
            <Footer />
        </div>
        ``

module.exports = App
