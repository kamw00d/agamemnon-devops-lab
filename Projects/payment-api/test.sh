#!/usr/bin/env bash

PORT=18080
echo "Uruchamiam test payment-api na porcie $PORT"

PORT=$PORT python3 app.py > test-app.log 2>&1 &
APP_PID=$!

echo "Aplikacja uruchomiona. PID $APP_PID"

cleanup() {
	echo "Sprzatam po tescie..."
	kill "$APP_PID" 2>/dev/null || true

}

trap cleanup EXIT

sleep 1

RESPONSE=$(curl --silent --max-time 3 "http://127.0.0.1:$PORT/health")
CURL_EXIT=$?

if [[ $CURL_EXIT -ne 0 ]]; then
	echo "TEST FAILED - nie udalo sie polaczyc aplikacja"
	exit 1

fi

if [[ "$RESPONSE" == "payment-api: healthy" ]]; then
	echo "TEST PASSED - aplikacja jest zdrowa"
	exit 0

else
	echo "TEST FAILED - aplikacja odpowiedziala inaczej niz oczekiwano"
	echo "Odpowiedz: $RESPONSE"
	exit 1

fi
