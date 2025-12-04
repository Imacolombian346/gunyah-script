#!/system/bin/sh

cd /data/local/tmp

ifname=crosvm_tap
if [ ! -d /sys/class/net/$ifname ]; then
    ip tuntap add mode tap vnet_hdr $ifname
    ip addr add 192.168.8.1/24 dev $ifname
    ip link set $ifname up
    ip r a table wlan0 192.168.8.0/24 via 192.168.8.1 dev $ifname
    iptables -D INPUT -j ACCEPT -i $ifname
    iptables -D OUTPUT -j ACCEPT -o $ifname
    iptables -I INPUT -j ACCEPT -i $ifname
    iptables -I OUTPUT -j ACCEPT -o $ifname
    iptables -t nat -D POSTROUTING -j MASQUERADE -o wlan0 -s 192.168.8.0/24
    iptables -t nat -I POSTROUTING -j MASQUERADE -o wlan0 -s 192.168.8.0/24
    sysctl -w net.ipv4.ip_forward=1
    
    ip rule add from all fwmark 0/0x1ffff iif wlan0 lookup wlan0
    ip rule add iif $ifname lookup wlan0
    
    iptables -j ACCEPT -D FORWARD -i $ifname -o wlan0
    iptables -j ACCEPT -D FORWARD -m state --state ESTABLISHED,RELATED -i wlan0 -o $ifname
    iptables -j ACCEPT -D FORWARD -m state --state ESTABLISHED,RELATED -o wlan0 -i $ifname
    iptables -j ACCEPT -I FORWARD -i $ifname -o wlan0
    iptables -j ACCEPT -I FORWARD -m state --state ESTABLISHED,RELATED -i wlan0 -o $ifname
    iptables -j ACCEPT -I FORWARD -m state --state ESTABLISHED,RELATED -o wlan0 -i $ifname
fi

ulimit -l unlimited
LD_PRELOAD=./libbinder_ndk.so:./libbinder.so /data/local/tmp/crosvm-a16 --log-level debug run \
  --disable-sandbox --no-balloon --protected-vm-without-firmware --swiotlb 64 \
  --params 'root=/dev/vda rw' --mem 4096 --cpus 4 \
  --net tap-name=$ifname \
  --rwdisk root_part /data/local/tmp/kernel
