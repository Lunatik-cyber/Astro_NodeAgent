from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
from typing import List, Optional
from app.gost import (
    deploy_forwarding, add_forwarding_port, remove_forwarding_port,
    edit_forwarding_port, list_forwarding_ports, forwarding_status,
    run_local_cmd
)

router = APIRouter()

@router.get("/ping")
async def ping():
    return {"status": "ok"}

class ForwardingRule(BaseModel):
    ip: str
    port: int
    redirect_port: int
    protocol: str

@router.post("/forwarding/deploy")
async def forwarding_deploy(rules: List[ForwardingRule]):
    try:
        result = await deploy_forwarding(rules)
        return {"status": "success", "message": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/forwarding/status")
async def get_status():
    return await forwarding_status()

@router.get("/forwarding/list")
async def get_list():
    return {"status": "success", "forwarding_ports": await list_forwarding_ports()}

@router.post("/forwarding/add")
async def add_port(rule: ForwardingRule):
    try:
        await add_forwarding_port(rule)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/forwarding/remove")
async def remove_port(rule: ForwardingRule):
    try:
        await remove_forwarding_port(rule)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/forwarding/edit")
async def edit_port(old_rule: ForwardingRule = Body(..., embed=True), new_rule: ForwardingRule = Body(..., embed=True)):
    try:
        await edit_forwarding_port(old_rule, new_rule)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

class CommandRequest(BaseModel):
    command: str

@router.post("/run_cmd")
async def run_cmd(req: CommandRequest):
    return await run_local_cmd(req.command)