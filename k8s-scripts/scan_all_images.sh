#!/bin/bash

# 모든 도커 이미지 목록 가져오기
images=$(docker images --format '{{.Repository}}:{{.Tag}}')

# 각 이미지에 대해 Trivy 스캔
for img in $images; do
  if [[ -n "$img" ]]; then
    echo "=============================="
    echo "▶️ 스캔 시작: $img"
    echo "=============================="
    
    trivy image --severity HIGH,CRITICAL --ignore-unfixed "$img"
    
    echo ""  # 줄바꿈
  fi
done

echo "[INFO] 전체 스캔 완료: $(date)"
