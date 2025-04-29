#!/bin/bash

STATE_DIR="./cve_current_state"
mkdir -p "$STATE_DIR"

function scan_image() {
  local image="$1"
  local clean_image=$(echo "$image" | tr '/:@' '_')
  local state_file="$STATE_DIR/${clean_image}.txt"

  echo "▶️ [$image] 스캔 시작..."

  # 현재 스캔 결과
  trivy image --severity HIGH,CRITICAL --ignore-unfixed --format json "$image" > "./scan_tmp_${clean_image}.json" 2>/dev/null

  if [ ! -s "./scan_tmp_${clean_image}.json" ]; then
    echo "⚠️ [$image] 스캔 결과 없음. 스킵."
    rm -f "./scan_tmp_${clean_image}.json"
    return
  fi

  # 현재 HIGH, CRITICAL CVE 추출
  jq -r '.Results[].Vulnerabilities[] | select(.Severity == "HIGH" or .Severity == "CRITICAL") | .VulnerabilityID' "./scan_tmp_${clean_image}.json" | sort > "./cve_tmp.txt"
  rm "./scan_tmp_${clean_image}.json"

  # 처음 실행이면 상태 파일 초기화
  if [ ! -f "$state_file" ]; then
    cp "./cve_tmp.txt" "$state_file"
    echo "📢 [$image] 현재 HIGH/CRITICAL 취약점:"
    cat "$state_file"
    echo ""
    return
  fi

  # 기존 상태 파일과 비교
  # 추가된 CVE
  added=$(comm -13 "$state_file" "./cve_tmp.txt")

  # 유지된 CVE
  still_exists=$(comm -12 "$state_file" "./cve_tmp.txt")

  # 갱신된 상태를 다시 저장
  cat "./cve_tmp.txt" > "$state_file"

  # 출력
  if [[ -n "$still_exists" || -n "$added" ]]; then
    echo "📢 [$image] 현재 HIGH/CRITICAL 취약점 목록 (유지 + 추가):"
    echo "$still_exists"
    echo "$added"
    echo ""
  else
    echo "✅ [$image] 현재 HIGH/CRITICAL 취약점 없음."
    echo ""
  fi

  rm -f "./cve_tmp.txt"
}

# 메인 루프
images=$(docker images --format '{{.Repository}}:{{.Tag}}')

for img in $images; do
  if [[ -n "$img" ]]; then
    scan_image "$img"
  fi
done

echo "[INFO] 전체 스캔 완료: $(date)"
