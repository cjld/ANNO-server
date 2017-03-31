require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! {
    \../history : myhistory
}

module.exports = class Signin extends React.Component
    componentDidMount: ->
        $ @form .on \submit ~>
            data = $ @form .serializeArray!
            data2 = {}
            for kv in data
                if kv.name == \password
                    ps = kv.value
                    kv.value = md5 ps
                data2[kv.name] = kv.value
            $.ajax do
                method: \POST
                url: \/api/signin
                data: data2
                success: ->
                    toastr.success "Sign in successful."
                    actions.set-store userProfile: it
                    myhistory.push \/profile
                error: (e)->
                    toastr.error "Sign in error: "+e.response-text
            return false

    componentWillUnmount: ->
        $ @form .off \submit

    render: ->
        return ``<div className="ui padded text container segment">
            <div className="ui header"> Sign in </div>
            <div className="ui divider"></div>
            <form className="ui form" ref={(it) => this.form=it}>
              <div className="field">
                <label>Email</label>
                <input type="text" name="email" placeholder="example@gmail.com" />
              </div>
              <div className="field">
                <label>Password</label>
                <input type="password" name="password" placeholder="" />
              </div>
              <button className="ui green button" type="submit">Login</button>
            </form>
        </div>``
