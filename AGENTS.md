# Regras do Projeto (`app_compras`)

## Sincronização Automática com o GitHub (`Auto-Git`)
Sempre que realizar qualquer alteração em arquivos de código ou configuração deste projeto:
1. Ao finalizar a alteração solicitada pelo usuário (e verificar que não há erros de compilação), execute automaticamente:
   - `git add .`
   - `git commit -m "<mensagem descritiva em português>"`
   - `git push origin main`
2. Como o diretório `.git` e a rede exigem acesso fora do sandbox no Windows, execute o comando de `commit` e `push` com `BypassSandbox: true`.
3. Informe brevemente ao usuário que as alterações já foram salvas e enviadas para o GitHub (`https://github.com/simoes-DEV/app_compras`).
