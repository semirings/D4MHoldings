# D4M Holdings

Uber project that contains the modules that support a D4M microservice.

## Start/Stop et.al.

### (one-time or after you change conf)
sudo supervisorctl reread
sudo supervisorctl update

### start / stop / restart / status
sudo supervisorctl start d4mService
sudo supervisorctl stop d4mService
sudo supervisorctl restart d4mService
sudo supervisorctl status d4mService

### live logs
sudo supervisorctl tail -f d4mService

## Dev mode (run without Supervisor)
cd /opt/d4m
CONFIG_PATH=/opt/d4m/config.toml PORT=5101 \
  julia --project=/opt/d4m --startup-file=no /opt/d4m/main.jl

## If you need to force-stop a stuck process

### try graceful first
pkill -TERM -f 'julia --project=/opt/d4m'

### last resort
pkill -KILL -f 'julia --project=/opt/d4m'

## Verify it’s listening (optional)

lsof -iTCP:5101 -sTCP:LISTEN