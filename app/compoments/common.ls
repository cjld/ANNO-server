require! {
    \react : React
    \react-router : {Link}
    \react-dom : ReactDOM
    \react-timer-mixin : TimerMixin
    \../actions/mainAction : {actions, store}
}

# props
# data
# dataOwner:[ref,dataKey]
class MyComponent extends React.Component
    componentWillMount: ->
        if @props.dataOwner?
            [@dataOwner, @dataKey] = @props.dataOwner
            @set-state data:@dataOwner.state[@dataKey]
            @onChange = (data) ~>
                @state.data = data
                if @dataOwner.state?[@dataKey] != data
                    @dataOwner.set-state "#{@dataKey}":data
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
        @dd = jq.dropdown do
            onChange: @onChange
        @dd.dropdown 'set selected', @state.data

    shouldComponentUpdate: (next-props, next-state)->
        if next-props.data and @props.data != next-props.data
            @dd.dropdown 'set selected', next-props.data
        return false

    render: ->
        console.log \dd-render
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

module.exports = {
    React, Link, ReactDOM, TimerMixin, actions, store
    MyComponent, MyCheckbox, MyDropdown
}
