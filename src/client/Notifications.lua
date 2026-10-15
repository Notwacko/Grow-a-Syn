local Net = require(script.Parent.Net)
local C = require(script.Parent.Components)
local Sound = require(script.Parent.Sound)

local Notifications = {}

function Notifications.init(ctx)
	Net.Notified:connect(function(kind, text)
		if type(text) == "string" and text ~= "" then
			if kind == "error" then
				Sound.play("error")
			end
			C.toast(ctx.layers.toast, text, kind)
		end
	end)
end

function Notifications.local_(ctx, text, kind)
	C.toast(ctx.layers.toast, text, kind or "info")
end

return Notifications
