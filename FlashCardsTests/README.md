# FlashCards Unit Tests

Para rodar os testes:

1. No Xcode: **File > New > Target**
2. Escolha **Unit Testing Bundle**, nome: `FlashCardsTests`
3. Adicione a pasta `FlashCardsTests` ao novo target (ou arraste os arquivos para o target)
4. No **Build Phases** do target FlashCardsTests, adicione o target **FlashCards** em **Dependencies**
5. Certifique-se de que **FlashCards** está em **Link Binary With Libraries** (ou que o target de teste depende do app para ter @testable import FlashCards)
6. **Product > Test** (Cmd+U)

Testes incluídos:
- **SRSServiceTests**: gravação de resultado (incorrect/correct), fila de estudo
- **ExportImportServiceTests**: exportar decks para JSON, importar e validar modelos
- **KeychainHelperTests**: salvar/ler/remover no Keychain, userIdentifier
