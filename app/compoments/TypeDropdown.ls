require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent} = common

require! {
    \../models/types
}

module.exports = class TypeDropdown extends MyComponent

    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        @popup = jq.find ".menu a" .popup do
            popup: jq.find \.popup
            on: \click
            position : 'bottom left'
            # avoid popup set width
            setFluidWidth: false

    shouldComponentUpdate: (next-props, next-state) ->
        res = next-props.data != @state.data
        @state.data = next-props.data
        res

    render: ->
        text = if @state.data == "" then "Please select" else @state.data

        img-url = types.url-map[@state.data]?.src
        if img-url? then imgui = ``<img src={imgUrl} />``

        types-ui = []
        for k,v of types.all-data
            # if k>4 then break
            subList = []
            for id,i of v.types
                f = ->
                    @set-data it
                    if @popup then @popup.popup \hide
                f .= bind this, i.title
                tag-ui = if i.src?
                    ``<img src={i.src} title={i.title} className="ui mini left floated image" style={{margin:'1px'}}/>``
                else
                    ``<div className='ui button'
                        style={{
                            'background-color':i.color,
                            'color':'#FFF',
                            'margin-bottom': '5px',
                            'text-shadow': '1px 0 1px #000000, 0 1px 1px #000000, 0 -1px 1px #000000, -1px 0 1px #000000'}}>{i.title}</div>``
                subList.push ``<a onClick={f} key={id}> {tagUi} </a>``
            types-ui.push ``<div className="column" style={{padding:'3px'}} key={k}>
                <h4 className="ui header">{v.description}</h4>
                <div className="">
                    {subList}
                </div>
            </div>``
        ``<div>
        <div className="ui text menu">
          <a className="item">
            {imgui}
          </a>
          <a className="browse item">
            {text}
            <i className="dropdown icon"></i>
          </a>
        </div>
        <div className="ui flowing basic admission fluid popup"
        style={{width: '960px'}}>
          <div className="ui one column relaxed divided grid">
                {typesUi}
          </div>
        </div></div>
        ``
