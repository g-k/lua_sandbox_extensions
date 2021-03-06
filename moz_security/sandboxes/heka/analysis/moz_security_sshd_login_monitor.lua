-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--[[
#  Mozilla Security SSHD Login Monitor

Sends a message to Pagerduty anytime there is a successful Bastion sshd login.
Pagerduty will then alert if it is out of policy (hours) for that user.

## Sample Configuration
```lua
filename = "moz_security_sshd_login_monitor.lua"
message_matcher = "Type == 'logging.shared.bastion.systemd.sshd' && Fields[sshd_authmsg] == 'Accepted'"
ticker_interval = 0
process_message_inject_limit = 1

-- default_email = "foxsec-alerts@mozilla.com"
```
--]]
require "string"

local default_email = read_config("default_email") or "foxsec-alerts@mozilla.com"
local msg = {
    Type = "alert",
    Payload = "",
    Severity = 1,
    Fields = {
        {name = "id"                , value = "sshd"},
        {name = "summary"           , value = ""},
        {name = "email.recipients"  , value = {string.format("<%s>", default_email)}}
    }
}

function process_message()
    local user  = read_message("Fields[remote_user]")
    local ip    = read_message("Fields[remote_addr]")
    local id    = string.format("%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X",
                                string.byte(read_message("Uuid"), 1, 16))

    msg.Fields[2].value    = string.format("%s logged into bastion from %s id:%s", user, ip, id)
    msg.Fields[3].value[2] = string.format("<manatee-%s@moz-svc-ops.pagerduty.com>", user)
    inject_message(msg)
    return 0
end


function timer_event()
-- no op
end
