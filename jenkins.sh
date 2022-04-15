#!/bin/bash

kubectl create namespace admin

my_git=`git config --list | grep user.name | cut -d "=" -f2`

argocd app create jenkins \
--repo https://github.com/$my_git/emarket_PaC.git \
--path jenkins \
--dest-server https://kubernetes.default.svc \
--dest-namespace admin

argocd app sync jenkins


echo "apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-agent
  namespace: admin
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-agent
  namespace: admin
rules:
- apiGroups:
  - \"\"
  resources:
  - pods
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - \"\"
  resources:
  - pods/exec
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - \"\"
  resources:
  - pods/log
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - \"\"
  resources:
  - events
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-agent
  namespace: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-agent
subjects:
- kind: ServiceAccount
  name: jenkins-agent" > jenkins-agent-sa.yaml

kubectl apply -f jenkins-agent-sa.yaml

echo
echo 'Jenkins is being installed. Please wait...'
sleep 15s

echo
echo '>>>>>>>>>>>>>>>>> SAVE the below infomation separately! <<<<<<<<<<<<<<<<<<<'
echo -n '>>> Jenkins URL : '
kubectl get svc -n admin | awk '{print $4":8080"}' | grep aws
echo
echo '>>> Jenkins User : admin '
echo
echo -n '>>> Jenkins Password : ' &&  kubectl -n admin get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d; echo
echo
echo '>>> Jenkins Secret Token : '
kubectl describe secret $jenkins_token -n admin | grep token:
echo


rm jenkins-agent-sa.yaml

