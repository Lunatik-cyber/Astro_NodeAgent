# 🚀 Node Agent — Умный агент для управления проксированием на Linux 🚀

![Node Agent Banner](https://em-content.zobj.net/source/microsoft-teams/363/rocket_1f680.png)

---

## 🦾 Что такое Node Agent?

**Node Agent** — это легкий и мощный агент для Linux/Ubuntu серверов, который:

- 🚦 Запускает собственное FastAPI для управления правилами проксирования  
- 🌐 Работает с GOST для гибкого TCP/UDP-перенаправления  
- 🫀 Поддерживает heartbeat: держит связь с мастер-нодой (для мониторинга)  
- ☁️ Позволяет централизованно деплоить, изменять и контролировать правила проксирования прямо из вашей управляющей панели  

---

## ⚡ Быстрый старт

> 🐧 **Требования:** Ubuntu 18.04/20.04/22.04+, root-доступ

1. **Клонируйте репозиторий и перейдите в папку:**
   ```bash
   git clone https://github.com/Lunatik-cyber/Astro_NodeAgent.git
   cd Astro_NodeAgent
   ```

2. **Запустите деплой-скрипт (он сам установит все нужные зависимости):**
   ```bash
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```

   Можно задать параметры:
   ```bash
   NODE_UUID=my-uuid-123 MASTER_URL=http://1.2.3.4/api/node/heartbeat sudo ./deploy.sh
   ```

3. **Готово! Агент будет доступен по адресу:**
   ```
   http://<ip-сервера>:8000/
   ```

---

## 🛠️ Пример супер-быстрой настройки через deploy.sh

```bash
git clone https://github.com/Lunatik-cyber/Astro_NodeAgent.git
cd Astro_NodeAgent
chmod +x deploy.sh
sudo NODE_UUID=$(cat /proc/sys/kernel/random/uuid) MASTER_URL="http://master-node/api/node/heartbeat" ./deploy.sh
```

---

## ⚙️ Переменные окружения

| Переменная   | Описание                                           | Пример                                        |
|--------------|----------------------------------------------------|-----------------------------------------------|
| `NODE_UUID`  | Уникальный идентификатор вашей ноды                | `c0ffee-babe-42-1337`                         |
| `MASTER_URL` | URL мастер-ноды для heartbeat и деплоев            | `http://master-node/api/node/heartbeat`       |

---

## 📡 API-эндпоинты агента

| Endpoint                | Метод | Описание                                    |
|-------------------------|-------|---------------------------------------------|
| `/ping`                 | GET   | Проверка доступности агента                 |
| `/forwarding/list`      | GET   | Список текущих правил проксирования         |
| `/forwarding/status`    | GET   | Статус форвардинга                          |
| `/forwarding/add`       | POST  | Добавить правило форвардинга                |
| `/forwarding/remove`    | POST  | Удалить правило                             |
| `/forwarding/edit`      | POST  | Изменить правило                            |
| `/forwarding/deploy`    | POST  | Перезаписать все правила списком            |
| `/run_cmd`              | POST  | Выполнить shell-команду на сервере ⚠️        |

---

## 🔥 Примеры использования API

### ➕ Добавить правило

```bash
curl -X POST http://localhost:8000/forwarding/add \
  -H "Content-Type: application/json" \
  -d '{"ip": "1.2.3.4", "port": 8080, "redirect_port": 80, "protocol": "tcp"}'
```

### 🗑️ Удалить правило

```bash
curl -X POST http://localhost:8000/forwarding/remove \
  -H "Content-Type: application/json" \
  -d '{"ip": "1.2.3.4", "port": 8080, "redirect_port": 80, "protocol": "tcp"}'
```

### ♻️ Перезаписать все правила

```bash
curl -X POST http://localhost:8000/forwarding/deploy \
  -H "Content-Type: application/json" \
  -d '[
    {"ip": "1.2.3.4", "port": 8080, "redirect_port": 80, "protocol": "tcp"},
    {"ip": "5.6.7.8", "port": 9090, "redirect_port": 443, "protocol": "udp"}
  ]'
```

### 🖥️ Получить статус

```bash
curl http://localhost:8000/forwarding/status
```

---

## 🧬 Пример структуры правила (JSON)

```json
{
  "ip": "1.2.3.4",
  "port": 8080,
  "redirect_port": 80,
  "protocol": "tcp"
}
```
- **port** и **redirect_port** — только от 1 до 65535  
- **protocol** — только "tcp" или "udp"  
- Можно создавать одновременно tcp+udp правила для одного и того же порта  

---

## 🫀 Heartbeat

Агент автоматически отправляет heartbeat раз в 30 секунд на MASTER_URL:

```json
{
  "node_uuid": "your-node-uuid"
}
```
> Для мониторинга активности и управления с центра.

---

## 🛡️ Безопасность

- Рекомендуем использовать firewall/ACL для ограничения доступа к API  
- Не открывайте порт 8000 наружу без необходимости!  
- Агент требует root-доступ только для управления сетевыми интерфейсами и портами  

---

## 🤖 Особенности и лайфхаки

- 🧩 Можно добавлять и tcp, и udp для одного и того же порта!
- 🦺 Встроена строгая валидация портов и протоколов
- 🏃‍♂️ GOST всегда запускается в фоне (никаких systemd/systemctl)
- 🕵️‍♂️ Можно выполнять ad-hoc shell-команды через `/run_cmd` (используйте осторожно!)

---

## 📜 Лицензия

MIT

---

> 💡 **Node Agent — ваш швейцарский нож для управления проксированием, мониторингом и автоматизацией на Linux!**
