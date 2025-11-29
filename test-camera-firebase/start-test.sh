#!/bin/bash

# Quick start script for Firebase Camera Test

# Function to find available port
find_available_port() {
    for port in 8080 8081 8082 8083 3000 3001; do
        if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo $port
            return
        fi
    done
    echo 8888
}

PORT=$(find_available_port)

echo "🚀 Starting Firebase Camera Test Server..."
echo ""
echo "📍 Server will start at: http://localhost:$PORT"
echo "📷 Opening in browser..."
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Open browser after a short delay
(sleep 2 && open http://localhost:$PORT 2>/dev/null) &

# Start Python HTTP server
python3 -m http.server $PORT

# Alternatively, if you have Node.js:
# npx http-server -p 8080 -o
