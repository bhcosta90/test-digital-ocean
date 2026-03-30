# 🚀 Setup Completo: Docker + Caddy + Deploy com GitHub Actions

Este guia documenta **tudo que você precisa** para subir um servidor com:

* Docker
* Caddy (proxy reverso + HTTPS automático)
* Deploy automático via GitHub Actions
* Suporte a múltiplos ambientes (main, develop, sandbox)

---

# 📦 1. Instalar Docker

## 🔹 Atualizar sistema

```bash
sudo apt update && sudo apt upgrade -y
```

## 🔹 Instalar dependências

```bash
sudo apt install -y ca-certificates curl gnupg
```

## 🔹 Adicionar chave do Docker

```bash
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

## 🔹 Adicionar repositório

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## 🔹 Instalar Docker

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 🔹 Ativar Docker

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

## 🔹 (Opcional) Rodar sem sudo

```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

# 🌐 2. Criar Network Docker

```bash
docker swarm init --advertise-addr 
docker network inspect web >/dev/null 2>&1 || docker network create --driver overlay web
```

---

# 🌍 3. Configurar DNS

No seu provedor (Cloudflare, Registro.br, etc):

```text
A  bhcosta90.dev.br         → IP_DO_SERVIDOR
A  develop.bhcosta90.dev.br → IP_DO_SERVIDOR
A  sandbox.bhcosta90.dev.br → IP_DO_SERVIDOR
```

Ou wildcard:

```text
*.bhcosta90.dev.br → IP
```

---

# ⚙️ 4. Criar Caddyfile

Crie um arquivo:

```bash
vi Caddyfile
```

## 🔹 Exemplo com múltiplos ambientes

```caddyfile
{
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

bhcosta90.dev.br {
    reverse_proxy project-test-main:80
}

develop.bhcosta90.dev.br {
    reverse_proxy project-test-develop:80
}

sandbox.bhcosta90.dev.br {
    reverse_proxy project-test-sandbox:80
}
```

---

# 🚀 5. Subir Caddy (Caddyfile)

vi CaddyfilePreview

```caddyfile
{
    auto_https off
}

bhcosta90.dev.br {
    reverse_proxy project-test-main:80
}

develop.bhcosta90.dev.br {
    reverse_proxy project-test-develop:80
}

sandbox.bhcosta90.dev.br {
    reverse_proxy project-test-sandbox:80
}
```

```bash
docker service create \
  --name caddy \
  --network web \
  -p target=80,published=80,mode=host \
  -p target=443,published=443,mode=host \
  --constraint 'node.role==manager' \
  --mount type=bind,src=$(pwd)/Caddyfile,dst=/etc/caddy/Caddyfile \
  --mount type=volume,src=caddy_data,dst=/data \
  --mount type=volume,src=caddy_config,dst=/config \
  --restart-condition any \
  caddy:2
```

# 🚀 5.1. Subir Caddy Preview  (CaddyfilePreview)

```bash
docker service create \
  --name caddy-preview \
  --network web \
  --publish published=8080,target=8080 \
  --constraint 'node.role==manager' \
  --mount type=bind,src=$(pwd)/CaddyfilePreview,dst=/etc/caddy/Caddyfile \
  caddy:2
```

---

# 🔐 6. HTTPS automático

O Caddy automaticamente:

* gera certificado (Let's Encrypt)
* ativa HTTPS
* redireciona HTTP → HTTPS

👉 Apenas garanta:

* porta 80 aberta
* porta 443 aberta
* DNS apontando corretamente

---

# 📁 7. Arquivos .env no servidor

Crie os arquivos:

```bash
mkdir -p ~/${NAME_REPOSITORY}/
vi ~/${NAME_REPOSITORY}/.env-main
vi ~/${NAME_REPOSITORY}/.env-develop
vi ~/${NAME_REPOSITORY}/.env-sandbox
```

---

# 🧠 Exemplo de .env

```env
APP_ENV=production
APP_DEBUG=false

QUEUE_CONNECTION=redis

REDIS_PREFIX=project-test-main_
CACHE_PREFIX=project-test-main_cache
SESSION_PREFIX=project-test-main_session
```

---

# 🤖 8. GitHub Actions (Deploy automático)

O pipeline:

* builda imagem
* envia via SSH
* sobe containers por branch
* usa `.env` com fallback

### Estrutura gerada:

```text
Containers:
project-test-main
project-test-develop
project-test-sandbox

Workers:
project-test-main-worker
project-test-develop-worker
project-test-sandbox-worker
```

---

# 🐳 9. Containers criados

### App

```bash
docker run -d \
  --name project-test-main \
  --network web \
  -v ~/.env-project-test-main:/var/www/html/.env \
  project-test
```

### Worker

```bash
docker run -d \
  --name project-test-main-worker \
  --network web \
  --restart unless-stopped \
  -v ~/.env-project-test-main:/var/www/html/.env \
  project-test worker
```
---

# 🔄 10. Atualizar Caddy após mudanças

```bash
docker restart caddy
```

---

# 🧪 11. Testes

### Testar HTTP

```bash
curl http://bhcosta90.dev.br
```

### Testar HTTPS

```bash
curl -v https://bhcosta90.dev.br
```

---

# 🧠 Dicas importantes

### ✔️ Sempre expor portas no Caddy

```bash
-p 80:80 -p 443:443
```

### ✔️ Containers devem estar na mesma network

```bash
--network web
```

### ✔️ Nome do container = usado no Caddy

```caddyfile
reverse_proxy project-test-main:80
```

---

# ⚠️ Problemas comuns

### ❌ HTTPS não funciona

* porta 443 fechada

### ❌ domínio não responde

* DNS errado

### ❌ container não encontrado

* nome errado no Caddyfile

### ❌ deploy quebra

* variável não definida no script

---

# 🎯 Resultado final

Você terá:

✔️ Deploy automático por branch
✔️ Ambientes isolados
✔️ HTTPS automático
✔️ Filas isoladas (Redis prefix)
✔️ Estrutura escalável

---

# 🚀 Próximos passos (opcional)

* Horizon dashboard por ambiente
* banco separado por branch
* rollback automático
* deploy sem downtime

---

**Pronto. Agora você pode replicar esse setup em qualquer servidor 🚀**
