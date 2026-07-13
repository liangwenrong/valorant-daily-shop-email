import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "main.py"


def load_monitor():
    spec = importlib.util.spec_from_file_location("valorant_daily_shop_email", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class MailTests(unittest.TestCase):
    def test_provider_inference_and_recipients(self):
        monitor = load_monitor()
        self.assertEqual(monitor.infer_mail_provider("sender@hotmail.com"), "outlook")
        self.assertEqual(
            monitor.parse_recipients("one@example.com; two@example.com,three@example.com"),
            ["one@example.com", "two@example.com", "three@example.com"],
        )

    def test_custom_smtp_settings(self):
        environment = {
            "MAIL_PROVIDER": "custom",
            "SMTP_HOST": "mail.example.com",
            "SMTP_PORT": "587",
            "SMTP_SECURITY": "starttls",
        }
        with mock.patch.dict(os.environ, environment, clear=True):
            monitor = load_monitor()
            self.assertEqual(
                monitor.smtp_settings("sender@example.com"),
                ("mail.example.com", 587, "starttls"),
            )

    def test_smtp_username_and_multiple_recipients(self):
        environment = {
            "MAIL_PROVIDER": "163",
            "MAIL_USER": "sender@163.com",
            "SMTP_USERNAME": "smtp-login",
            "MAIL_PASS": "authorization-code",
            "MAIL_TO": "one@example.com,two@example.com",
        }
        with mock.patch.dict(os.environ, environment, clear=True):
            monitor = load_monitor()
            app = monitor.ValorantShopEmail()
            message = monitor.MIMEMultipart()
            with mock.patch.object(monitor.smtplib, "SMTP_SSL") as smtp_ssl:
                client = smtp_ssl.return_value.__enter__.return_value
                app._deliver_message(message)
            client.login.assert_called_once_with("smtp-login", "authorization-code")
            self.assertEqual(
                client.sendmail.call_args.args[1],
                ["one@example.com", "two@example.com"],
            )

    def test_html_fallback_contains_product(self):
        monitor = load_monitor()
        app = monitor.ValorantShopEmail()
        content = app.build_mail_html(
            [
                {
                    "goods_name": "测试商品",
                    "rmb_price": "88",
                    "goods_pic": "https://example.com/item.png",
                    "bg_image": "https://example.com/tier.jpg",
                }
            ]
        )
        self.assertIn("测试商品", content)
        self.assertIn("https://example.com/item.png", content)
        self.assertIn('background="https://example.com/tier.jpg"', content)
        self.assertIn("background-image:url('https://example.com/tier.jpg')", content)
        self.assertIn('height="200"', content)

    def test_expired_notice_is_sent_once(self):
        environment = {
            "MAIL_USER": "sender@163.com",
            "MAIL_PASS": "authorization-code",
            "MAIL_TO": "one@example.com",
        }
        with tempfile.TemporaryDirectory() as temp_dir, mock.patch.dict(os.environ, environment, clear=True):
            monitor = load_monitor()
            marker = Path(temp_dir) / "expired"
            app = monitor.ValorantShopEmail()
            with mock.patch.object(monitor, "AUTH_EXPIRED_STATE_FILE", marker), mock.patch.object(
                app, "_deliver_message"
            ) as deliver:
                app.send_auth_expired_notice_once()
                app.send_auth_expired_notice_once()
            deliver.assert_called_once()
            self.assertEqual(marker.read_text(encoding="utf-8"), "sent")


if __name__ == "__main__":
    unittest.main()
