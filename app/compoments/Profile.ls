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
                url: \/api/edit-profile
                data: data2
                success: ->
                    toastr.success "Edit profile successful."
                    actions.set-store userProfile: it
                    myhistory.push \/profile
                error: (e)->
                    toastr.error "Edit profile error: "+e.response-text
            return false

    componentWillUnmount: ->
        $ @form .off \submit

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
            <form className={"ui form"+errc} ref={(it) => this.form=it}>
                <div className="disabled field">
                    <label>Email</label>
                    <input type="text" name="email" placeholder="example@gmail.com" defaultValue={userProfile.email} />
                </div>
                <div className="field">
                    <label>Name</label>
                    <input type="text" name="name" placeholder="" defaultValue={userProfile.name}/>
                </div>

                <h4 className="ui dividing header">Change password</h4>
                <div className="field">
                    <label>Old assword</label>
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
