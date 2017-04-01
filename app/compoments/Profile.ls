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

module.exports = class Profile extends React.Component
    ->
        super ...
        @state = { passwordError: "" }
        store.connect-to-component this, [\userProfile]

    submit: ~>
        data = $ @form .serializeArray!
        data2 = {}
        ps = ""
        for kv in data
            if kv.value == "" then continue
            if kv.value == @state.userProfile[kv.name]
                continue
            if kv.name == \password or kv.name == \password2 or kv.name == \oldpassword
                ps = kv.value
                kv.value = md5 ps
            data2[kv.name] = kv.value
        if ps != ""
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
            url: \/api/edit-profile
            data: data2
            success: ->
                toastr.success "Edit profile successful."
                actions.set-store userProfile: it
            error: (e)->
                toastr.error "Edit profile error: "+e.response-text
        return false

    componentDidMount: ->
        @form = $ "form" .0
        @form?onsubmit = @submit

    componentDidUpdate: ->
        @componentDidMount!

    componentWillUnmount: ->

    render: ->
        if not @state.userProfile
            return ``<div className="ui padded text container segment">
                <div className="ui header"> Please login first </div>
            </div>``
        errc = ""
        userProfile = @state.userProfile
        if @state.passwordError
            errc = " error"
            errorMsg = ``<div className="ui error message">
                    <div className="header">Action Forbidden</div>
                    <pre>{this.state.passwordError}</pre>
                </div>``
        return ``<div className="ui padded text container segment">
            <div className="ui header"> Profile </div>
            <div className="ui divider"></div>
            <form className={"ui form"+errc}>
                <div className="disabled field">
                    <label>Email</label>
                    <input type="text" name="email" placeholder="" defaultValue={userProfile.email} />
                </div>
                <div className="field">
                    <label>Name</label>
                    <input type="text" name="name" placeholder="" defaultValue={userProfile.name}/>
                </div>
                <h4 className="ui dividing header">Google acccount</h4>
                {userProfile.googleId ?
                    <div className="disabled field">
                        <label>Google ID</label>
                        <input type="text" name="googleId" placeholder="" defaultValue={userProfile.googleId}/>
                    </div>
                :
                  <button type="button" className="ui google plus button" onClick={()=>location.href = "/api/auth/google"}>
                    <i className="google icon"></i>
                    Link with Google
                  </button>
                }

                <h4 className="ui dividing header">Change password</h4>
                <div className="field">
                    <label>Old password</label>
                    <input type="password" name="oldpassword" placeholder="" />
                </div>
                <div className="field">
                    <label>New password</label>
                    <input type="password" name="password" placeholder="" />
                </div>
                <div className="field">
                    <label>New password again</label>
                    <input type="password" name="password2" placeholder="" />
                </div>
                {errorMsg}
                <button className="ui green button" type="submit">Change Profile</button>
            </form>
        </div>``
