#!/bin/sh
set -eu

ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-development}"
IMAGE="${IMAGE:-buildathon-backend:local}"

if [ -z "${SSH_HOST:-}" ] || [ -z "${SSH_USER:-}" ] || [ -z "${SSH_KEY:-}" ]; then
  echo "No server is configured for the ${ENVIRONMENT_NAME} environment yet."
  echo "Add these GitHub environment secrets: SSH_HOST, SSH_USER, SSH_KEY."
  echo "Optional secrets: DATABASE_URL, PORT. Optional variable: APP_URL."
  exit 0
fi

mkdir -p "${HOME}/.ssh"
printf '%s\n' "${SSH_KEY}" > "${HOME}/.ssh/id_deploy"
chmod 600 "${HOME}/.ssh/id_deploy"
ssh-keyscan -H "${SSH_HOST}" >> "${HOME}/.ssh/known_hosts"

PORT_VALUE="${PORT:-3000}"
REMOTE="${SSH_USER}@${SSH_HOST}"
SSH="ssh -i ${HOME}/.ssh/id_deploy -o StrictHostKeyChecking=yes"

docker save "${IMAGE}" | ${SSH} "${REMOTE}" "docker load"

${SSH} "${REMOTE}" \
  ENVIRONMENT_NAME="${ENVIRONMENT_NAME}" \
  IMAGE="${IMAGE}" \
  PORT_VALUE="${PORT_VALUE}" \
  DATABASE_URL="${DATABASE_URL:-}" \
  sh <<'EOF'
set -eu
docker rm -f "buildathon-backend-${ENVIRONMENT_NAME}" >/dev/null 2>&1 || true
docker run -d \
  --name "buildathon-backend-${ENVIRONMENT_NAME}" \
  --restart unless-stopped \
  -p "${PORT_VALUE}:3000" \
  -e "NODE_ENV=${ENVIRONMENT_NAME}" \
  -e "PORT=3000" \
  -e "DATABASE_URL=${DATABASE_URL}" \
  "${IMAGE}"
docker image prune -a -f || true
EOF

echo "Deployed ${ENVIRONMENT_NAME} to ${SSH_HOST}:${PORT_VALUE}"
