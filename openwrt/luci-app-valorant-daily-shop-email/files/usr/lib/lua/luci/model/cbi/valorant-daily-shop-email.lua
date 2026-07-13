local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local m = Map("valorant-daily-shop-email", translate("无畏契约每日商店"))

local s = m:section(NamedSection, "main", "valorant", translate("管理"))
s.addremove = false
s:tab("status", translate("运行状态"))

local o = s:taboption("status", DummyValue, "_service", translate("定时服务"))
o.rawhtml = true
function o.cfgvalue()
	if sys.call("/etc/init.d/valorant-daily-shop-email status >/dev/null 2>&1") == 0 then
		return '<span style="color:#2d8a34;font-weight:bold">运行中</span>'
	end
	return '<span style="color:#b33a3a;font-weight:bold">未运行</span>'
end

o = s:taboption("status", DummyValue, "_account", translate("账号凭证"))
function o.cfgvalue()
	return fs.access("/etc/valorant-daily-shop-email/config.json") and translate("已绑定") or translate("未绑定")
end

o = s:taboption("status", ListValue, "login_method", translate("扫码方式"))
o:value("qq", "QQ")
o:value("wechat", translate("微信"))
o.default = "qq"

o = s:taboption("status", DummyValue, "_bind", translate("扫码绑定账号"))
o.rawhtml = true
function o.cfgvalue()
	return '<button type="button" id="valorant-start-bind" class="cbi-button cbi-button-apply">扫码绑定账号</button>'
end

o = s:taboption("status", DummyValue, "_qr", translate("登录二维码"))
o.rawhtml = true
function o.cfgvalue()
	if sys.call("ls /tmp/valorant-daily-shop-email/*_login_*.png >/dev/null 2>&1") == 0 then
		return '<div id="valorant-bind-status"><span id="valorant-bind-message">请扫码完成绑定</span><img id="valorant-bind-qr" src="' .. luci.dispatcher.build_url("admin", "services", "valorant-daily-shop-email", "qr") .. '?t=' .. os.time() .. '" alt="登录二维码" /></div>'
	end
	return '<div id="valorant-bind-status"><span id="valorant-bind-message">' .. translate("暂无二维码") .. '</span><img id="valorant-bind-qr" alt="登录二维码" style="display:none" /></div>'
end

o = s:taboption("status", Button, "_run", translate("立即运行"))
o.inputstyle = "apply"
function o.write()
	sys.call("/usr/libexec/valorant-daily-shop-email/run run >/tmp/valorant-daily-shop-email.log 2>&1 &")
	m.message = translate("任务已启动。")
end

o = s:taboption("status", Button, "_test", translate("发送测试邮件"))
o.inputstyle = "apply"
function o.write()
	local result = sys.call("/usr/libexec/valorant-daily-shop-email/run test >/tmp/valorant-daily-shop-email.log 2>&1")
	m.message = result == 0 and translate("测试邮件发送成功。") or translate("发送失败，请查看运行日志。")
end

o = s:taboption("status", DummyValue, "_log", translate("运行日志"))
o.rawhtml = true
function o.cfgvalue()
	local output = trim(sys.exec("tail -n 40 /tmp/valorant-daily-shop-email.log 2>/dev/null"))
	return '<pre style="max-height:320px;overflow:auto;white-space:pre-wrap">' .. util.pcdata(output ~= "" and output or translate("暂无日志")) .. '</pre>'
end

s:tab("schedule", translate("定时设置"))
s:tab("mail", translate("邮件设置"))
o = s:taboption("schedule", Flag, "enabled", translate("启用每日推送"))
o.default = 0
o.rmempty = false
o = s:taboption("schedule", Value, "hour", translate("小时"))
o.datatype = "range(0,23)"
o.default = 8
o.rmempty = false
o = s:taboption("schedule", Value, "minute", translate("分钟"))
o.datatype = "range(0,59)"
o.default = 5
o.rmempty = false
o = s:taboption("mail", ListValue, "mail_provider", translate("发件邮箱类型"))
o:value("163", "163 邮箱")
o:value("126", "126 邮箱")
o:value("qq", "QQ / Foxmail")
o:value("gmail", "Gmail")
o:value("yahoo", "Yahoo Mail")
o:value("outlook", "Outlook / Hotmail")
o:value("custom", translate("自定义 SMTP"))
o.default = "163"
o.rmempty = false
o = s:taboption("mail", Value, "smtp_host", translate("SMTP 服务器"))
o:depends("mail_provider", "custom")
o = s:taboption("mail", Value, "smtp_username", translate("SMTP 登录用户名"))
o:depends("mail_provider", "custom")
o.description = translate("留空时使用发件邮箱作为登录用户名。")
o = s:taboption("mail", Value, "smtp_port", translate("SMTP 端口"))
o.datatype = "port"
o.default = 465
o:depends("mail_provider", "custom")
o = s:taboption("mail", ListValue, "smtp_security", translate("SMTP 加密"))
o:value("ssl", "SSL/TLS")
o:value("starttls", "STARTTLS")
o:value("plain", translate("不加密"))
o.default = "ssl"
o:depends("mail_provider", "custom")
o = s:taboption("mail", Value, "mail_user", translate("发件邮箱"))
o.rmempty = false
o = s:taboption("mail", Value, "mail_pass", translate("SMTP 授权码或应用密码"))
o.password = true
o.rmempty = false
o = s:taboption("mail", DynamicList, "mail_to", translate("收件邮箱"))
o.rmempty = false
o = s:taboption("mail", Value, "subject_prefix", translate("邮件主题前缀"))
o.default = "无畏契约每日商店"
o.rmempty = false

function m.on_after_commit()
	sys.call("chmod 600 /etc/config/valorant-daily-shop-email 2>/dev/null")
	sys.call("/etc/init.d/valorant-daily-shop-email restart >/dev/null 2>&1")
end

m:append(Template("valorant-daily-shop-email/status"))

return m
