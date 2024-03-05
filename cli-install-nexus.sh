#!/bin/bash
NEXUS_NAMESPACE=cicd-devtools

echo "Aplicando o template cli-install-nexus.yaml..."

oc apply -f cli-install-nexus.yaml

while true; do
    if oc get namespace $NEXUS_NAMESPACE &> /dev/null; then
        echo "Namespace $NEXUS_NAMESPACE criado com sucesso"
        break
    else
        echo "Aguardando..."
        sleep 5
    fi
done

oc project cicd-devtools

echo "Criando pods..."

oc wait --for=condition=Ready pod -l app=nexus3 --timeout=300s

oc get pods | grep Running

NEXUS_POD=$(oc get pods --selector app=nexus3 -n $NEXUS_NAMESPACE | { read line1 ; read line2 ; echo "$line2" ; } | awk '{print $1;}')

NEXUS_PASSWORD=$(oc exec $NEXUS_POD cat /nexus-data/admin.password)

oc get routes | grep nexus3

NEXUS_ROUTE=http://$(oc get route nexus3 --template='{{ .spec.host }}')

#echo "senha admin: $NEXUS_PASSWORD"

curl -v -X PUT -u admin:$NEXUS_PASSWORD -H "accept: application/json" -H "Content-Type: text/plain" "$NEXUS_ROUTE/service/rest/v1/security/users/admin/change-password" -d 'admin123'

echo "Host: $NEXUS_ROUTE"
echo "Usuário: admin"
echo "Senha: admin123"

#chmod +x setup_nexus3.sh

#./setup_nexus3.sh admin admin123 $NEXUS_ROUTE

#oc annotate route nexus-registry com.microservices.apigateway.security.service=nexus-registry