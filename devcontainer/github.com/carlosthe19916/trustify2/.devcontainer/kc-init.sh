#!/bin/sh -l
KEYCLOAK_HOME="/opt/keycloak"
REALM="trustify2"

while ! $KEYCLOAK_HOME/bin/kcadm.sh config credentials --server ${KEYCLOAK_SERVER_URL} --realm master --user ${KEYCLOAK_ADMIN} --password ${KEYCLOAK_ADMIN_PASSWORD} &> /dev/null; do
  echo "Waiting for ${KEYCLOAK_SERVER_URL} to start up..."
  sleep 3
done

# Create realm
$KEYCLOAK_HOME/bin/kcadm.sh create realms -s realm="${REALM}" -s enabled=true -o

# Create clients
$KEYCLOAK_HOME/bin/kcadm.sh create clients -r "${REALM}"  -f - << EOF
  {
    "clientId": "trustify2-api",
    "secret": "secret"
  }
EOF

$KEYCLOAK_HOME/bin/kcadm.sh create clients -r "${REALM}"  -f - << EOF
  {
    "clientId": "trustify2-ui",
    "publicClient": true,
    "redirectUris": ["*"],
    "webOrigins": ["*"]
  }
EOF

# Create user
$KEYCLOAK_HOME/bin/kcadm.sh create users -r="${REALM}" -s username=admin -s enabled=true
$KEYCLOAK_HOME/bin/kcadm.sh set-password -r="${REALM}" --username admin --new-password admin
