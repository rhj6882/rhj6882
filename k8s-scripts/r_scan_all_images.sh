#!/bin/bash
# 결과 저장할 파일 이름 만들기 (현재 날짜시간 기준)
mkdir -p ./scan_logs
output_file="./scan_logs/trivy_result_$(date +%Y%m%d_%H%M%S).txt"

# 모든 도커 이미지 목록 가져오기
images=$(docker images --format '{{.Repository}}:{{.Tag}}')

# 결과를 파일에 기록 시작
{
  echo "[INFO] 스캔 시작 시간: $(date)"
  
  for img in $images; do
    if [[ -n "$img" ]]; then
      echo "=============================="
      echo "▶️ 스캔 시작: $img"
      echo "=============================="
      
      trivy image --severity HIGH,CRITICAL --ignore-unfixed "$img"
      
      echo ""
    fi
  done
  
  echo "[INFO] 전체 스캔 완료 시간: $(date)"
} >> "$output_file" 2>&1

echo "[INFO] 스캔 결과 저장 완료: $output_file"
