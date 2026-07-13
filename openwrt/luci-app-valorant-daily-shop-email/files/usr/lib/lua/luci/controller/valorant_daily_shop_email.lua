module("luci.controller.valorant_daily_shop_email", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/valorant-daily-shop-email") then
		return
	end
	local page = entry(
		{"admin", "services", "valorant-daily-shop-email"},
		cbi("valorant-daily-shop-email"),
		_("无畏契约每日商店"),
		66
	)
	page.dependent = true
	entry(
		{"admin", "services", "valorant-daily-shop-email", "qr"},
		call("action_qr")
	).leaf = true
end

function action_qr()
	local fs = require "nixio.fs"
	local http = require "luci.http"
	local sys = require "luci.sys"
	local path = (sys.exec("ls -1t /tmp/valorant-daily-shop-email/*_login_*.png 2>/dev/null | head -n 1") or ""):match("^%s*(.-)%s*$")
	if path == "" or not fs.access(path) then
		http.status(404, "Not Found")
		return
	end
	http.header("Content-Type", "image/png")
	http.header("Cache-Control", "no-store")
	http.write(fs.readfile(path))
end
