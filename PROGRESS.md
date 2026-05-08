# Mars App — Development Progress Log

> **Target:** Flutter app that runs the `gemma-4-E2B-it.litert.lm` model fully on-device (offline),
> with 4 AI agents (psychological, social, linguistic, etc.), no internet required after setup.

---

## Overall Roadmap

| # | Step | Status |
|---|------|--------|
| 1 | Environment setup (packages + storage + download foundation) | ✅ Done |
| 2 | LLM Bridge + Download Screen UI | ✅ Done |
| 3 | Agent architecture (4 isolated chat agents) | ⬜ Next |
| 4 | Chat UI (message bubbles, input field, per-agent screens) | ⬜ Pending |

---

## Step 1 — Environment Setup ✅

**Goal:** Lay the foundation so the app can download a 2 GB model file and run it on-device.

---

### 1.1 — Packages added to `pubspec.yaml`

| Package | Version | Why |
|---------|---------|-----|
| `flutter_riverpod` | `^2.6.1` | State manager for 4 independent agents. Uses `family` providers so each agent has isolated conversation state — no cross-talk between agents. |
| `dio` | `^5.8.0` | HTTP client that supports `Range` headers for resumable downloads. The built-in `http` package cannot resume an interrupted 2 GB download. |
| `path_provider` | `^2.1.5` | Gives access to `getApplicationSupportDirectory()` — a hidden, app-private folder that survives app updates and is NOT backed up to iCloud/Google Drive (critical: a 2 GB file must not upload to the cloud). |

---

### 1.2 — Files created

#### `lib/main.dart`
- Replaced the default counter demo with a clean `MarsApp` widget.
- Wrapped the entire app in `ProviderScope` — **this is mandatory** for Riverpod to work anywhere in the widget tree.

#### `lib/core/services/model_storage_service.dart`
**Responsibility:** Everything related to WHERE the model file lives on disk.

Key decisions:
- Uses `getApplicationSupportDirectory()` (not Downloads, not Documents).
  - Hidden from the user's file manager.
  - Survives app updates.
  - Excluded from iCloud / Google Drive backup (important — 2 GB must not auto-upload).
- Creates a `models/` subfolder inside the app support directory.
- `getDownloadedBytes()` reads the current size of a partial file — used by the download service to know where to resume.
- `isModelDownloaded()` checks that the file exists AND has non-zero size (guards against empty/corrupted files).
- `deleteModel()` utility for a "re-download" option in the settings screen (future step).

Model file name stored as a constant: `gemma-4-E2B-it.litert.lm`

#### `lib/core/services/model_download_service.dart`
**Responsibility:** Downloading the 2 GB model with pause/resume support.

Key decisions:
- Returns a `Stream<DownloadState>` instead of a `Future` — the UI listens to every chunk and updates the progress bar in real time without polling.
- **Resume logic:** On start, checks `getDownloadedBytes()`. If > 0, sends HTTP header `Range: bytes=X-`. The server continues from byte X, and the file is opened in `FileMode.append`. This means if the user's WiFi drops at 80%, the next attempt only downloads the remaining 20%.
- `CancelToken` from Dio is used to pause: cancelling the token stops the download without deleting the partial file.
- `DownloadStatus` enum has 5 states: `idle`, `downloading`, `paused`, `completed`, `error` — each maps to a different UI state.
- Timeouts: 30 seconds to connect, 30 minutes to receive (a 2 GB file on slow WiFi can take a long time).

#### `lib/core/providers/download_provider.dart`
**Responsibility:** Riverpod wiring — makes services available to the widget tree.

Providers defined:
- `modelStorageServiceProvider` — singleton `ModelStorageService`.
- `modelDownloadServiceProvider` — singleton `ModelDownloadService`, receives storage via `ref.read`.
- `modelDownloadedProvider` — `FutureProvider<bool>`: any widget can watch this to know if the model is ready. Used in Step 2 to decide: show Download screen OR show main Chat screen.
- `downloadStateProvider` — `StateProvider<DownloadState>`: holds the live download progress during an active session.

---

### 1.3 — Folder structure after Step 1

```
lib/
├── main.dart                                  ← App root, ProviderScope
├── core/
│   ├── providers/
│   │   └── download_provider.dart             ← Riverpod providers
│   └── services/
│       ├── model_storage_service.dart         ← File system / storage
│       └── model_download_service.dart        ← Download + resume logic
├── features/
│   └── agents/                                ← Empty, used in Step 4
test/
└── widget_test.dart                           ← Updated to match new app structure
```

---

## Step 2 — LLM Bridge + Download Screen UI ✅

**Goal:** Build the bridge between Flutter and the LiteRT engine, and the download screen that runs once on first launch.

---

### 2.1 — Package added

| Package | Version | Why |
|---------|---------|-----|
| `flutter_litert_lm` | `^0.3.0` | Official Google package. Exposes `LiteLmEngine` + `LiteLmConversation` — wraps the native C++ LiteRT engine so Dart code can call it. The engine memory-maps the 2 GB file instead of copying it into RAM. |

Why not `mediapipe_genai`? It's 24 months stale and can't load from a local file path.
Why not `flutter_gemma`? It works but is a third-party wrapper. `flutter_litert_lm` is the first-party Google package built specifically for `.litert.lm` files.

---

### 2.2 — Files created

#### `lib/core/services/inference_service.dart`
**Responsibility:** The bridge — owns the LiteRT engine lifecycle.

Key decisions:
- `loadModel()` tries `LiteLmBackend.gpu` first (faster inference on Android). If the GPU backend fails (not all devices support it), it **automatically retries with CPU**. This means the app works on any Android device.
- `cacheDir` passed to `LiteLmEngineConfig` — LiteRT stores compiled GPU shaders here. Second launch loads ~3x faster.
- `createConversation(systemPrompt, history)` — creates a `LiteLmConversation` with the system instruction baked in. Each call returns a **new, isolated session** — critical for the 4-agent architecture in Step 3.
- `streamResponse(conversation, message)` calls `sendMessageStream()` which returns `Stream<LiteLmMessage>`. We map it to `Stream<String>` (text deltas only) for the UI.
- A custom `StreamTransformer` resets `_status` to `ready` when the stream finishes — prevents the engine from appearing busy after a completed response.

#### `lib/core/providers/inference_provider.dart`
**Responsibility:** Riverpod wiring for the engine lifecycle.

Providers:
- `inferenceServiceProvider` — singleton `InferenceService`. Calls `service.dispose()` when the provider is destroyed (app shutdown), which releases native memory.
- `ModelLoaderNotifier` (`AsyncNotifier`) — manages the load sequence. Widgets watch `modelLoaderProvider` to know the engine state. `AsyncValue.guard()` wraps the load so errors surface cleanly in the UI without crashing.

#### `lib/features/setup/download_screen.dart`
**Responsibility:** The one-time first-launch screen.

UI flow:
1. User sees idle screen with "Download Model (~2 GB)" button.
2. Tap → `ModelDownloadService.download()` stream starts. Screen shows live progress bar + byte counter + percentage.
3. If WiFi drops → tap "Pause" → `CancelToken` cancels the stream, partial file stays on disk.
4. Tap "Resume" → stream restarts with `Range: bytes=X-` header, picks up from where it stopped.
5. `DownloadStatus.completed` → `modelLoaderProvider.notifier.loadModel()` is called automatically.
6. Engine loads → `InferenceStatus.ready` → `Navigator.pushReplacementNamed('/home')`.
7. Error state shows the error message + "Retry" button.

#### `lib/main.dart` — updated
Added `_StartupRouter` which checks `modelDownloadedProvider` on cold start:
- Model file missing → `DownloadScreen`
- Model file exists → `_ModelLoaderGate` (loads engine, then shows home)
- Engine ready → `_PlaceholderHome` (replaced in Step 3)

---

### 2.3 — Folder structure after Step 2

```
lib/
├── main.dart                                      ← Startup routing logic
├── core/
│   ├── providers/
│   │   ├── download_provider.dart                 ← Step 1
│   │   └── inference_provider.dart                ← Engine lifecycle provider
│   └── services/
│       ├── model_storage_service.dart             ← Step 1
│       ├── model_download_service.dart            ← Step 1
│       └── inference_service.dart                 ← LiteRT bridge
└── features/
    ├── setup/
    │   └── download_screen.dart                   ← First-launch download UI
    └── agents/                                    ← Empty, used in Step 3
```

---

## Step 3 — Agent Architecture ⬜ (Next)

**What will be built:**
- An `AgentType` enum with 4 values (e.g. `psychological`, `social`, `linguistic`, `coaching`).
- An `AgentConfig` class — holds the name, description, and **system prompt** for each agent. The system prompt is what makes the psychological agent different from the social one; it's the personality injected before every conversation.
- A `chatProvider(AgentType)` family provider — each agent type gets its own `LiteLmConversation` instance. The psychological agent's conversation history is completely isolated from the social agent's.
- A home screen with 4 agent cards.

---

## Step 4 — Chat UI ⬜

**What will be built:**
- A shared `ChatScreen` widget parameterised by `AgentType`.
- Message bubbles (user right, AI left).
- Text input + send button.
- Streaming "typing" indicator while the model generates (tokens appear word by word).
