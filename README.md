# 无畏契约每日商店邮件推送

查询《无畏契约》每日商店，生成包含商品名称、价格和图片的汇总图，并通过邮件发送。首次运行支持 QQ 或微信扫码登录，登录凭证保存在本地，后续可配合定时任务自动执行。

> 本项目为非官方工具，与 Riot Games、腾讯游戏无隶属或合作关系。接口可能随官方更新而失效，请合理使用并自行承担账号与数据风险。

## 功能

- QQ / 微信扫码登录
- 自动保存和刷新本地登录状态
- 查询每日商店商品及价格
- 下载商品素材并生成汇总图片
- 通过 SMTP 邮件推送
- 支持 Windows、Linux 和 OpenWrt 定时运行

## 环境要求

- Python 3.10 或更高版本
- 可访问相关腾讯服务与邮箱 SMTP 服务的网络环境

## 安装

```bash
git clone https://github.com/Ceylan233/valorant-daily-shop-email.git
cd valorant-daily-shop-email
python -m venv .venv
```

Windows：

```powershell
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Linux / OpenWrt：

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

## 配置

程序通过环境变量读取邮箱信息。163 邮箱需要使用 SMTP 授权码，不要填写邮箱登录密码。

| 变量 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `MAIL_USER` | 是 | - | 发件邮箱 |
| `MAIL_PASS` | 是 | - | SMTP 授权码 |
| `MAIL_TO` | 否 | 与发件邮箱相同 | 收件邮箱 |
| `SMTP_HOST` | 否 | `smtp.163.com` | SMTP 服务器 |
| `SMTP_PORT` | 否 | `465` | SMTP SSL 端口 |
| `VAL_SHOP_SUBJECT_PREFIX` | 否 | `无畏契约每日商店` | 邮件标题前缀 |

PowerShell 示例：

```powershell
$env:MAIL_USER="your_email@163.com"
$env:MAIL_PASS="your_smtp_authorization_code"
$env:MAIL_TO="recipient@example.com"
python main.py
```

Linux / OpenWrt 示例：

```bash
export MAIL_USER="your_email@163.com"
export MAIL_PASS="your_smtp_authorization_code"
export MAIL_TO="recipient@example.com"
python3 main.py
```

首次运行时按提示选择 QQ 或微信扫码登录。成功后会生成 `config.json`，其中包含账号登录凭证，已被 `.gitignore` 排除，请勿公开或分享。

## 定时运行

OpenWrt / Linux 可使用 `cron`，例如每天 08:05 执行：

```cron
5 8 * * * cd /root/valorant-daily-shop-email && MAIL_USER="your_email@163.com" MAIL_PASS="your_smtp_authorization_code" MAIL_TO="recipient@example.com" /usr/bin/python3 main.py >> valorant_shop.log 2>&1
```

## 常见问题

- 登录凭证失效：程序会删除本地 `config.json`，再次运行并扫码登录即可。
- 中文显示异常：可在项目目录放置 `fontFamily.ttf`，程序也会尝试使用系统中文字体。
- 邮件发送失败：确认邮箱已启用 SMTP 服务，填写的是授权码，并检查 SMTP 主机和端口。

## 安全说明

- 不要提交 `.env`、`config.json` 或登录二维码。
- 建议使用专用邮箱授权码，并定期轮换。
- 已经公开过的登录凭证应立即作废并重新登录。

## License

[MIT](LICENSE)
