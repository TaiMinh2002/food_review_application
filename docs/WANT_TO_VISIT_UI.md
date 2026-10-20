# T16 — Want to Visit

Màn `/want-to-visit` được đối chiếu với Stitch screen `10 - Want to Visit` (`f2d9a2440a094837a6446842725772f3`). Màn dùng app shell và bottom navigation hiện có, với header Cá Nhân, tìm kiếm, sắp xếp, summary “Danh sách của bạn”, các thẻ quán có bookmark và empty state.

`WantToVisitRepository` và `wantToVisitIdsProvider` là state độc lập với Favorites. Provider scope theo user session, cập nhật lạc quan và hoàn tác nếu ghi lỗi. Detail có nút bookmark; Favorites và Profile có lối vào danh sách.

Hiện `MemoryWantToVisitRepository` chỉ là adapter demo trong RAM, dữ liệu mất khi khởi động lại và chưa ghi Firestore. Contract domain giữ nguyên để thay implementation khi tích hợp backend.
