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
	page.leaf = false
	entry(
		{"admin", "services", "valorant-daily-shop-email", "qr"},
		call("action_qr")
	).leaf = true
	entry(
		{"admin", "services", "valorant-daily-shop-email", "status"},
		call("action_status")
	).leaf = true
	entry(
		{"admin", "services", "valorant-daily-shop-email", "bind"},
		call("action_bind")
	).leaf = true
	entry(
		{"admin", "services", "valorant-daily-shop-email", "cancel-bind"},
		call("action_cancel_bind")
	).leaf = true
end

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function latest_qr()
	local sys = require "luci.sys"
	return trim(sys.exec("ls -1t /tmp/valorant-daily-shop-email/*_login_*.png 2>/dev/null | head -n 1"))
end

function action_qr()
	local fs = require "nixio.fs"
	local http = require "luci.http"
	local path = latest_qr()
	if path == "" or not fs.access(path) then
		http.status(404, "Not Found")
		return
	end
	http.header("Content-Type", "image/png")
	http.header("Cache-Control", "no-store")
	http.write(fs.readfile(path))
end

function action_status()
	local fs = require "nixio.fs"
	local http = require "luci.http"
	local json = require "luci.jsonc"
	local sys = require "luci.sys"
	local pid = trim(fs.readfile("/tmp/valorant-daily-shop-email.bind.pid"))
	local running = pid:match("^%d+$") and sys.call("kill -0 " .. pid .. " 2>/dev/null") == 0
	local qr = latest_qr()
	local bound = fs.access("/etc/valorant-daily-shop-email/config.json")
	local log_stat = fs.stat("/tmp/valorant-daily-shop-email.log")
	local log_exists = log_stat and log_stat.size or 0
	local state = "idle"

	if bound then
		state = "bound"
	elseif running and qr ~= "" then
		state = "qr"
	elseif running then
		state = "waiting"
	elseif log_exists > 0 then
		state = "error"
	end

	http.prepare_content("application/json")
	http.header("Cache-Control", "no-store")
	http.write(json.stringify({ state = state, has_qr = qr ~= "" }))
end

function action_bind()
	local http = require "luci.http"
	local json = require "luci.jsonc"
	local sys = require "luci.sys"
	local uci = require("luci.model.uci").cursor()
	local login_method = http.formvalue("login_method")
	if login_method == "qq" or login_method == "wechat" then
		uci:set("valorant-daily-shop-email", "main", "login_method", login_method)
		uci:commit("valorant-daily-shop-email")
	end
	local result = sys.call("/usr/libexec/valorant-daily-shop-email/start-bind >/dev/null 2>&1")
	http.prepare_content("application/json")
	http.header("Cache-Control", "no-store")
	http.write(json.stringify({ ok = result == 0 }))
end

function action_cancel_bind()
	local http = require "luci.http"
	local json = require "luci.jsonc"
	local sys = require "luci.sys"
	local result = sys.call("/usr/libexec/valorant-daily-shop-email/stop-bind >/dev/null 2>&1")
	http.prepare_content("application/json")
	http.header("Cache-Control", "no-store")
	http.write(json.stringify({ ok = result == 0 }))
end
