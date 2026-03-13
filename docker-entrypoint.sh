#!/bin/sh
N8N_DATA="/home/node/.n8n"
WORKFLOW_FILE="/workflows/recherche_appart_rennes.json"
FLAG_FILE="${N8N_DATA}/.workflow_imported"

# Si le workflow a déjà été importé (redémarrage), lancer n8n directement (évite double processus)
if [ -f "$FLAG_FILE" ]; then
  echo "[n8n] Redémarrage (workflow déjà importé). Démarrage de n8n..."
  exec n8n start
fi

# Premier démarrage : n8n en arrière-plan pour attendre le compte owner puis importer
n8n start &
N8N_PID=$!

echo "[n8n] Démarrage de n8n (migrations en cours, patientez 1 à 2 min)..."
i=0
while [ $i -lt 90 ]; do
  if wget -q -O /dev/null http://127.0.0.1:5678/healthz/readiness 2>/dev/null; then
    echo "[n8n] n8n est prêt. Créez votre compte sur http://localhost:5678 (le workflow sera importé dès que c'est fait)."
    break
  fi
  i=$((i + 1))
  sleep 2
done

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "[n8n] Fichier workflow absent. Arrêt du processus en arrière-plan puis démarrage normal."
  kill -TERM $N8N_PID 2>/dev/null || true
  wait $N8N_PID 2>/dev/null || true
  sleep 2
  exec n8n start
fi

echo "[n8n] En attente de la création de votre compte..."
attempt=1
max_attempts=60
owner_ready=0
while [ $attempt -le $max_attempts ]; do
  sleep 5
  out=$(wget --max-redirect=0 -S -O /dev/null http://127.0.0.1:5678/ 2>&1) || true
  if echo "$out" | grep -q "Location:.*signup"; then
    :
  else
    owner_ready=1
    break
  fi
  attempt=$((attempt + 1))
done

if [ $owner_ready -eq 1 ]; then
  echo "[n8n] Compte détecté. Arrêt temporaire de n8n pour importer le workflow..."
  kill -TERM $N8N_PID 2>/dev/null || true
  wait $N8N_PID 2>/dev/null || true
  sleep 2
  echo "[n8n] Import du workflow depuis $WORKFLOW_FILE..."
  if n8n import:workflow --input="$WORKFLOW_FILE"; then
    touch "$FLAG_FILE"
    echo "[n8n] Workflow importé. Redémarrage de n8n."
  else
    echo "[n8n] Échec import. Relancez: docker exec n8n-location n8n import:workflow --input=/workflows/recherche_appart_rennes.json"
  fi
else
  echo "[n8n] Timeout (5 min). Créez votre compte puis lancez: docker exec n8n-location n8n import:workflow --input=/workflows/recherche_appart_rennes.json"
  kill -TERM $N8N_PID 2>/dev/null || true
  wait $N8N_PID 2>/dev/null || true
  sleep 2
fi

exec n8n start
