# Living Memory Loop (Taya)

Living Memory Loop is an iOS SwiftUI app that records short voice notes, sends them to a local backend for AI processing, and saves the resulting structured memories on-device.

Each memory includes:

- `title`
- `category`
- `mood`
- `action_items`
- `transcript`

## Current Scope

This repository currently ships one active product flow:

1. iOS app (`Living_Memory_Loop/`) records audio.
2. App calls `POST /api/process-memory` on the local Node server (`server/routes.ts`).
3. Server transcribes + structures the note with OpenAI APIs.
4. App stores results locally in `memories.json` via `MemoryFileStorage`.

The UI supports listing memories, pin/unpin, delete, share, and action-item completion.

## Tech Stack

- iOS: SwiftUI, Observation, AVFoundation
- Backend: Express + TypeScript
- AI: OpenAI transcription + chat-completions JSON structuring
- Persistence: local JSON file in the app Documents directory

## Repository Layout

```text
Living_Memory_Loop/
├── Living_Memory_Loop.xcodeproj
├── Living_Memory_Loop/
│   ├── Living_Memory_LoopApp.swift
│   ├── Assets.xcassets/
│   └── Taya/
│       ├── Info.plist
│       ├── Models/
│       ├── Services/
│       ├── Views/
│       ├── Helpers/
│       └── Resources/Fonts/
├── Living_Memory_LoopTests/
├── server/
├── package.json
└── tsconfig.json
```

Notes:

- `Living_Memory_Loop/TayaTests/` exists, but those files are excluded from current Xcode target membership.
- `package.json` includes Expo/Replit-related dependencies and scripts from earlier scaffolding. The iOS memory flow does not depend on Expo runtime code.

## Data Flow (Implemented)

1. `RecordScreen` starts recording through `AudioRecorderService` (`.m4a`, auto-stop at 60s).
2. Audio is base64-encoded and sent by `APIClient` to `/api/process-memory`.
3. Backend validates payload and size (`<= 25MB`), normalizes audio format, and transcribes audio.
4. Backend structures transcript into JSON (`title`, `category`, `action_items`, `mood`).
5. App creates a `Memory` model and persists it through `MemoryStore` + `MemoryFileStorage`.
6. `HomeScreen` refreshes and navigates to `MemoryDetailScreen` for the new memory.

## Prerequisites

- macOS with Xcode
- Node.js + npm
- OpenAI API key
- Inter font files in `Living_Memory_Loop/Taya/Resources/Fonts/`:
  - `Inter-Regular.ttf`
  - `Inter-Medium.ttf`
  - `Inter-SemiBold.ttf`
  - `Inter-Bold.ttf`

## Local Setup

1. Install Node dependencies from repository root:

```bash
npm install
```

2. Start backend:

```bash
HOST=127.0.0.1 OPENAI_API_KEY=your_key_here npm run server:dev
```

Expected log:

```text
express server serving on http://127.0.0.1:5000
```

3. Open `Living_Memory_Loop.xcodeproj` in Xcode.

4. Confirm app target plist settings:

- `Generate Info.plist File` = `No`
- `Info.plist File` = `$(SRCROOT)/Living_Memory_Loop/Taya/Info.plist`

5. Build and run (`Cmd+B`, then Run).

## Configuration

### iOS app base URL

`API_BASE_URL` is read from `Living_Memory_Loop/Taya/Info.plist` and defaults to:

```text
http://127.0.0.1:5000
```

For a physical iPhone on your local network:

- Run server with `HOST=0.0.0.0`
- Set `API_BASE_URL` to `http://<your-mac-lan-ip>:5000`

### Backend environment variables

Required:

- `OPENAI_API_KEY` or `AI_INTEGRATIONS_OPENAI_API_KEY`

Optional:

- `OPENAI_BASE_URL` or `AI_INTEGRATIONS_OPENAI_BASE_URL`
- `MEMORY_TRANSCRIPTION_MODEL` (fallbacks to `gpt-4o-mini-transcribe`, then `whisper-1`)
- `MEMORY_STRUCTURING_MODEL` (fallbacks to `gpt-5-mini`, then `gpt-4o-mini`)
- `PORT` (default `5000`)
- `HOST` (default `127.0.0.1`, except Replit-style environments)

## API Contract (Active Endpoint)

`POST /api/process-memory`

Request body:

```json
{
  "audio": "<base64-audio>"
}
```

Success response:

```json
{
  "transcript": "...",
  "title": "...",
  "category": "Shopping | Learning | Meeting | Personal | Ideas | Health | Work | Travel | Other",
  "action_items": ["..."],
  "mood": "..."
}
```

Common error cases:

- `400`: invalid audio payload or transcription failure
- `413`: recording too large
- `500/503`: API key, model availability, quota/rate-limit, or network/backend dependency issues

## Testing

Run tests in Xcode with `Cmd+U`.

Current test coverage in `Living_Memory_LoopTests/` includes:

- `APIClient` request construction and error mapping
- `Memory` JSON codable behavior
- `MemoryStore` sorting, toggles, and persistence behavior
- `TimeFormatting` boundary behavior

## Troubleshooting

- App shows "Could not reach the backend":
  - Ensure the server is running and reachable at `API_BASE_URL`.
- App shows OpenAI credential errors:
  - Ensure `OPENAI_API_KEY` (or `AI_INTEGRATIONS_OPENAI_API_KEY`) is set before starting server.
- Processing fails for large clips:
  - Keep recordings short (the app auto-stops at ~60 seconds).
- Share sheet options look limited on Simulator:
  - This is expected; Simulator has fewer share extensions than real devices.

## Active vs Scaffolded Code

This repo still contains scaffold code from an Expo/Replit template:

- Expo-oriented scripts/deps in `package.json`
- `server/replit_integrations/*` modules

Those modules include extra chat/audio/image route helpers and DB imports that are not wired into the current `registerRoutes` path used by the iOS app.

If your goal is only the memory app, focus on:

- `Living_Memory_Loop/Taya/*`
- `server/index.ts`
- `server/routes.ts`

## Privacy Notes

- Memory records are saved locally on-device (`memories.json`).
- Audio is sent to your configured backend/OpenAI endpoint for processing.
- Do not commit API keys or `.env` files.

## License

Private project.
