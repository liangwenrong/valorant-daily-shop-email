import importlib.util
import os
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


if __name__ == "__main__":
    unittest.main()
