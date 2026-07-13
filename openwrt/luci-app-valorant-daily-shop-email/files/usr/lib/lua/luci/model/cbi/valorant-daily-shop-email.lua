local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local m = Map("valorant-daily-shop-email", translate("无畏契约每日商店"))

local s = m:section(NamedSection, "main", "valorant", translate("运行状态"))
s.addremove = false

local o = s:option(DummyValue, "_service", translate("定时服务"))
o.rawhtml = true
function o.cfgvalue()
	if sys.call("/etc/init.d/valorant-daily-shop-email status >/dev/null 2>&1") == 0 then
		return '<span style="color:#2d8a34;font-weight:bold">运行中</span>'
	end
	return '<span style="color:#b33a3a;font-weight:bold">未运行</span>'
end

o = s:option(DummyValue, "_account", translate("账号凭证"))
function o.cfgvalue()
	return fs.access("/etc/valorant-daily-shop-email/config.json") and translate("已绑定") or translate("未绑定")
end

o = s:option(Button, "_bind", translate("扫码绑定账号"))
o.inputstyle = "apply"
function o.write()
	sys.call("rm -f /tmp/valorant-daily-shop-email.log /tmp/valorant-daily-shop-email/*_login_*.png")
	sys.call("/usr/libexec/valorant-daily-shop-email/run bind >/tmp/valorant-daily-shop-email.log 2>&1 &")
	m.message = translate("绑定任务已启动，请稍后刷新页面扫描二维码。")
end

o = s:option(DummyValue, "_qr", translate("登录二维码"))
o.rawhtml = true
function o.cfgvalue()
	if sys.call("ls /tmp/valorant-daily-shop-email/*_login_*.png >/dev/null 2>&1") == 0 then
		return '<img src="' .. luci.dispatcher.build_url("admin", "services", "valorant-daily-shop-email", "qr") .. '?t=' .. os.time() .. '" style="width:240px;height:240px;object-fit:contain" />'
	end
	return translate("暂无二维码")
end

o = s:option(Button, "_run", translate("立即运行"))
o.inputstyle = "apply"
function o.write()
	sys.call("/usr/libexec/valorant-daily-shop-email/run run >/tmp/valorant-daily-shop-email.log 2>&1 &")
	m.message = translate("任务已启动。")
end

o = s:option(Button, "_test", translate("发送测试邮件"))
o.inputstyle = "apply"
function o.write()
	local result = sys.call("/usr/libexec/valorant-daily-shop-email/run test >/tmp/valorant-daily-shop-email.log 2>&1")
	m.message = result == 0 and translate("测试邮件发送成功。") or translate("发送失败，请查看运行日志。")
end

o = s:option(DummyValue, "_log", translate("运行日志"))
o.rawhtml = true
function o.cfgvalue()
	local output = trim(sys.exec("tail -n 40 /tmp/valorant-daily-shop-email.log 2>/dev/null"))
	return '<pre style="max-height:320px;overflow:auto;white-space:pre-wrap">' .. util.pcdata(output ~= "" and output or translate("暂无日志")) .. '</pre>'
end

s = m:section(NamedSection, "main", "valorant", translate("定时设置"))
s.addremove = false
o = s:option(Flag, "enabled", translate("启用每日推送"))
o.default = 0
o.rmempty = false
o = s:option(Value, "hour", translate("小时"))
o.datatype = "range(0,23)"
o.default = 8
o.rmempty = false
o = s:option(Value, "minute", translate("分钟"))
o.datatype = "range(0,59)"
o.default = 5
o.rmempty = false
o = s:option(ListValue, "login_method", translate("扫码方式"))
o:value("qq", "QQ")
o:value("wechat", translate("微信"))
o.default = "qq"

s = m:section(NamedSection, "main", "valorant", translate("邮件设置"))
s.addremove = false
o = s:option(ListValue, "mail_provider", translate("发件邮箱类型"))
o:value("163", "163 邮箱")
o:value("126", "126 邮箱")
o:value("qq", "QQ / Foxmail")
o:value("gmail", "Gmail")
o:value("yahoo", "Yahoo Mail")
o:value("outlook", "Outlook / Hotmail")
o:value("custom", translate("自定义 SMTP"))
o.default = "163"
o.rmempty = false
o = s:option(Value, "mail_user", translate("发件邮箱"))
o.rmempty = false
o = s:option(Value, "mail_pass", translate("SMTP 授权码或应用密码"))
o.password = true
o.rmempty = false
o = s:option(DynamicList, "mail_to", translate("收件邮箱"))
o.rmempty = false
o = s:option(Value, "subject_prefix", translate("邮件主题前缀"))
o.default = "无畏契约每日商店"
o.rmempty = false
o = s:option(Value, "smtp_host", translate("SMTP 服务器"))
o:depends("mail_provider", "custom")
o = s:option(Value, "smtp_username", translate("SMTP 登录用户名"))
o:depends("mail_provider", "custom")
o.description = translate("留空时使用发件邮箱作为登录用户名。")
o = s:option(Value, "smtp_port", translate("SMTP 端口"))
o.datatype = "port"
o.default = 465
o:depends("mail_provider", "custom")
o = s:option(ListValue, "smtp_security", translate("SMTP 加密"))
o:value("ssl", "SSL/TLS")
o:value("starttls", "STARTTLS")
o:value("plain", translate("不加密"))
o.default = "ssl"
o:depends("mail_provider", "custom")

function m.on_after_commit()
	sys.call("chmod 600 /etc/config/valorant-daily-shop-email 2>/dev/null")
	sys.call("/etc/init.d/valorant-daily-shop-email restart >/dev/null 2>&1")
end

return m
