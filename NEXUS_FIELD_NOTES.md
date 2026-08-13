# Nexus Field Notes

Các ghi nhận thực tế khi dùng Agent Workflow Kit trong `/Users/luuhung93/git/nexus-ai-platform`.

## 2026-08-09 — Cài đặt v2.1.0

### Generic `lib/` ignore có thể làm thiếu runtime

Repository đích có rule `.gitignore` dạng `lib/`, khiến `.agents/lib/*.sh` không xuất hiện trong `git status` và dễ bị bỏ sót khi commit bằng `git add .`.

Workaround tại Nexus:

```gitignore
!.agents/lib/
!.agents/lib/**
```

Đề xuất cho kit: thêm bước kiểm tra trong `self-test` hoặc tài liệu cài đặt để cảnh báo khi file bắt buộc dưới `.agents/` đang bị Git ignore.

### Codex cảnh báo model metadata

Live test sau vẫn chạy thành công và trả `ROLE_OK explorer`:

```bash
AGENT_HOST=codex .agents/agent explorer "Reply only ROLE_OK explorer"
```

Codex cảnh báo:

```text
Model metadata for `9r-terra` not found. Defaulting to fallback metadata.
```

Chưa cần sửa routing vì model thực tế vẫn là `9r-terra` và role hoàn thành đúng. Theo dõi thêm trước khi thêm cấu hình hoặc abstraction mới.

### Codex multi-agent không nhận reasoning mặc định của model nội bộ

Khi gọi reviewer qua Codex multi-agent với model được route thành `9r-sol`, cả reasoning mặc định `medium` và override `high` đều bị từ chối nhưng thông báo không liệt kê giá trị được hỗ trợ. Runner `.agents/agent explorer` với `9r-terra` vẫn chạy được.

Đề xuất cho kit: khai báo reasoning hợp lệ theo từng model nội bộ hoặc bỏ trường reasoning khi model metadata không có, đồng thời để lỗi hiển thị danh sách giá trị thực tế thay vì danh sách rỗng.

## 2026-08-11 — Migration Vite + Hyperdrive

### Agent worktree không thấy thay đổi chưa commit

Trong lúc migration đang có working tree lớn chưa commit, chạy:

```bash
AGENT_HOST=codex .agents/agent explorer "Rà apps/company_web và apps/company_core..."
```

Explorer chỉ đọc committed `HEAD`. Vì vậy báo cáo nói Vite, React Router và Worker assets chưa tồn tại dù parent session đã tạo các file đó. Kết quả vẫn hữu ích cho baseline nhưng bị stale đối với công việc đang diễn ra.

Đề xuất cho kit:

- Preflight cảnh báo rõ khi repository dirty và agent sẽ không thấy thay đổi hiện tại.
- Thêm tùy chọn `--include-dirty` để tạo snapshot tạm từ `HEAD` + tracked diff + untracked files rồi khởi tạo worktree agent từ snapshot đó.
- Nếu chưa hỗ trợ snapshot, tự đính kèm `git diff --stat` và danh sách untracked vào prompt để agent biết giới hạn dữ liệu.

### Reviewer cần nhận diff chưa commit

Với thay đổi lớn, reviewer chạy trên committed `HEAD` không thể review implementation hiện tại. Parent phải tự review hoặc commit tạm chỉ để agent nhìn thấy code, điều này không phù hợp khi user chưa yêu cầu commit.

Đề xuất cho kit: reviewer nhận trực tiếp patch qua stdin/artifact, áp patch read-only vào worktree tạm rồi review; không cần tạo commit trong repository chính.

### Explorer dễ lỗi shell quoting ở truy vấn tổng hợp

Explorer hai lần tạo lệnh `rg`/`for` dài với nhiều lớp quote và nhận `EXIT 1`, sau đó tự chia nhỏ lệnh và tiếp tục thành công. Không gây sai dữ liệu nhưng tăng thời gian và log noise.

Đề xuất cho kit: bổ sung rule cho explorer ưu tiên nhiều lệnh ngắn, tránh regex quote phức tạp trong một `zsh -lc`; nếu cần tổng hợp thì ghi script tạm hoặc dùng `rg` nhiều `-e` đơn giản.

### Cảnh báo metadata `9r-terra` vẫn tái diễn

Run `20260811-033335-explorer` tiếp tục hiện:

```text
Model metadata for `9r-terra` not found. Defaulting to fallback metadata.
```

Agent vẫn hoàn thành, nhưng đây là lần tái hiện thứ hai. Nên thêm metadata chính thức hoặc suppress warning có chủ đích khi router xác nhận model hợp lệ.

### Native reviewer không khởi tạo được trong phiên Nexus

Khi review refactor route ngày 2026-08-11, native multi-agent lỗi theo hai bước:

1. Model nội bộ `9r-sol` kế thừa reasoning `medium` nhưng báo reasoning không được hỗ trợ và không trả danh sách giá trị hợp lệ.
2. Khi fallback sang model công khai, tool báo `agent type is currently not available` cho role `reviewer`.

Đề xuất cho kit: preflight khả năng khởi tạo từng role/model trước khi dispatch, rồi fallback sang `.agents/agent reviewer` hoặc trả hướng dẫn rõ ràng thay vì để parent thử nhiều lần.

### Fallback reviewer có model nhưng thiếu provider credential

Ngày 2026-08-11, fallback sang default agent với `gpt-5.6-terra` khởi tạo được nhưng kết thúc bằng `404 No active credentials for provider: openai` tại endpoint router `ai.aov.one/v1/responses`.

Đề xuất cho kit: preflight cả role/model và credential của provider trước khi trả agent ID; nếu credential thiếu thì fail ngay với hướng dẫn fallback local review thay vì tạo agent rồi lỗi bất đồng bộ.

### Explorer read-only không ghi được artifact vào `.agents/runs`

Run `20260811-083947-explorer` hoàn thành audit UI Next → Vite nhưng sandbox của agent từ chối ghi file checklist vào `.agents/runs`, dù runner đã tạo run directory và prompt yêu cầu lưu artifact.

Đề xuất cho kit: runner tạo sẵn một output file writable hoặc thu `final` của agent và tự persist bằng parent process; read-only explorer không nên tự chịu trách nhiệm ghi artifact.

### Native explorer role không khả dụng dù đã đổi model

Ngày 2026-08-11, native multi-agent trong phiên Nexus từ chối `explorer` theo hai bước: model kế thừa `9r-sol` lỗi reasoning metadata; khi chỉ định `gpt-5.6-terra` với reasoning `low`, tool trả `agent type is currently not available`.

Đề xuất cho kit: preflight role availability trước model selection và fallback tự động sang `.agents/agent explorer`, thay vì yêu cầu parent thử lại thủ công.

## 2026-08-13 — Native agent vẫn lỗi reasoning metadata

Trong phiên Nexus, gọi native `explorer` tiếp tục route sang `9r-sol` và bị từ chối vì reasoning mặc định `medium`; lỗi vẫn không liệt kê giá trị reasoning hợp lệ. Thử cả fork-context và non-fork đều không khởi tạo agent.

Đề xuất cho kit: bỏ reasoning override khi metadata model nội bộ chưa có, hoặc chạy preflight model/role rồi tự fallback sang runner `.agents/agent` thay vì để parent thử lại thủ công.
