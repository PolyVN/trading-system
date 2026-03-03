# Dev Scripts

Scripts chạy dev environment trên host, Docker chỉ chạy databases (MongoDB + Redis).

## Yêu cầu

- Docker Desktop (chạy MongoDB + Redis)
- Node.js 22+ (CMS Backend + Frontend)
- Rust 1.85+ (Trading Engine)
- Git Bash (Windows) hoặc bash (Linux/Mac)
- `cargo-watch` (optional, cho auto-recompile TE): `cargo install cargo-watch`

## Chạy từng module riêng

Mỗi script chạy trong **1 terminal riêng**:

```bash
# 1. Bật databases trước (bắt buộc)
./scripts/dev/dev-db.sh

# 2. Chạy module cần dev (chọn 1 hoặc nhiều, mỗi cái 1 terminal)
./scripts/dev/dev-te.sh      # Trading Engine  → http://localhost:3010
./scripts/dev/dev-be.sh      # CMS Backend     → http://localhost:3001
./scripts/dev/dev-fe.sh      # CMS Frontend    → http://localhost:3000
```

## Chạy tất cả (1 terminal)

```bash
./scripts/dev/dev-all.sh                  # tất cả services
./scripts/dev/dev-all.sh --no-te          # bỏ Trading Engine
./scripts/dev/dev-all.sh --no-be          # bỏ CMS Backend
./scripts/dev/dev-all.sh --no-fe          # bỏ CMS Frontend
./scripts/dev/dev-all.sh --no-te --no-fe  # chỉ DB + Backend
```

Nhấn `Ctrl+C` để stop tất cả.

## Quản lý databases

```bash
./scripts/dev/dev-db.sh          # start (mặc định)
./scripts/dev/dev-db.sh up       # start
./scripts/dev/dev-db.sh down     # stop + xóa containers
./scripts/dev/dev-db.sh status   # xem trạng thái
```

## Hot-reload (tự nhận code mới)

| Module | Cơ chế | Ghi chú |
|--------|--------|---------|
| Trading Engine | `cargo watch -x run` | Cài 1 lần: `cargo install cargo-watch`. Nếu chưa cài sẽ fallback `cargo run` (không auto-reload) |
| CMS Backend | `tsx watch` | Tự động, không cần cài thêm |
| CMS Frontend | Next.js Fast Refresh | Tự động, không cần cài thêm |

## Ports

| Service | Port | URL |
|---------|------|-----|
| CMS Frontend | 3000 | http://localhost:3000 |
| CMS Backend | 3001 | http://localhost:3001 |
| Trading Engine | 3010 | http://localhost:3010 |
| MongoDB | 27017 | See `packages/docker/dev/.env.host` |
| Redis | 6379 | See `packages/docker/dev/.env.host` |

## Ví dụ workflow

**Chỉ dev Frontend** (phổ biến nhất):
```bash
# Terminal 1
./scripts/dev/dev-db.sh
# Terminal 2
./scripts/dev/dev-be.sh
# Terminal 3
./scripts/dev/dev-fe.sh
```

**Chỉ dev Trading Engine**:
```bash
# Terminal 1
./scripts/dev/dev-db.sh
# Terminal 2
./scripts/dev/dev-te.sh
```

**Dev full stack**:
```bash
./scripts/dev/dev-all.sh
```

## Troubleshooting

**Redis/MongoDB auth failed**: Đảm bảo `.env` đúng credentials (xem `packages/docker/dev/.env.host`)

**Port đã bị chiếm**: Kill process cũ hoặc đổi port trong `.env`

**cargo-watch không tìm thấy**: `cargo install cargo-watch`

**node_modules chưa có**: Script tự chạy `npm install` nếu thiếu
