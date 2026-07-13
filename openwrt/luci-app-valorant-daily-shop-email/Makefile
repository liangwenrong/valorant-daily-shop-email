include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-valorant-daily-shop-email
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-valorant-daily-shop-email
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Valorant daily shop email
  PKGARCH:=all
  DEPENDS:=+luci-base +python3 +python3-pip +ca-bundle
endef

define Package/luci-app-valorant-daily-shop-email/description
 LuCI configuration and scheduler for Valorant daily shop email.
endef

define Build/Compile
endef

define Package/luci-app-valorant-daily-shop-email/install
	$(CP) ./files/* $(1)/
endef

define Package/luci-app-valorant-daily-shop-email/conffiles
/etc/config/valorant-daily-shop-email
endef

define Package/luci-app-valorant-daily-shop-email/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
chmod 600 /etc/config/valorant-daily-shop-email 2>/dev/null || true
mkdir -p /etc/valorant-daily-shop-email /tmp/valorant-daily-shop-email
if ! /usr/bin/python3 -c 'import aiohttp, PIL' >/dev/null 2>&1; then
	/usr/bin/pip3 install --no-cache-dir 'aiohttp>=3.9,<4' 'Pillow>=10,<13' || \
		/usr/bin/pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple 'aiohttp>=3.9,<4' 'Pillow>=10,<13' || exit 1
fi
rm -f /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null || true
/etc/init.d/valorant-daily-shop-email enable 2>/dev/null || true
exit 0
endef

define Package/luci-app-valorant-daily-shop-email/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
/etc/init.d/valorant-daily-shop-email stop 2>/dev/null || true
/etc/init.d/valorant-daily-shop-email disable 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,luci-app-valorant-daily-shop-email))
