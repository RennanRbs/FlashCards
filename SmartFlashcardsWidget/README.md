# Smart Flashcards Widget Extension

Para ativar o widget na home screen:

1. No Xcode: **File > New > Target**
2. Escolha **Widget Extension**
3. Nome: `SmartFlashcardsWidget`, marque **Include Configuration App Intent** se quiser (opcional)
4. Apague os arquivos gerados pelo Xcode no novo target e adicione o arquivo `SmartFlashcardsWidget.swift` desta pasta ao target
5. No target do **Widget**, em **Signing & Capabilities**, adicione **App Groups** com `group.rennanRBS.FlashCards` (o mesmo do app principal)
6. O app principal já grava os dados do widget ao terminar uma sessão de estudo

O widget mostra o último deck estudado, quantos cards foram revisados na semana e o streak de dias.
