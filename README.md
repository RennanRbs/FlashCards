# Smart Flashcards

---

# Português (Brasil)

**Estudo inteligente offline.** App iOS para criar decks de flashcards, estudar com repetição espaçada (SRS) e acompanhar seu progresso.

## Visão geral

O Smart Flashcards permite organizar o estudo em **decks** e **cards** (frente e verso), com suporte a tags, leitura em voz alta (TTS), notificações de revisão e exportação/importação em JSON. Os dados ficam no dispositivo; o app vem com conteúdo inicial opcional focado em programação (POO, estruturas de dados, arquitetura, linguagens, redes e segurança).

## Arquitetura

### Stack

- **UI:** SwiftUI  
- **Persistência:** SwiftData  
- **Plataforma:** iOS  

### Fluxo de telas

```
RootView (autenticação)
    ├── LoginView (Sign in with Apple ou "Continuar sem login")
    └── ContentView (após login)
            └── DecksListView
                    ├── DeckDetailView (lista de cards do deck)
                    │       ├── AddEditCardView (sheet)
                    │       ├── CardDetailView (navegação)
                    │       └── StudyView (tela cheia)
                    ├── SettingsView (sheet)
                    └── StatisticsView (sheet)
```

### Camadas

| Camada | Responsabilidade |
|--------|------------------|
| **Models** | `Deck`, `Card`, `StudySession` (SwiftData `@Model`); `CardId` para navegação. |
| **Features** | Telas por domínio: Login, Decks, Cards, Study, Settings, Statistics. ViewModels onde faz sentido (ex.: `DecksListViewModel`). |
| **Core** | Auth (`AuthService`, `KeychainHelper`), Design System (tipografia, espaçamento, botões, chips, barras de progresso), Schema SwiftData. |
| **Services** | `SRSService` (repetição espaçada), `TTSService` (text-to-speech), `NotificationService` (lembretes), `ExportImportService` (JSON), `DecksJSONService` (seed e incremento de decks/cards via JSON). |

### Dados

- **SwiftData:** fonte principal; armazena decks, cards e sessões de estudo.  
- **JSON no bundle:** `decks_programming.json` — conteúdo inicial (5 decks de programação).  
- **JSON em Documents:** `decks_data.json` — cópia do seed após primeira importação; incrementado quando o usuário adiciona decks ou cards.

## UI e design

- **Design system:** tipografia com `.rounded`, espaçamento centralizado em `AppSpacing`, cores semânticas (`BackgroundColor`, `PrimaryColor`, `CardBackgroundColor`, `ErrorColor`, `SuccessColor`).  
- **Componentes reutilizáveis:** `PrimaryButton`, `CardContainer`, `TagChip`, `ProgressBar`; haptics e animações (ex.: confete ao terminar uma sessão de estudo).  
- **Telas principais:** lista de decks com progresso, detalhe do deck com lista de cards (reordenar/excluir), estudo em tela cheia com flip 3D e botões de resultado (incorreto / difícil / correto), configurações (conta, notificações, TTS, export/import) e estatísticas com gráficos (Charts).

## Lógica de negócio

### Autenticação

- **Sign in with Apple** opcional ou **"Continuar sem login"**; estado em `AuthService` e identificador no Keychain.  
- Em DEBUG, pode haver bypass automático para abrir direto no conteúdo.

### Repetição espaçada (SRS)

- **SRSService** atualiza, por card, `nextReviewDate`, `intervalDays`, `easeFactor` e contagens (`totalCorrect`, `totalIncorrect`, `consecutiveCorrect`) conforme o resultado (incorreto / difícil / correto).  
- Fila de estudo prioriza cartões vencidos e, em seguida, os mais errados; limite configurável (ex.: 50 cards por sessão).

### Estudo

- Cada execução de "Estudar" gera uma `StudySession` (deck, início/fim, acertos/erros).  
- Ao final da sessão: resumo (acertos/erros) e opção de animação de confete.  
- TTS opcional para ouvir o texto da frente ou do verso.

### Dados e JSON

- Criação/edição de decks e cards via UI; persistência em SwiftData.  
- **Exportar/importar:** JSON de decks (e cards) nas configurações.  
- **Seed:** na primeira abertura (sem `decks_data.json`), o app importa o JSON do bundle para SwiftData e grava em Documents; ao adicionar deck ou card, o JSON em Documents é incrementado.

## Como usar o app (usuário final)

### Primeira abertura

1. Na tela de login, toque em **Sign in with Apple** ou em **Continuar sem login**.  
2. Se for a primeira vez, o app pode carregar automaticamente decks de exemplo (programação).

### Decks

- **Ver lista:** na tela principal você vê todos os decks, com quantidade de cards e percentual "dominado".  
- **Criar deck:** toque no **+** na barra superior; informe o nome e confirme.  
- **Abrir um deck:** toque no deck para ver a lista de cards.  
- **Editar nome:** dentro do deck, toque em **Editar** e altere o nome.  
- **Reordenar ou excluir:** use os controles da lista (arrastar para reordenar, deslizar para excluir).

### Cards

- **Adicionar card:** dentro de um deck, toque no **+**; preencha **frente** (pergunta) e **verso** (resposta), opcionalmente tags e "Importante".  
- **Editar ou excluir:** toque no card para ver detalhes; edite ou exclua a partir da tela de detalhe ou da lista.

### Estudar

1. Abra um deck e toque em **Estudar**.  
2. Aparece um card (frente); toque no card para **virar** e ver o verso.  
3. Com o card virado, use **Incorreto**, **Difícil** ou **Correto** conforme seu desempenho.  
4. Se **TTS** estiver ativado nas configurações, use **Ouvir** para ouvir o texto.  
5. Ao terminar a fila, veja o **resumo** (acertos/erros) e, se quiser, a animação de confete.

### Configurações

- **Conta:** sair da conta (volta à tela de login).  
- **Estudo:** ligar/desligar notificações de revisão e **Text-to-Speech (TTS)**.  
- **Dados:** **Exportar decks (JSON)** para backup ou **Importar decks (JSON)** para restaurar/carregar conteúdo.

### Estatísticas

- Toque no ícone de **gráfico** na tela de decks.  
- Visualize acertos/erros por dia (últimos 7 dias), totais, taxa de sucesso e sequência de dias estudados (streak).

## Requisitos e como rodar

- **Xcode** (versão compatível com o projeto).  
- **iOS** (versão alvo definida no projeto, ex.: iOS 18+).  
- **Swift 5.**  

1. Abra `FlashCards.xcodeproj` no Xcode.  
2. Selecione o destino (simulador ou dispositivo).  
3. Build e run (⌘R).

## Estrutura de pastas (resumida)

```
FlashCards/                 # App principal
├── Features/                # Telas por feature
│   ├── Login/               # RootView, LoginView
│   ├── Decks/               # DecksListView, DeckDetailView, DecksListViewModel
│   ├── Cards/               # AddEditCardView, CardDetailView
│   ├── Study/               # StudyView
│   ├── Settings/            # SettingsView
│   └── Statistics/          # StatisticsView
├── Core/                    # Auth, Design, Persistence
├── Models/                  # Deck, Card, StudySession, CardId
├── Services/                # SRS, TTS, Notifications, ExportImport, DecksJSON
├── Resources/               # decks_programming.json (seed)
├── Assets.xcassets/         # Cores, ícones, App Icon
└── Widget/                  # WidgetDataStore (extensão)
SmartFlashcardsWidget/       # Extensão de widget
FlashCardsTests/             # Testes unitários
```

## Licença e créditos

Projeto de uso interno/educacional. Dados do usuário permanecem no dispositivo; Sign in with Apple e opção "Continuar sem login" conforme implementado no app.

---

# English

**Smart study offline.** iOS app to create flashcard decks, study with spaced repetition (SRS), and track your progress.

## Overview

Smart Flashcards lets you organize study with **decks** and **cards** (front and back), with support for tags, text-to-speech (TTS), review reminders, and JSON export/import. Data stays on device; the app includes optional starter content focused on programming (OOP, data structures, architecture, languages, networking, and security).

## Architecture

### Stack

- **UI:** SwiftUI  
- **Persistence:** SwiftData  
- **Platform:** iOS  

### Screen flow

```
RootView (authentication)
    ├── LoginView (Sign in with Apple or "Continue without login")
    └── ContentView (after login)
            └── DecksListView
                    ├── DeckDetailView (deck card list)
                    │       ├── AddEditCardView (sheet)
                    │       ├── CardDetailView (navigation)
                    │       └── StudyView (full screen)
                    ├── SettingsView (sheet)
                    └── StatisticsView (sheet)
```

### Layers

| Layer | Responsibility |
|--------|------------------|
| **Models** | `Deck`, `Card`, `StudySession` (SwiftData `@Model`); `CardId` for navigation. |
| **Features** | Screens by domain: Login, Decks, Cards, Study, Settings, Statistics. ViewModels where applicable (e.g. `DecksListViewModel`). |
| **Core** | Auth (`AuthService`, `KeychainHelper`), Design System (typography, spacing, buttons, chips, progress bars), SwiftData schema. |
| **Services** | `SRSService` (spaced repetition), `TTSService` (text-to-speech), `NotificationService` (reminders), `ExportImportService` (JSON), `DecksJSONService` (seed and increment decks/cards via JSON). |

### Data

- **SwiftData:** main store; holds decks, cards, and study sessions.  
- **Bundle JSON:** `decks_programming.json` — initial content (5 programming decks).  
- **Documents JSON:** `decks_data.json` — copy of seed after first import; incremented when the user adds decks or cards.

## UI and design

- **Design system:** typography with `.rounded`, spacing via `AppSpacing`, semantic colors (`BackgroundColor`, `PrimaryColor`, `CardBackgroundColor`, `ErrorColor`, `SuccessColor`).  
- **Reusable components:** `PrimaryButton`, `CardContainer`, `TagChip`, `ProgressBar`; haptics and animations (e.g. confetti at session end).  
- **Main screens:** deck list with progress, deck detail with card list (reorder/delete), full-screen study with 3D flip and result buttons (incorrect / hard / correct), settings (account, notifications, TTS, export/import), and statistics with charts (Charts).

## Business logic

### Authentication

- Optional **Sign in with Apple** or **"Continue without login"**; state in `AuthService` and identifier in Keychain.  
- In DEBUG, automatic bypass may open directly into content.

### Spaced repetition (SRS)

- **SRSService** updates per-card `nextReviewDate`, `intervalDays`, `easeFactor`, and counts (`totalCorrect`, `totalIncorrect`, `consecutiveCorrect`) based on result (incorrect / hard / correct).  
- Study queue prioritizes due cards first, then most incorrect; configurable limit (e.g. 50 cards per session).

### Study

- Each "Study" run creates a `StudySession` (deck, start/end, correct/incorrect).  
- At session end: summary (correct/incorrect) and optional confetti animation.  
- Optional TTS to hear front or back text.

### Data and JSON

- Create/edit decks and cards via UI; persistence in SwiftData.  
- **Export/import:** JSON of decks (and cards) in settings.  
- **Seed:** on first launch (no `decks_data.json`), the app imports bundle JSON into SwiftData and writes to Documents; when the user adds a deck or card, the Documents JSON is incremented.

## How to use the app (end user)

### First launch

1. On the login screen, tap **Sign in with Apple** or **Continue without login**.  
2. On first run, the app may load sample decks (programming) automatically.

### Decks

- **View list:** on the main screen you see all decks with card count and "mastered" percentage.  
- **Create deck:** tap **+** in the top bar; enter name and confirm.  
- **Open a deck:** tap a deck to see its card list.  
- **Edit name:** inside the deck, tap **Edit** and change the name.  
- **Reorder or delete:** use list controls (drag to reorder, swipe to delete).

### Cards

- **Add card:** inside a deck, tap **+**; fill **front** (question) and **back** (answer), optionally tags and "Important".  
- **Edit or delete:** tap a card for details; edit or delete from the detail screen or list.

### Study

1. Open a deck and tap **Study**.  
2. A card (front) appears; tap the card to **flip** and see the back.  
3. With the card flipped, use **Incorrect**, **Hard**, or **Correct** based on your performance.  
4. If **TTS** is enabled in settings, use **Listen** to hear the text.  
5. When the queue is done, see the **summary** (correct/incorrect) and optional confetti.

### Settings

- **Account:** sign out (returns to login).  
- **Study:** turn review notifications and **Text-to-Speech (TTS)** on or off.  
- **Data:** **Export decks (JSON)** for backup or **Import decks (JSON)** to restore or load content.

### Statistics

- Tap the **chart** icon on the decks screen.  
- View correct/incorrect per day (last 7 days), totals, success rate, and study streak.

## Requirements and how to run

- **Xcode** (version compatible with the project).  
- **iOS** (target version set in the project, e.g. iOS 18+).  
- **Swift 5.**  

1. Open `FlashCards.xcodeproj` in Xcode.  
2. Select destination (simulator or device).  
3. Build and run (⌘R).

## Folder structure (summary)

```
FlashCards/                 # Main app
├── Features/               # Screens by feature
│   ├── Login/              # RootView, LoginView
│   ├── Decks/              # DecksListView, DeckDetailView, DecksListViewModel
│   ├── Cards/              # AddEditCardView, CardDetailView
│   ├── Study/              # StudyView
│   ├── Settings/           # SettingsView
│   └── Statistics/         # StatisticsView
├── Core/                   # Auth, Design, Persistence
├── Models/                 # Deck, Card, StudySession, CardId
├── Services/               # SRS, TTS, Notifications, ExportImport, DecksJSON
├── Resources/              # decks_programming.json (seed)
├── Assets.xcassets/        # Colors, icons, App Icon
└── Widget/                 # WidgetDataStore (extension)
SmartFlashcardsWidget/      # Widget extension
FlashCardsTests/            # Unit tests
```

## License and credits

Internal/educational use. User data remains on device; Sign in with Apple and "Continue without login" as implemented in the app.
