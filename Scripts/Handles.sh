#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

if [ -n "${GITHUB_WORKSPACE:-}" ] && [ -d "$GITHUB_WORKSPACE/wrt/package" ]; then
	PKG_PATH="$GITHUB_WORKSPACE/wrt/package"
else
	PKG_PATH="$(pwd)"
fi

#修改 Argon 主题字体和颜色
if [ -d "$PKG_PATH/luci-theme-argon" ]; then
	echo " "
	if sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" \
		"$PKG_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"; then
		echo "theme-argon has been fixed!"
	else
		echo "theme-argon fix failed; continuing!"
	fi
fi

#修改 mini-diskmanager 菜单位置
if [ -d "$PKG_PATH/luci-app-mini-diskmanager" ]; then
	echo " "
	if sed -i "s/services/system/g" \
		"$PKG_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"; then
		echo "mini-diskmanager has been fixed!"
	else
		echo "mini-diskmanager fix failed; continuing!"
	fi
fi

#自动添加 R76S 网络亲和性脚本
if [[ "${WRT_CONFIG,,}" == *"rockchip" ]]; then
	R76S_DEFAULTS="$PKG_PATH/base-files/files/etc/uci-defaults"
	mkdir -p "$R76S_DEFAULTS"
	cat > "$R76S_DEFAULTS/40-net-smp-affinity" <<'EOF'
#!/bin/sh
# NanoPi R76S IRQ affinity: eth0 -> CPU4-5, eth1 -> CPU6-7
[ "$(. /lib/functions.sh; board_name)" = "friendlyarm,nanopi-r76s" ] || exit 0

set_irq_affinity() {
	local iface="$1"
	local mask="$2"
	local irqs

	irqs="$(grep -i "$iface" /proc/interrupts | awk -F: '{print $1}' | tr -d ' ')"
	for irq in $irqs; do
		[ -w "/proc/irq/$irq/smp_affinity" ] && echo "$mask" > "/proc/irq/$irq/smp_affinity"
	done
}

set_irq_affinity eth0 30
set_irq_affinity eth1 c0

exit 0
EOF
	chmod +x "$R76S_DEFAULTS/40-net-smp-affinity"
	echo "R76S 40-net-smp-affinity has been added!"

	NETIFD_PATCH_DIR="$PKG_PATH/network/config/netifd/patches"
	mkdir -p "$NETIFD_PATCH_DIR"
	cat > "$NETIFD_PATCH_DIR/999-r76s-packet-steering.patch" <<'EOF'
diff --git a/files/etc/init.d/packet_steering b/files/etc/init.d/packet_steering
index 5266a931ae..cec2002683 100755
--- a/files/etc/init.d/packet_steering
+++ b/files/etc/init.d/packet_steering
@@ -1,5 +1,7 @@
 #!/bin/sh /etc/rc.common
 
+. /lib/functions/uci-defaults.sh
+
 START=25
 USE_PROCD=1
 
@@ -16,10 +18,29 @@ service_triggers() {
 reload_service() {
 	packet_steering="$(uci -q get "network.@globals[0].packet_steering")"
 	steering_flows="$(uci -q get "network.@globals[0].steering_flows")"
-	[ "${steering_flows:-0}" -gt 0 ] && opts="-l $steering_flows"
-	if [ -e "/usr/libexec/platform/packet-steering.sh" ]; then
-		/usr/libexec/platform/packet-steering.sh "$packet_steering"
+	if [ "$packet_steering" = "0" ] && [ "$(board_name)" = "friendlyarm,nanopi-r76s" ]; then
+		for iface in eth0 eth1; do
+			[ -d "/sys/class/net/$iface" ] || continue
+
+			case "$iface" in
+				eth0) mask="30" ;;
+				eth1) mask="c0" ;;
+			esac
+
+			for q in /sys/class/net/$iface/queues/rx-*; do
+				[ -e "$q/rps_cpus" ] && echo "$mask" > "$q/rps_cpus"
+			done
+
+			for q in /sys/class/net/$iface/queues/tx-*; do
+				[ -e "$q/xps_cpus" ] && echo "$mask" > "$q/xps_cpus"
+			done
+		done
 	else
-		/usr/libexec/network/packet-steering.uc $opts "$packet_steering"
+		[ "${steering_flows:-0}" -gt 0 ] && opts="-l $steering_flows"
+		if [ -e "/usr/libexec/platform/packet-steering.sh" ]; then
+			/usr/libexec/platform/packet-steering.sh "$packet_steering"
+		else
+			/usr/libexec/network/packet-steering.uc $opts "$packet_steering"
+		fi
 	fi
 }
EOF
	echo "sbwml R76S packet steering patch has been added!"
fi

#修复 Rust 编译失败
RUST_FILE="$(find "$PKG_PATH/../feeds/packages" -maxdepth 3 -type f -wholename '*/rust/Makefile' -print -quit 2>/dev/null)"
if [ -f "$RUST_FILE" ]; then
	echo " "
	if sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"; then
		echo "rust has been fixed!"
	else
		echo "rust fix failed; continuing!"
	fi
fi
