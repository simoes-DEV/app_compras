---
trigger: always_on
description: Faz commit e push automatico para o GitHub apos alteracoes no codigo
---

# Sincronização Automática com o GitHub (`Auto-Git`)

Sempre que você fizer alterações em arquivos deste projeto a pedido do usuário:
1. Ao concluir a tarefa, faça automaticamente o `git add .`, `git commit -m "<resumo em português>"` e `git push origin main` (usando `BypassSandbox: true`).
2. Confirme ao usuário que a alteração já subiu para o GitHub (`https://github.com/simoes-DEV/app_compras`).
