require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! {
    \owasp-password-strength-test : owasp
    \../history : myhistory
}


owasp.config do
  maxLength              : 128,
  minLength              : 7,
  minOptionalTestsToPass : 1

module.exports = class Signup extends React.Component
    ->
        super ...
        @state = { passwordError: "" }

    componentDidMount: ->
        $ @form .on \submit ~>
            data = $ @form .serializeArray!
            data2 = {}
            for kv in data
                if kv.name == \password
                    ps = kv.value
                    kv.value = md5 ps
                data2[kv.name] = kv.value
            result = owasp.test ps
            if not result.strong
                @set-state passwordError: result.errors.join("\n")
                return false
            else
                @set-state passwordError: ""
            $.ajax do
                method: \POST
                url: \/api/signup
                data: data2
                success: ->
                    toastr.success "Sign up successful."
                    actions.set-store userProfile: it
                    myhistory.push \/profile
                error: (e)->
                    toastr.error "Sign up error: "+e.response-text
            return false

    componentWillUnmount: ->
        $ @form .off \submit

    render: ->
        errc = ""
        if @state.passwordError
            errc = " error"
            errorMsg = ``<div className="ui error message">
                    <div className="header">Action Forbidden</div>
                    <pre>{this.state.passwordError}</pre>
                </div>``
        return ``<div className="ui padded text container segment">
            <div className="ui header"> Sign up </div>
            <div className="ui divider"></div>
            <form className={"ui form"+errc} ref={(it) => this.form=it}>
                <div className="field">
                    <label>Email</label>
                    <input type="text" name="email" placeholder="example@gmail.com" />
                </div>
                <div className="field">
                    <label>Name</label>
                    <input type="text" name="name" placeholder="Dun Liang" />
                </div>
                <div className="field">
                    <label>Password</label>
                    <input type="password" name="password" placeholder="" />
                </div>
                {errorMsg}
                <button className="ui green button" type="submit">Sign up</button>
            </form>
        </div>``
