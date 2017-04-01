require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! {
    \../history : myhistory
    \owasp-password-strength-test : owasp
}

module.exports = class Forget extends React.Component
    ->
        super ...
        @state =
            isSend: false
            passwordError: ""
    componentDidMount: ->
        $ @form .on \submit ~>
            data = $ @form .serializeArray!
            data2 = {}
            for kv in data
                if kv.name == \password or kv.name == \password2
                    ps = kv.value
                    kv.value = md5 ps
                data2[kv.name] = kv.value
            if data2["password"] != data2["password2"]
                @set-state passwordError: "Two password different."
                return false
            result = owasp.test ps
            if not result.strong
                @set-state passwordError: result.errors.join("\n")
                return false
            else
                @set-state passwordError: ""
            $.ajax do
                method: \POST
                url: \/api/reset-password
                data: data2
                success: ->
                    toastr.success "Reset password successful."
                    actions.set-store userProfile: it
                    myhistory.push \/signin
                error: (e)->
                    toastr.error "Error: "+e.response-text
            return false

    componentWillUnmount: ->
        $ @form .off \submit

    sendCode: ~>
        email = $ @form .find "[name=email]" .val!
        $.ajax do
            method: \POST
            url: \/api/sendcode
            data: {email}
            success: ~>
                toastr.success "Please check your email."
                @set-state isSend:true
            error: (e) ->
                toastr.error "Error: "+e.response-text
        return false


    render: ->
        errc = ""
        if @state.passwordError
            errc = " error"
            errorMsg = ``<div className="ui error message">
                    <div className="header">Action Forbidden</div>
                    <pre>{this.state.passwordError}</pre>
                </div>``
        return ``<div className="ui padded text container segment">
            <div className="ui header"> Password reset </div>
            <div className="ui divider"></div>
            <form className={"ui form"+errc} ref={(it) => this.form=it}>
              <div className="field">
                <label>Email</label>
                <div className="fields">
                    <div className="twelve wide field">
                        <input type="text" name="email" placeholder="example@gmail.com" />
                    </div>
                    <div className="four wide field">
                        <button type="button" className={this.state.isSend?"ui disabled button":"ui button"} onClick={()=>this.sendCode()}>Send code</button>
                    </div>
                </div>
              </div>
              <div className="field">
                <label>Reset code</label>
                <input name="resetcode" placeholder="" />
              </div>
              <div className="field">
                <label>New password</label>
                <input type="password" name="password" placeholder="" />
              </div>
              <div className="field">
                <label>New Password again</label>
                <input type="password" name="password2" placeholder="" />
              </div>
              {errorMsg}
              <button className="ui green button" type="submit">Reset</button>
            </form>
        </div>``
