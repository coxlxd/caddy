#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

[[ $(id -u) != 0 ]] && echo -e " \n哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get || -f /usr/bin/yum ]] && [[ -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi

else

	echo -e " 
    哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
    " && exit 1

fi

if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
	caddy_download_link="https://caddyserver.com/download/linux/386"
elif [[ $sys_bit == "x86_64" ]]; then
	caddy_download_link="https://caddyserver.com/download/linux/amd64"
else
	echo -e " 
    哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
    " && exit 1
fi

ask() {

	while :; do
		echo
		echo -e "请输入一个 $magenta正确的域名$none，一定一定一定要正确，不！能！出！错！"
		read -p "(例如：233abc.com): " domain
		[ -z "$domain" ] && error && continue
		echo
		echo
		echo -e "$yellow 你的域名 = $cyan$domain$none"
		echo "----------------------------------------------------------------"
		break
	done

	get_ip

	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo " 重要的事情要说三次....(^_^)"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(是否已经正确解析: [${magenta}Y$none]):") " record
		if [[ -z "$record" ]]; then
			error
		else
			if [[ "$record" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 域名解析 = ${cyan}OK $none"
				echo "----------------------------------------------------------------"
				echo
				break
			else
				error
			fi
		fi

	done

	while :; do
		read -p "$(echo -e "请输入登录用户名...(默认用户名: ${magenta}233abc$none)"): " username
		[ -z "$username" ] && username="233abc"
		echo
		echo
		echo -e "$yellow 用户名 = $cyan$username$none"
		echo "----------------------------------------------------------------"
		echo
		break

	done

	while :; do
		read -p "$(echo -e "请输入用户密码...(默认密码: ${magenta}233abc.com$none)"): " userpass
		[ -z "$userpass" ] && userpass="233abc.com"
		echo
		echo
		echo -e "$yellow 用户密码 = $cyan$userpass$none"
		echo "----------------------------------------------------------------"
		echo
		break

	done

}

install_info() {
	clear
	echo
	echo " ....准备安装了咯..看看有毛有配置正确了..."
	echo
	echo "---------- 配置信息 -------------"
	echo
	echo -e "$yellow 你的域名 = $cyan$domain$none"
	echo
	echo -e "$yellow 域名解析 = ${cyan}OK${none}"
	echo
	echo -e "$yellow 用户名 = ${cyan}$username$none"
	echo
	echo -e "$yellow 密码 = ${cyan}$userpass$none"
	echo
	pause
}
domain_check() {
	$cmd install dnsutils -y
	test_domain=$(dig $domain +short)
	if [[ $test_domain != $ip ]]; then
		echo -e "
		$red 检测域名解析错误....$none
		
		你的域名: $yellow$domain$none 未解析到: $cyan$ip$none

		备注...如果你的域名是使用 Cloudflare 解析的话..在 Status 那里点一下那图标..让它变灰
		" && exit 1
	fi
}
install_caddy() {
	local caddy_tmp="/tmp/install_caddy/"
	local caddy_tmp_file="/tmp/install_caddy/caddy.tar.gz"
	mkdir -p $caddy_tmp
	$cmd install wget -y
	if ! wget --no-check-certificate -O "$caddy_tmp_file" $caddy_download_link; then
		echo -e "
        $red 下载 Caddy 失败啦..可能是你的小鸡鸡的网络太辣鸡了...重新安装也许能解决$none
        " && exit 1
	fi

	tar zxf $caddy_tmp_file -C $caddy_tmp
	cp -f ${caddy_tmp}caddy /usr/local/bin/

	if [[ ! -f /usr/local/bin/caddy ]]; then
		echo -e "
        $red 哎呀...安装 Caddy 失败咯....$none
        " && exit 1
	fi

	cp ${caddy_tmp}init/linux-systemd/caddy.service /lib/systemd/system/
	sed -i "s/www-data/root/g" /lib/systemd/system/caddy.service
	systemctl enable caddy
	mkdir -p /etc/ssl/caddy
	mkdir -p /etc/caddy
	rm -rf $caddy_tmp $caddy_tmp_file
}
open_port() {
	if [[ $cmd == "apt-get" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
	else
		firewall-cmd --permanent --zone=public --add-port=80/tcp
		firewall-cmd --permanent --zone=public --add-port=443/udp
		firewall-cmd --reload
	fi
}
del_port() {
	if [[ $cmd == "apt-get" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
	else
		firewall-cmd --permanent --zone=public --remove-port=80/tcp
		firewall-cmd --permanent --zone=public --remove-port=443/udp
	fi
}
config_caddy() {
	email=$(shuf -i1-10000000000 -n1)
	Caddyfile_link="https://raw.githubusercontent.com/233abc/caddy/master/Caddyfile"
	Caddyfile_tmp="/tmp/Caddyfile_tmp"
	Caddyfile="/etc/caddy/Caddyfile"
	if ! wget --no-check-certificate -O "$Caddyfile_tmp" $Caddyfile_link; then
		echo -e "
        $red 下载 Caddy 配置文件失败啦..可能是你的小鸡鸡的网络太辣鸡了...重新安装也许能解决$none
        " && exit 1
	fi
	cp -f $Caddyfile_tmp $Caddyfile
	sed -i "1s/233abc.com/$domain/; 3s/233abc/$username/; 3s/233abc.com/$userpass/; 5s/email/$email/" $Caddyfile
	echo -e "User-agent: *\nDisallow: /" >/etc/caddy/robots.txt
	rm -rf $Caddyfile_tmp
	open_port
	systemctl restart caddy
}
show_config_info() {
	clear
	echo
	echo "---------- 安装完成 -------------"
	echo
	echo -e "$yellow 你的域名 = $cyan$domain$none"
	echo
	echo -e "$yellow 用户名 = ${cyan}$username$none"
	echo
	echo -e "$yellow 密码 = ${cyan}$userpass$none"
	echo
	echo " 帮助或反馈: https://233abc.com/post/21/"
	echo
}
unistall() {
	if [[ -f /usr/local/bin/caddy && -f /etc/caddy/Caddyfile ]] && [[ -f /lib/systemd/system/caddy.service ]]; then
		unistall_caddy
	else
		echo -e "
		$red 大胸弟...你貌似毛有安装 Caddy ....卸载个鸡鸡哦...$none

		备注...卸载仅支持使用我(233abc.com)提供的 Caddy 一键反代谷歌安装脚本
		" && exit 1
	fi
}
unistall_caddy() {
	caddy_pid=$(ps ux | pgrep "caddy")
	while :; do
		echo
		read -p "是否卸载[Y/N]:" unistall_caddy_ask
		if [ -z $unistall_caddy_ask ]; then
			error
		else
			if [[ $unistall_caddy_ask == [Yy] ]]; then
				if [[ $caddy_pid ]]; then
					systemctl stop caddy
				fi
				systemctl disable caddy
				rm -rf /lib/systemd/system/caddy.service
				rm -rf /usr/local/bin/caddy /etc/caddy
				rm -rf /etc/ssl/caddy
				del_port
				echo
				echo -e "$green 卸载完成啦.... $none"
				echo
				break
			elif [[ $unistall_caddy_ask == [Nn] ]]; then
				echo
				echo -e "$red....已取消卸载....$none"
				echo
				break
			else
				error
			fi
		fi

	done
}
error() {

	echo -e "\n$red 输入错误！$none\n"

}
pause() {

	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'

}
get_ip() {
	ip=$(curl -s ipinfo.io/ip)
}
install() {
	ask
	install_info
	domain_check
	install_caddy
	config_caddy
	show_config_info
}
clear
while :; do
	echo
	echo "........... Caddy 一键反代谷歌安装脚本 by 233abc.com .........."
	echo
	echo " 1. 安装"
	echo
	echo " 2. 卸载"
	echo
	read -p "请选择[1-2]:" choose
	case $choose in
	1)
		install
		break
		;;
	2)
		unistall
		break
		;;
	*)
		error
		;;
	esac
done