from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

# Базовая модель информации о ноде
class NodeInfo(BaseModel):
    node_id: str
    node_ip: str
    node_region: str
    node_type: str
    node_status: str
    last_activity: datetime
    created_at: datetime

# Модель порта для форвардинга
class ForwardingPort(BaseModel):
    ip: Optional[str]
    port: int
    protocol: str

# Запрос на добавление/редактирование порта
class ForwardingAddRequest(BaseModel):
    ip: str
    port: int
    protocol: str

class ForwardingRemoveRequest(BaseModel):
    port: int
    protocol: str

class ForwardingEditRequest(BaseModel):
    old_ip: str
    old_port: int
    old_protocol: str
    new_ip: str
    new_port: int
    new_protocol: str

# Ответы
class ForwardingStatus(BaseModel):
    enabled: bool
    ports: List[ForwardingPort]

class RunCommandRequest(BaseModel):
    command: str