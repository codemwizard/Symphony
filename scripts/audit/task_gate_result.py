import sys
import json
from dataclasses import dataclass, asdict
from typing import Optional, List

@dataclass
class GateResult:
    status: str            # 'PASS', 'FAIL', 'BLOCKED'
    failure_class: str     # 'NONE', 'MALFORMED', 'INCOMPLETE', 'PROOF_BLOCKED', etc.
    message: str
    gate_identity: str

    def to_json(self) -> str:
        return json.dumps(asdict(self), sort_keys=True)

    @staticmethod
    def from_dict(data: dict) -> 'GateResult':
        if not isinstance(data, dict):
            raise ValueError("GateResult data must be a dictionary")
        
        required_fields = ["status", "failure_class", "message", "gate_identity"]
        for field in required_fields:
            if field not in data:
                raise ValueError(f"GateResult missing required field: {field}")
                
        if data['status'] not in ['PASS', 'FAIL', 'BLOCKED']:
            raise ValueError(f"Invalid status: {data['status']}")
            
        return GateResult(
            status=data['status'],
            failure_class=data['failure_class'],
            message=data['message'],
            gate_identity=data['gate_identity']
        )
