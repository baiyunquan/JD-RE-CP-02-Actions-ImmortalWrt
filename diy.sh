#!/usr/bin/env bash
set -euo pipefail

device_dts="target/linux/ramips/dts/mt7621_jdcloud_re-cp-02.dts"
device_makefile="target/linux/ramips/image/mt7621.mk"
# nikki_dir="package/nikki"

test -f "$device_dts"
grep -q "define Device/jdcloud_re-cp-02" "$device_makefile"
grep -q 'reg = <0x90000 0xf70000>;' "$device_dts"
grep -q '&sdhci' "$device_dts"

# test -f "$nikki_dir/nikki/Makefile"
# test -f "$nikki_dir/mihomo-meta/Makefile"
# test -f "$nikki_dir/luci-app-nikki/Makefile"

# Clone latest native nftables MWAN3 and LuCI app from dl12345 (openwrt-25.12-beta)
rm -rf package/mwan3 package/luci-app-mwan3
git clone -b openwrt-25.12-beta --depth 1 https://github.com/dl12345/mwan3.git package/mwan3
git clone -b openwrt-25.12-beta --depth 1 https://github.com/dl12345/luci-app-mwan3.git package/luci-app-mwan3

# Fix luci.mk include path for standalone luci-app-mwan3
sed -i 's|include ../../luci.mk|include $(TOPDIR)/feeds/luci/luci.mk|' package/luci-app-mwan3/Makefile

# Add IPv6 policy display support to mwan3 policies/status output
sed -i 's/echo "Current policies:"/echo "Current ipv4 policies:"/' package/mwan3/files/usr/sbin/mwan3
sed -i '/mwan3_report_policies_v4/a \\t[ $NO_IPV6 -ne 0 ] \&\& return\n\techo "Current ipv6 policies:"\n\tmwan3_report_policies_v6' package/mwan3/files/usr/sbin/mwan3

test -f package/mwan3/Makefile
test -f package/luci-app-mwan3/Makefile

# mirror.iscas.ac.cn accepts connections but can stop transferring indefinitely.
# Drop it before `make download`, and make curl abandon any other zero-speed
# mirror so the downloader can continue with its next configured source.
sed -i '\#https://mirror\.iscas\.ac\.cn/kernel\.org#d' scripts/projectsmirrors.json
sed -i \
  's/curl -f --connect-timeout 5 --retry 3 --location/curl -f --connect-timeout 5 --speed-limit 1024 --speed-time 30 --retry 3 --location/' \
  scripts/download.pl
grep -q -- '--speed-limit 1024 --speed-time 30' scripts/download.pl

echo "Using upstream jdcloud_re-cp-02 support and native nftables MWAN3."
