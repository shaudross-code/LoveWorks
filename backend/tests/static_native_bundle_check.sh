#!/bin/bash
# Static checks for native (iOS/Android) web bundle freshness
cd /app/frontend
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
ko(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }
check_bundle(){
  NAME=$1; PUB=$2; CFG=$3
  echo "=== $NAME ==="
  [ -f "$PUB/index.html" ] && ok "$NAME index.html exists" || ko "$NAME index.html missing"
  grep -q "viewport-fit=cover" "$PUB/index.html" && ok "$NAME viewport-fit=cover" || ko "$NAME viewport-fit missing"
  REF=$(grep -o 'static/js/main\.[a-z0-9]*\.js' "$PUB/index.html" | head -1)
  echo "  referenced: $REF ; present: $(ls $PUB/static/js/main.*.js 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
  [ -n "$REF" ] && [ -f "$PUB/$REF" ] && ok "$NAME main js reference resolves" || ko "$NAME main js reference broken"
  JS="$PUB/$REF"
  for s in "My Sizes" "How to measure" "https://labor-admin-hub.emergent.host"; do
    grep -q "$s" "$JS" && ok "$NAME contains '$s'" || ko "$NAME missing '$s'"
  done
  if grep -rq "preview.emergentagent.com" "$PUB/static/js/"; then ko "$NAME contains preview.emergentagent.com"; else ok "$NAME no preview URL"; fi
  N=$(ls "$PUB/measure/"*.webp 2>/dev/null | wc -l); [ "$N" -eq 10 ] && ok "$NAME 10 webp ($N)" || ko "$NAME webp count $N"
  grep -q '"contentInset": "never"' "$CFG" && ok "$NAME contentInset never" || ko "$NAME contentInset not never"
  grep -q '"appId": "com.loveworks.app"' "$CFG" && ok "$NAME appId" || ko "$NAME appId wrong"
}
check_bundle iOS ios/App/App/public ios/App/App/capacitor.config.json
check_bundle Android android/app/src/main/assets/public android/app/src/main/assets/capacitor.config.json
echo "=== git check-ignore ==="
git check-ignore -v ios/App/App/public/index.html ios/App/App/capacitor.config.json android/app/src/main/assets/public/index.html android/app/src/main/assets/capacitor.config.json
RC=$?; [ $RC -eq 1 ] && ok "nothing ignored (rc=1)" || ko "check-ignore rc=$RC"
echo "TOTAL PASS=$PASS FAIL=$FAIL"
