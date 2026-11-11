# App Compras

Aplicativo de lista de compras para registrar produtos, categorias, supermercados e preços com data de compra.

## Visão inicial

- cadastro de categorias
- cadastro de supermercados
- registro de compras com preço e quantidade
- cálculo simples de histórico por data e mercado
- base para evoluir para app familiar e depois monetização

## Requisitos

- Flutter SDK instalado
- Android Studio ou VS Code com emulador/configuração do dispositivo

## Como rodar

```bash
flutter pub get
flutter run
```

## Estrutura de dados inicial

- categorias
- supermercados
- compras

Cada compra salva:
- nome do produto
- categoria
- quantidade
- unidade
- preço
- supermercado
- data da compra
