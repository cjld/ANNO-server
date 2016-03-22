require! {
    \react : React
    \react-router : {Link}
    \react-dom : ReactDOM
    \./../models/Object : my-object
    \../alt
}

class MainActions
    -> @generate-actions do
        \fetchCounterSuccess
        \fetchCounterComplete
        \fetchItemsSuccess
        \fetchItemsComplete
        \selectToggle
        \resetSelects
        \selectShowed
        \tabChange

    fetchCounter: ->
        $ .ajax do
            method: \POST
            url: \/api/counter
            error: ->
                toastr.error it.response-text
            success: ~>
                @fetchCounterSuccess it
            complete: ~>
                @fetchCounterComplete it

    fetchItems: ->
        $ .ajax do
            method: \POST
            url: \/api/list-objects
            error: ->
                toastr.error it.response-text
            success: ~>
                @fetchItemsSuccess it
            complete: ~>
                @fetchItemsComplete!

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
                @fetchItems!
                @fetchCounter!
                @resetSelects {}
            complete: ~>

actions = alt.create-actions MainActions

class MainStore
    ->
        @bind-actions actions
        @loadingCounter = true
        @counter = {}

        @loadingItems = true
        @items = []

        @selects = {}
        @showed-items = []

        @tabType = \total

    update-showed-items: ->
        @showed-items = @items.filter ~>
            if @tabType == \total
                return 1
            return it.state == @tabType

    on-tabChange: ->
        @tabType = it
        @update-showed-items!

    on-selectShowed: ->
        @selects = { [i._id, true] for i in @showed-items }

    on-fetchCounter: -> @loadingCounter = true
    on-fetchCounterSuccess: -> @counter = it
    on-fetchCounterComplete: -> @loadingCounter = false

    on-fetchItems: -> @loadingItems = true
    on-fetchItemsSuccess: ->
        @items = it
        @update-showed-items!

    on-fetchItemsComplete: !-> @loadingItems = false

    on-resetSelects: -> @selects = it

    on-selectToggle: ->
        if not Array.isArray it
            then it = [it]
        for i in it
            ! = @selects[i]


store = alt.create-store MainStore


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
                selects: store.get-state!.selects
                select-all-state: true
        store.listen @on-change

    on-change: ~>
        @set-state selects: it.selects

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
                console.log "delete items: ", @state.selects
                actions.deleteItems @state.selects


        $ \#addItemBtn .click ->
            dialog.modal \show

        $ \#delItemBtn .click ->
            del-dialog.modal \show

        $ \#selectAllBtn .click ->
            self.set-state select-all-state: !self.state.select-all-state
            if self.state.select-all-state
                actions.selectShowed 0
            else
                actions.resetSelects {}

        addItemForm = $ \#addItemForm
        addItemForm.submit (e) ->
            e.prevent-default!
            inputs = addItemForm.find \input
            values = {}
            for input in inputs
                values[input.name] = $(input).val!
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
                    actions.fetchItems!
                    actions.fetchCounter!
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
        data = store.get-state!
        @state =
            *   tabType: data.tabType # total annotated un-annotated issued
                selects: data.selects
                items: []
                ajaxing: true
                counter:
                    \total : 0
                    \annotated : 0
                    \un-annotated : 0
                    \issued : 0

    on-change: ~>
        @set-state do
            tabType: it.tabType
            ajaxing: it.loadingItems
            items: it.showed-items
            counter: it.counter
            selects: it.selects

    componentWillUnmount: ->
        store.unlisten @on-change

    componentDidMount: ->
        store.listen @on-change
        actions.fetchCounter!
        actions.fetchItems!

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
                onClick={function(){actions.tabChange(it.type)}}
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

        imgsUI = @state.items.map (it, index) ->
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
                    <div className="imgGalleryBox">
                        <img className="ui bordered image" src={it.url} alt="" />
                    </div>
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
    render: ->
        ``<div>
            <Navbar />
            <MainPage />
            <Footer />
        </div>
        ``

module.exports = App
