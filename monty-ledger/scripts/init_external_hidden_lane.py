#!/usr/bin/env python3
from pathlib import Path
import json

ROOT = Path.cwd()
TARGET = ROOT / 'external_hidden_lane_example'
TARGET.mkdir(exist_ok=True)
(TARGET / 'README.txt').write_text(
    'This is only a placeholder example.\n'
    'Do not store hidden material in the main vault by default.\n'
    'If you choose to keep hidden notes, prefer an encrypted store outside the vault.\n'
)
example = {
    'shadow_id': 'H-001',
    'incident_class': 'trauma',
    'influence_domains': ['authority_response', 'conflict_tone'],
    'exposure_rule': 'manual-only',
    'abstraction_level': 'minimal',
    'safe_summary': 'Example only.',
    'retrieval_policy': 'Only for explicit hidden-layer work.'
}
(TARGET / 'shadow_reference_example.json').write_text(json.dumps(example, indent=2))
print(f'Created example external hidden lane scaffold at {TARGET}')
