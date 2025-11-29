# Start server

open http://localhost:8080

cd test-camera-firebase
./start-test.sh

# Or manually

python3 -m http.server 8080

# Then open

open http://localhost:8080

# Press Ctrl+C in the terminal

# Or kill it manually:

lsof -ti:8080 | xargs kill -9
