-- Soft shutdown / BindToClose so DataStores flush before the server dies.
-- Roblox gives ~30s on BindToClose; we save everyone and optionally notify.

local Players = game:GetService("Players")

local SoftShutdown = {}

function SoftShutdown.Bind(saveAll: () -> (), opts: { notifyRemote: RemoteEvent? }?)
	game:BindToClose(function()
		print("[SoftShutdown] Closing — saving all profiles…")
		local notify = opts and opts.notifyRemote
		if notify then
			for _, p in Players:GetPlayers() do
				pcall(function()
					notify:FireClient(p, {
						kind = "shutdown",
						message = "Server restarting — progress saved. Rejoin in a moment.",
					})
				end)
			end
		end

		local ok, err = pcall(saveAll)
		if not ok then
			warn("[SoftShutdown] saveAll failed:", err)
		end

		-- Brief window so last remote packets can flush
		if #Players:GetPlayers() > 0 then
			task.wait(2)
		end
		print("[SoftShutdown] Done")
	end)
end

return SoftShutdown
