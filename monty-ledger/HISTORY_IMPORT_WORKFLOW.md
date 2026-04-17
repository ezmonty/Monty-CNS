# History Import Workflow

This file exists because the vault will get much stronger if it is fed your real chat history in packets instead of guessing from memory.

## What this workflow is for

Use it when you have:
- exported ChatGPT data
- searched up specific old chats
- copied important conversations
- collected old Claude chats or notes

## Rule

Do not dump everything into the vault at once.

Use this sequence:

1. identify one question or one theme
2. collect only the chats relevant to that theme
3. create a packet folder under `exports/`
4. extract evidence units from those chats
5. update only the profile notes that the evidence actually supports

## Good themes

- writing voice
- leadership
- duty of care
- revision behavior
- decision style
- role leakage
- raw versus polished output
- school versus work voice
- executive tone

## Suggested import path for ChatGPT export

1. export your data
2. locate `conversations.json`
3. run `scripts/split_conversations_json.py`
4. review the output folder
5. move only the relevant conversations into an import packet
6. use an agent prompt from `15_Agent_Prompts`

## Warning

A full export is too big to reason over cleanly in one pass.
Packets beat dumps.
