#!/bin/bash

# 1. /etc/apt/sources.list.d 존재 여부 확인 후 생성
if [ ! -d /etc/apt/sources.list.d ]; then
  sudo mkdir -p /etc/apt/sources.list.d
fi

# 2. 필요한 패키지 설치
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg lsb-release curl

# 3. Trivy 저장소 키 등록 (올바른 방법)
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg

# 4. Trivy 저장소 등록 (signed-by 추가)
echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

# 5. 패키지 목록 갱신
sudo apt-get update

# 6. Trivy 설치
sudo apt-get install -y trivy

# 7. Trivy 버전 확인
trivy --version

echo "trivy 설치 끝 / 실행하려면 trivy image [image] 입력"
