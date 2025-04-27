#!/bin/bash

set -e

echo "🔐 Ubuntu 22.04 서버 보안 하드닝 시작..."

# 1. 시스템 패키지 업데이트
echo "📦 시스템 패키지 업데이트"
apt update && apt upgrade -y

# 2. 불필요한 서비스 비활성화
echo "🚫 불필요한 서비스 비활성화"
systemctl disable --now avahi-daemon.service || true
systemctl disable --now cups.service || true
systemctl disable --now bluetooth.service || true

# 3. SSH 보안 설정
echo "🔑 SSH 보안 설정"

if [ -f /etc/ssh/sshd_config ]; then
  echo "✅ sshd_config 파일 발견 → 하드닝 적용합니다."
else
  echo "⚠️ sshd_config 파일이 없습니다. openssh-server를 설치합니다."
  apt update
  apt install -y openssh-server
fi

# (파일이 없었어도 설치되었으니 이제 하드닝 적용)
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd


# 4. 자동 보안 업데이트 설정
echo "🔄 자동 보안 업데이트 활성화"
apt install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades

# 5. 로그 감시 설정 (fail2ban)
echo "📜 Fail2Ban 설치 및 설정"
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Fail2Ban 설정 추가
cat <<EOF >> /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 5
EOF
systemctl restart fail2ban

# 6. 비밀번호 만료 정책 설정
echo "📅 비밀번호 만료 정책 적용"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs

# 7. 신규 사용자 기본 설정 강제 적용
echo "👤 신규 사용자 생성 시 만료정책 강제"
useradd -D -f 30

# 8. 비밀번호 복잡도 설정
echo "🔑 비밀번호 복잡도 정책 설정"
apt install -y libpam-pwquality
sed -i '/pam_pwquality.so/ d' /etc/pam.d/common-password
echo "password requisite pam_pwquality.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1" >> /etc/pam.d/common-password

# 9. 시스템 계정 로그인 제한
echo "🔒 로그인 제한이 필요한 시스템 계정 쉘 변경"
for user in $(awk -F: '($3 < 1000 && $1 != "root") {print $1}' /etc/passwd); do
  usermod -s /usr/sbin/nologin $user
done

# 10. 비밀번호 없는 사용자 잠금
echo "🚫 비밀번호 없는 계정 잠금"
awk -F: '($2==""){print $1}' /etc/shadow | while read user; do
  passwd -l $user
done

# 11. 관리자 계정 생성 (옵션)
echo "📛 sudo 전용 관리자 계정 생성 권장 (예시: admin)"
read -p "관리자 계정을 생성하시겠습니까? (y/n): " create_admin
if [ "$create_admin" == "y" ]; then
  read -p "생성할 계정 이름: " admin_user
  adduser $admin_user
  usermod -aG sudo $admin_user
  echo "✅ '$admin_user' 계정이 sudo 그룹에 추가되었습니다."
fi

# 12. 유휴 세션 자동 종료 설정
echo "⏲️ 유휴 세션 자동 종료 설정 (10분)"
echo "TMOUT=600" >> /etc/profile
echo "readonly TMOUT" >> /etc/profile
echo "export TMOUT" >> /etc/profile
echo "TMOUT=600" >> /etc/bash.bashrc
echo "readonly TMOUT" >> /etc/bash.bashrc
echo "export TMOUT" >> /etc/bash.bashrc

# 13. iptables 방화벽 설정
echo "🔥 iptables 방화벽 설정 중..."

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

apt install -y iptables-persistent
netfilter-persistent save
netfilter-persistent reload

echo "✅ iptables 규칙 저장 완료"

# 14. firewalld 설정 (설치되어 있을 경우만)
if command -v firewall-cmd &> /dev/null; then
  echo "🔥 firewalld 규칙 설정 중..."

  firewall-cmd --set-default-zone=public
  firewall-cmd --permanent --zone=public --add-port=22/tcp
  firewall-cmd --permanent --zone=public --add-port=80/tcp
  firewall-cmd --permanent --zone=public --add-port=443/tcp
  firewall-cmd --permanent --set-target=DROP
  firewall-cmd --reload

  echo "✅ firewalld 규칙 적용 완료"
else
  echo "⚡ firewalld가 설치되어 있지 않아서 firewalld 설정은 스킵합니다."
fi

# 15. 설치된 방화벽 도구 확인
echo "✅ 설치된 방화벽 도구 확인"
which ufw || echo "ufw 없음"
which iptables || echo "iptables 없음"
which firewall-cmd || echo "firewalld 없음"

# 16. 실행 중인 방화벽 서비스 상태 확인
echo "✅ 실행 중인 방화벽 서비스 확인"
systemctl status ufw || true
systemctl status netfilter-persistent || true
systemctl status firewalld || true

echo "🎉 Ubuntu 22.04 서버 보안 하드닝 완료!"
