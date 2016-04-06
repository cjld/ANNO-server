require! {
    \react : React
    \react-router : {Link}
    \react-dom : ReactDOM
    \./../models/Object : my-object
    \../alt
    \../actions/mainAction : {Actions, create-main-actions}
    \../models/types
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
    currentItem: undefined
    ancestors: []

    editMode: ""

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
            actions.fetchContent!
            actions.findAncestor!
            return {}

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
        my-func = ~>
            i = it[0]
            if i
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

class Breadcrumb extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \ancestors
        ]

    render: ->
        lists = []
        p = [] <<< @state.ancestors
        for a in p.reverse!
            lists.push ``<div key={a._id} className="divider">/</div>``
            lists.push ``<Link key={a._id+"-link"} to={"/i/"+a._id}>{a.name}</Link>``

        ``<div>
            <Link to="/i/"><i className="big database icon" /></Link>
            <div className="ui huge breadcrumb">
                {lists}
            </div>
        </div>``

class Guider extends React.Component
    ->
        super ...
        @state =
            *   displayType: \grid # grid list block
                ajaxing: false
                select-all-state: false
                # modal type, edit or add
                modalType: \add

        store.connect-to-component this, [
            \currentItem
        ]

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
            else
                fid = store.get-state!.fatherId
                if fid then values.parent = fid
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
        mainDescription = @state.currentItem?.description
        unless mainDescription? then mainDescription=\Home
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

                <Breadcrumb/>

            </div>
            <div className="ui fitted hidden clearing divider"></div>
            <div className="ui vertical segment">
                <big>{mainDescription}</big>
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
        infos = [ \category \description \name ]

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

class Editor extends React.Component
    ->
        store.connect-to-component this, [\currentItem]
        @state.marks = [
            *   type: \cow, state:\set-mark, spots:[{x:100,y:200}, {x:0,y:0}], segments: {active:{}, data:[]}
            *   type: \dog, state:\set-mark2, spots:[{x:200,y:200}], segments: {active:{}, data:[]}
        ]
        @state.cMark = \0
        @state.smooth = false
        @state.showMark = false
        @state.editMode = "spotting"

    create-typeimage-symbol: ->
        @typeimages = {}
        for k,v of types.url-map
            raster = new paper.Raster v
            @typeimages[k] = new paper.Symbol raster
            raster.remove!
        #@test-symbol @typeimages[k]

    create-cross-symbol: ->
        w = 7
        line = new paper.Path [
            new paper.Point -w,0
            new paper.Point w,0
        ]
        line2 = new paper.Path [
            new paper.Point 0,-w
            new paper.Point 0,w
        ]
        linegroup = new paper.Group [line,line2]
        linegroup.strokeColor = \yellow
        linegroup.strokeWidth = 3
        @cross-symbol = new paper.Symbol linegroup
        linegroup.remove!
        #@test-symbol @cross-symbol

    test-symbol: (symbol) ->
        for i til 100
            instance = symbol.place!
            instance.position = paper.Point.random!.multiply paper.view.size
            instance.rotate Math.random! * 360
            instance.scale 0.25 + Math.random! * 1.75

    rebuild: ->
        if @rebuild-group
            @rebuild-group.remove!
        @rebuild-group = new paper.Group
        @rebuild-group.apply-matrix = false
        @rebuild-group.translate @background.bounds.point
        wfactor = 1 / @layer.scaling.x
        paper.project.current-style =
            fillColor : \red
            strokeColor : \black
            strokeWidth : wfactor
        segm-op = if @state.editMode==\pan then 0.5 else 1
        spot-op = if @state.editMode==\pan then 0.8 else 1
        # draw segments
        @segments-group = new paper.Group
        @rebuild-group.addChild @segments-group
        for i,mark of @state.marks
            for j,segment of mark.segments.data
                path = new paper.Path
                path.opacity = segm-op * if i==@state.cMark then 1 else 0.5
                @segments-group.addChild path
                path.mydata = {i,j}
                if i==@state.cMark and
                   j==mark.segments.active.j
                    path.selected = true
                path.closed = true
                for k,p of segment
                    pt = new paper.Point p
                    path.add pt
                if @state.smooth then path.smooth!

        # draw spots
        @spots-group = new paper.Group
        @rebuild-group.addChild @spots-group
        for i,mark of @state.marks
            type-symbol = undefined
            if @state.showMark and mark.type and @typeimages[mark.type]
                type-symbol = @typeimages[mark.type]
            for j,spot of mark.spots
                instance = @cross-symbol.place!
                instance.position = spot
                instance.scale wfactor
                instance.opacity = spot-op * if @state.cMark == i then 1 else 0.5
                @spots-group.addChild instance
                instance.mydata = {i,j}
                if type-symbol
                    instance = type-symbol.place!
                    instance.scale 0.3 * wfactor
                    instance.position = spot
                    @rebuild-group.addChild instance
        paper.view.draw!

    componentDidMount: ->

        imgUrl = @state.currentItem.url
        paper.setup 'canvas'
        @layer = paper.project.activeLayer
            ..apply-matrix = false
        raster = new paper.Raster imgUrl
        @background = raster
        raster.on-load = ~>
            console.log "The image has loaded."
            @background.position = paper.view.center
            @rebuild!

        @create-cross-symbol!
        @create-typeimage-symbol!
        #@rebuild!
        @spotting-tool = new paper.Tool

        @spotting-tool.on-mouse-down = (e) ~>
            hitOptions =
                stroke: true
                tolerance: 5
            tmatrix = @spots-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hit-result = @spots-group.hit-test point, hitOptions
            @drag-func = undefined
            if hit-result?item?mydata
                {i,j} = that
                if @state.cMark != i
                    @set-state cMark:i
                if e.modifiers.shift
                    @state.marks[i].spots.splice j,1
                    return @rebuild!
                @drag-func = (i,j,e) -->
                    @state.marks[i].spots[j] = e.point.transform tmatrix
                    @rebuild!
                @drag-func = @drag-func i,j
            else
                if @state.cMark and @state.marks[@state.cMark]
                    @state.marks[@state.cMark].spots.push point
                    @rebuild!

        @spotting-tool.on-mouse-up = (e) ~>
            @up-func? e
            #console.log \on-mouse-up, e
        @spotting-tool.on-mouse-drag = (e) ~>
            @drag-func? e

        @segment-tool = new paper.Tool

        @segment-tool.on-mouse-down = (e) ~>
            @drag-func = undefined
            c = @state.cMark
            if c then mark = @state.marks[c]
            unless mark then return
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hitOptions =
                stroke: true
                fill: true
                segments: true
                tolerance: 5
            hit-result = @segments-group.hit-test point, hitOptions
            console.log hit-result
            if e.modifiers.control
                data = mark.segments.data
                data.push [point]
                mark.segments.active = {i:c,j:(data.length-1).to-string!}
            else
                #if hit-result?item?mydata?i != @state.cMark
                #    @set-state cMark:i
                if hit-result?item?mydata
                    {i,j} = that
                    if i == @state.cMark
                        mark = @state.marks[i]
                        poly = mark.segments.data[j]
                        if hit-result.segment
                            k = hit-result.item.segments.index-of that
                            point = poly[k]
                        if hit-result.location
                            k = hit-result.location.index + 1
                        switch hit-result?type
                        case \fill
                            if e.modifiers.shift
                                mark.segments.data.splice j,1
                            else
                                @drag-func = (poly, e) ~~>
                                    movePolygon poly, e.delta.multiply tmatrix.scaling
                                    @rebuild!
                                @drag-func = @drag-func poly
                        case \segment
                            if e.modifiers.shift
                                poly.splice k, 1
                            else
                                @drag-func = (point, e) ~~>
                                    delta = e.delta.multiply tmatrix.scaling
                                    np = delta.add point
                                    point <<< np{x,y}
                                    @rebuild!
                                @drag-func = @drag-func point
                        case \stroke
                            if e.modifiers.shift
                                null
                            else
                                poly.splice k, 0, point{x,y}
                        mark.segments.active.j = j
                        @rebuild!
                        return

                j = mark.segments?active?j
                if j?
                    poly = mark.segments.data[j]
                    poly?.push point
            @rebuild!

        @segment-tool.on-mouse-up = (e) ~>
            @up-func? e

        @segment-tool.on-mouse-drag = (e) ~>
            @drag-func? e

        @pan-tool = new paper.Tool
        @pan-tool.on-mouse-drag = (e) ~>
            if e.modifiers.control
                @layer.scale(e.delta.y / 100.0 + 1, e.downPoint)
            else
                @layer.translate e.delta
            @rebuild!

        @empty-tool = new paper.Tool
        @empty-tool.activate!

    componentDidUpdate: ->
        if @state.editMode == \spotting
            @spotting-tool.activate!
        else if @state.editMode == \segment
            @segment-tool.activate!
        else if @state.editMode == \pan
            @pan-tool.activate!
        else
            @empty-tool.activate!
        @rebuild!

    addMark: ~>
        @state.marks.push type:"",state:"set-type",spots:[],segments:{active:{},data:[]}
        @forceUpdate!
    delMark: ~>
        @state.marks.splice @cMark, 1
        @forceUpdate!

    render: ->
        imgUrl = @state.currentItem?.url
        {marks,cMark} = @state
        marksUI = for i of marks
            switchCMark = ->
                @set-state cMark:it
            switchCMark .= bind @, i
            switchType = (i, data) ->
                @state.marks[i].type = data
                @forceUpdate!
            switchType .= bind @, i
            ``<tr key={i}>
                <td><a onClick={switchCMark}><div className={i==cMark?"ui ribbon label":""}>{i}</div></a></td>
                <td>{}<TypeDropdown data={marks[i].type} onChange={switchType}/></td>
                <td>{marks[i].state}</td>
            </tr>
            ``
        ``<div className="ui segment">
            <div className="ui grid">
                <div className="myCanvas ten wide column">
                    <canvas id='canvas'></canvas>
                </div>
                <div className="six wide column">
                    <div className="ui button" onClick={this.addMark}>add</div>
                    <div className="ui button" onClick={this.delMark}>delete</div>
                    <MyCheckbox
                        text="Show mark"
                        dataOwner={[this,"showMark"]}/>
                    <MyCheckbox
                        text="Smooth"
                        dataOwner={[this, "smooth"]}/>
                    <MyDropdown
                        dataOwner={[this, "editMode"]}
                        defaultText="Edit mode"
                        options={[
                            {value:"pan",text:"Pan"},
                            {value:"spotting",text:"Instance Spotting"},
                            {value:"segment",text:"Instance Segmentation"}]} />
                    <table className="ui celled table">
                        <thead>
                            <tr><th>Mark ID</th>
                            <th>type</th>
                            <th>state</th></tr>
                        </thead>
                        <tbody>
                        {marksUI}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>``

# props
# data
# dataOwner:[ref,dataKey]
class MyComponent extends React.Component
    componentWillMount: ->
        if @props.dataOwner?
            [@dataOwner, @dataKey] = @props.dataOwner
            @set-state data:@dataOwner.state[@dataKey]
            @onChange = (data) ~> @dataOwner.set-state "#{@dataKey}":data
        else if @props.data?
            @set-state @props{data}
            @onChange = @props.onChange

    set-data: ->
        @set-state data:it
        if this.onChange then this.onChange it

# props
# text
class MyCheckbox extends MyComponent
    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        cb = jq.checkbox do
            onChecked: ~> @set-data true
            onUnchecked: ~> @set-data false
        cb.checkbox if @state.data then "set checked" else "set unchecked"

    render: ->
        ``<div className="ui checkbox">
          <input type="checkbox" />
          <label>{this.props.text}</label>
        </div>``

# props
# options:[{value,text}]
# defaultText
class MyDropdown extends MyComponent
    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        dd = jq.dropdown do
            onChange: @onChange
        dd.dropdown 'set selected', @state.data

    render: ->
        optList = for opt in @props.options
            ``<div className="item" data-value={opt.value} key={opt.value}>{opt.text}</div>
            ``
        ``<div className="ui selection dropdown">
          <input type="hidden" />
          <i className="dropdown icon"></i>
          <div className="default text">{this.props.defaultText}</div>
          <div className="menu">
            {optList}
          </div>
        </div>``

class TypeDropdown extends MyComponent

    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        @popup = jq.find ".menu a" .popup do
            popup: jq.find \.popup
            on: \click
            position : 'bottom left'
            # avoid popup set width
            setFluidWidth: false

    render: ->
        text = if @state.data == "" then "Please select" else @state.data
        img-url = types.url-map[@state.data]

        types-ui = []
        for k,v of types.all-data
            # if k>4 then break
            subList = []
            for id,i of v.types
                f = ->
                    @set-data it
                    if @popup then @popup.popup \hide
                f .= bind this, i.title
                subList.push ``<a onClick={f} key={id}>
                    <img src={i.src} title={i.title} className="ui mini left floated image" style={{margin:'1px'}}/></a>``
            types-ui.push ``<div className="column" style={{padding:'3px'}} key={k}>
                <h4 className="ui header">{v.description}</h4>
                <div className="">
                    {subList}
                </div>
            </div>``

        ``<div>
        <div className="ui text menu">
          <a className="item">
            <img src={imgUrl} />
          </a>
          <a className="browse item">
            {text}
            <i className="dropdown icon"></i>
          </a>
        </div>
        <div className="ui flowing basic admission fluid popup"
        style={{width: '960px'}}>
          <div className="ui eleven column relaxed divided grid">
                {typesUi}
          </div>
        </div></div>
        ``

class MainPage extends React.Component
    ->
        store.connect-to-component this, [\currentItem]

    render: ->
        type = @state.currentItem?type
        ``<div className="ui container">
            <Guider />
            {
                type == "item"? <Editor /> : <Displayer />
            }
        </div>
        ``

class App extends React.Component

    componentDidMount: ->
        actions.set-store fatherId:@props.params.itemId

    componentWillUpdate: ->
        actions.set-store fatherId:it.params.itemId

    render: ->
        ``<div>
            <Navbar />
            <MainPage />
            <Footer />
        </div>
        ``

module.exports = App

movePolygon = (poly, delta) ->
    delta = new paper.Point delta
    for i of poly then poly[i] = delta.add poly[i]
