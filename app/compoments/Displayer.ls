require! \./common
require! \prelude : _
{React, Link, ReactDOM, TimerMixin, actions, store} = common

my-parse-int = ->
    a = parseInt it
    if a==NaN then a=1
    return a

class Pagebar extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \counter
            \page
            \tabType
            \fatherId
        ]

    render: ->
        page-size = my-parse-int @state.counter.page-size
        totalPage = Math.ceil (my-parse-int @state.counter[@state.tabType]) / page-size
        page = my-parse-int @state.page
        showpage = [1,2,3,page-1,page,page+1,totalPage-2, totalPage-1, totalPage].sort!
            |> _.array.unique |> _.array.filter -> it>0 and it<=totalPage
        pageUI = []
        fatherId = this.state.fatherId
        unless fatherId? then fatherId = ""
        for p,i in showpage
            if i!=0 and showpage[i-1] != p-1
                pageUI.push ``<div className="disabled item" key={"."+i}>...</div>``
            cstr = if p==page then "active item" else "item"
            furl = if fatherId? and fatherId!="" then "/"+fatherId else ""
            pageUI.push ``<Link key={i} to={"/i"+furl+"/page/"+p} className={cstr}>{p}</Link>``
        ``<div className="ui pagination secondary pointing menu">
            {pageUI}
        </div>
        ``


module.exports = class Displayer extends React.Component
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
                    {
                        (it.type=="item")?
                            <img className="ui bordered image" src={it.url} alt="" />
                        :
                            <h3><i className="ui huge folder open icon" />{it.name}</h3>
                    }
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
            <Pagebar />
        </div></div>
        ``
