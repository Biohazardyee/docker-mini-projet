#!/usr/bin/env bash
set -eux
ROLE="$1"
MY_IP="$2"

# Basic Docker install for Ubuntu
install_docker(){
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release gnupg2
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  usermod -aG docker vagrant || true
}

wait_for_file(){
  local file="$1"
  local retries=120
  while [ ! -f "$file" ] && [ $retries -gt 0 ]; do
    sleep 1
    retries=$((retries-1))
  done
  if [ $retries -le 0 ]; then
    echo "Timed out waiting for $file" >&2
    return 1
  fi
}

install_docker

# ensure /vagrant exists and is writable
mkdir -p /vagrant/images

if [ "$ROLE" = "manager" ]; then
  echo "Running manager provisioning on $MY_IP"

  # Initialize swarm
  docker swarm init --advertise-addr "$MY_IP" || true
  # save token and manager IP to shared folder for workers
  docker swarm join-token -q worker > /vagrant/join-token
  echo "$MY_IP" > /vagrant/manager-ip

  # Build images from shared project folder
  echo "Building images on manager..."
  docker build -t voting-app_vote:latest /vagrant/vote
  docker build -t voting-app_worker:latest /vagrant/worker
  docker build -t voting-app_result:latest /vagrant/result

  echo "Saving images to /vagrant/images"
  docker save voting-app_vote:latest -o /vagrant/images/voting-app_vote.tar
  docker save voting-app_worker:latest -o /vagrant/images/voting-app_worker.tar
  docker save voting-app_result:latest -o /vagrant/images/voting-app_result.tar

  # Wait a moment for workers to load images, then deploy the stack
  echo "Deploying stack from /vagrant/stack.yml"
  # ensure stack.yml exists in /vagrant
  if [ ! -f /vagrant/stack.yml ]; then
    echo "stack.yml not found in /vagrant — please place stack.yml at project root before vagrant up" >&2
  else
    # If a .env file is present in the project root, source it so environment
    # variables (POSTGRES_USER/POSTGRES_PASSWORD/POSTGRES_DB/OPTION_*) are
    # exported into the shell and available during `docker stack deploy`.
    if [ -f /vagrant/.env ]; then
      echo "Loading /vagrant/.env for stack deploy (handles CRLF and comments)"
      # Read .env line-by-line, ignore comments/empty lines, strip CRLF,
      # and export KEY=VALUE pairs into the environment.
      while IFS= read -r line || [ -n "$line" ]; do
        # strip Windows CR if present
        line=$(printf '%s' "$line" | sed 's/\r$//')
        # skip empty or comment lines
        case "$line" in
          ''|\#*) continue;;
        esac
        # split on first '=' into key and value
        IFS='=' read -r key val <<< "$line"
        # remove surrounding quotes from value if present
        val="${val%\"}"
        val="${val#\"}"
        export "${key}=${val}"
      done < /vagrant/.env
    fi

    docker stack deploy -c /vagrant/stack.yml voting-app || true
  fi

else
  echo "Running worker provisioning on $ROLE ($MY_IP)"
  # wait for join token and manager ip
  wait_for_file /vagrant/join-token
  wait_for_file /vagrant/manager-ip

  TOKEN=$(cat /vagrant/join-token)
  MGR_IP=$(cat /vagrant/manager-ip)

  # Join swarm
  docker swarm join --token "$TOKEN" "$MGR_IP:2377" || true

  # Wait for images to be saved by manager, then load
  wait_for_file /vagrant/images/voting-app_vote.tar
  wait_for_file /vagrant/images/voting-app_worker.tar
  wait_for_file /vagrant/images/voting-app_result.tar

  docker load -i /vagrant/images/voting-app_vote.tar || true
  docker load -i /vagrant/images/voting-app_worker.tar || true
  docker load -i /vagrant/images/voting-app_result.tar || true
fi

echo "Provisioning for $ROLE complete."