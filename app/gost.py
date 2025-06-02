import asyncio
from typing import List, Optional
from pydantic import BaseModel, Field, validator
from enum import Enum

GOST_PATH = "/usr/local/bin/gost"
GOST_PROCESS: Optional[asyncio.subprocess.Process] = None
FORWARDING_RULES: List["ForwardingRule"] = []

class Protocol(str, Enum):
    tcp = "tcp"
    udp = "udp"

class ForwardingRule(BaseModel):
    ip: str
    port: int = Field(..., ge=1, le=65535)
    redirect_port: int = Field(..., ge=1, le=65535)
    protocol: Protocol

    @validator("ip")
    def valid_ip(cls, v):
        # Можно добавить строгую проверку IP, например через ipaddress
        # Для простоты оставлено базовое условие:
        if not isinstance(v, str) or not v:
            raise ValueError("IP must be a non-empty string")
        return v

def rule_key(rule: ForwardingRule):
    return (rule.ip, rule.port, rule.protocol)

def build_gost_args(rules: List[ForwardingRule]) -> List[str]:
    args = []
    for r in rules:
        args.append(f"-L={r.protocol}://:{r.port}/{r.ip}:{r.redirect_port}")
    return args

async def stop_gost():
    global GOST_PROCESS
    if GOST_PROCESS and GOST_PROCESS.returncode is None:
        GOST_PROCESS.terminate()
        try:
            await asyncio.wait_for(GOST_PROCESS.wait(), timeout=5)
        except asyncio.TimeoutError:
            GOST_PROCESS.kill()
            await GOST_PROCESS.wait()
    GOST_PROCESS = None

async def start_gost(rules: List[ForwardingRule]):
    await stop_gost()
    args = build_gost_args(rules)
    if not args:
        return
    global GOST_PROCESS
    GOST_PROCESS = await asyncio.create_subprocess_exec(
        GOST_PATH, *args,
        stdout=asyncio.subprocess.DEVNULL,
        stderr=asyncio.subprocess.DEVNULL
    )

async def deploy_forwarding(rules: List[ForwardingRule]):
    global FORWARDING_RULES
    # Удаляем дубликаты по ключу (ip, port, protocol)
    seen = set()
    deduped = []
    for r in rules:
        key = rule_key(r)
        if key not in seen:
            deduped.append(r)
            seen.add(key)
    FORWARDING_RULES = deduped
    await start_gost(FORWARDING_RULES)
    return "Деплой и запуск gost завершены"

async def add_forwarding_port(rule: ForwardingRule):
    # Разрешаем только если такой же ip+port+protocol отсутствует
    if any(rule_key(r) == rule_key(rule) for r in FORWARDING_RULES):
        raise Exception("Такое правило уже есть")
    FORWARDING_RULES.append(rule)
    await start_gost(FORWARDING_RULES)

async def remove_forwarding_port(rule: ForwardingRule):
    global FORWARDING_RULES
    updated = [r for r in FORWARDING_RULES if rule_key(r) != rule_key(rule)]
    if len(updated) == len(FORWARDING_RULES):
        raise Exception("Такое правило не найдено")
    FORWARDING_RULES = updated
    await start_gost(FORWARDING_RULES)

async def edit_forwarding_port(old_rule: ForwardingRule, new_rule: ForwardingRule):
    # Проверка: если новое правило уже есть (и оно не совпадает со старым), ошибка
    if rule_key(new_rule) != rule_key(old_rule) and any(rule_key(r) == rule_key(new_rule) for r in FORWARDING_RULES):
        raise Exception("Новое правило дублирует уже существующее")
    await remove_forwarding_port(old_rule)
    await add_forwarding_port(new_rule)

async def list_forwarding_ports():
    return [r.dict() for r in FORWARDING_RULES]

async def forwarding_status():
    return {
        "enabled": len(FORWARDING_RULES) > 0,
        "ports": [r.dict() for r in FORWARDING_RULES]
    }

async def run_local_cmd(command: str):
    try:
        proc = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        out, err = await proc.communicate()
        return {
            "status": "success",
            "output": out.decode().strip(),
            "error": err.decode().strip() or None
        }
    except Exception as e:
        return {
            "status": "error",
            "output": "",
            "error": str(e)
        }