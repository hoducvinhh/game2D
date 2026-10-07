# KẾ HOẠCH TOÀN DIỆN NÂNG CẤP GAME 2D ĐẠT ĐIỂM TỐI ĐA (5.0 / 5.0)
## BỔ SUNG: VIRTUAL JOYSTICK, NÚT TẤN CÔNG & TỔNG HỢP DANH MỤC ASSETS

> **Dự án:** Lil' Boy Domixi (Game 2D Roguelite / Survivor trên Godot Engine 4)  
> **Mục tiêu:** Đáp ứng trọn vẹn và xuất sắc cả 5 nhóm tiêu chí đánh giá sản phẩm Game 2D, đạt điểm tối đa **5.0 / 5.0 điểm**.

---

## 1. Bảng Đối Chiếu Hiện Trạng & Mục Tiêu Đạt Điểm

| Nhóm tiêu chí (Điểm) | Yêu cầu trong đề bài | Hiện trạng dự án | Kế hoạch nâng cấp để đạt điểm tối đa |
| :--- | :--- | :--- | :--- |
| **Nhóm 1 (1.0 đ)** | • Có cốt truyện hấp dẫn<br>• Phong cách nghệ thuật chủ đạo<br>• Cơ chế game đa dạng, logic | • Prologue, di chuyển, vũ khí, nâng cấp level, dash, attack chủ động và ultimate đã có.<br>• Các nhân vật có sprite/chỉ số riêng; nội tại/kỹ năng đặc trưng riêng cho từng nhân vật vẫn chưa hoàn thiện. | 1. Rà soát tính nhất quán UI/Typography vàng-đen retro.<br>2. Thiết kế nội tại/kỹ năng riêng cho 4 nhân vật (còn lại).<br>3. Dash: 180px tối đa, i-frame 0,25 giây, hồi chiêu 2 giây; Ultimate cần đầy nộ, AOE và +50% tốc đánh trong 5 giây. |
| **Nhóm 2 (1.0 đ)** | • Nhiều nhân vật/đối tượng/vật phẩm<br>• Thế giới game lôi cuốn<br>• Đồ hoạ dễ nhìn | • Có dữ liệu 4 nhân vật, quái thường/nhanh/tầm xa, boss, pet và các pickups EXP/vàng/thịt/nam châm/bom/rương.<br>• Sprite tương ứng phần lớn đã có; cần xác minh trực quan trong game. | 1. Cân chỉnh chỉ số/hành vi quái và kiểm tra tương phản trên mỗi nền.<br>2. Không yêu cầu tạo ảnh mới cho các sửa đổi hiện tại; ưu tiên asset có sẵn hoặc hiệu ứng dựng bằng Godot. |
| **Nhóm 3 (1.0 đ)** | • Gameplay hấp dẫn, độc đáo<br>• Demo mượt, không giật lag hoặc crash | • Touch HUD, điều khiển PC, giới hạn 85 quái, tiến hóa vũ khí và hiệu ứng chiến đấu đã được nối logic.<br>• Chưa có benchmark chứng minh 60 FPS; hiệu năng còn cần đo trên máy đích. | 1. Kiểm tra joystick đa chạm, chuột/phím, cooldown và tránh kích hoạt lặp.<br>2. Benchmark tình huống đông quái; tối ưu theo số đo, không cam kết FPS khi chưa đo. |
| **Nhóm 4 (1.0 đ)** | • Nhiều cấp độ chơi (levels) / bản đồ (maps)<br>• Thực hiện nhiệm vụ / hoàn thành màn chơi có độ khó & thú vị | • Có 3 map chọn được; map 2 có vùng làm chậm, map 3 có sét cảnh báo trước và khác biệt xác suất spawn quái.<br>• Quest diệt quái/nhặt vàng/boss đã có, thưởng 100 vàng một lần mỗi lượt. | 1. Kiểm tra cân bằng/tầm nhìn của hazard và phân bố quái theo map.<br>2. Quest theo độ khó: Dễ 30/20, Khó 50/30, Siêu khó 75/45 (diệt quái/nhặt vàng). |
| **Nhóm 5 (1.0 đ)** | • **NPC có tính năng thông minh sử dụng AI**<br>• Có độ hoàn thiện cao<br>• Có khả năng thương mại | • Có separation, quái tầm xa, boss hai pha, pet, damage numbers, shake, pause/settings, cửa hàng talent, profile và achievements thưởng vàng.<br>• AI chưa tổ chức thành FSM; SFX còn giới hạn ở âm thanh có sẵn. | 1. Xác minh AI, boss và pet bằng play-test; FSM là cải tiến tiếp theo, không phải tính năng đã hoàn tất.<br>2. Bổ sung SFX chỉ khi có nguồn âm thanh được duyệt; hiện dùng các file có sẵn và bus BG/DR.<br>3. Kiểm tra save/load và thưởng thành tựu không bị nhận lặp. |

---

## 2. Thiết Kế Hệ Thống Điều Khiển Màn Hình: Virtual Joystick & Cụm Nút Tấn Công

Để trải nghiệm game trực quan (đáp ứng cả PC dùng chuột/phím và Mobile/cảm ứng), game sẽ được bổ sung một lớp điều khiển ảo chuyên nghiệp (**Touch Controls HUD**):

```
+-------------------------------------------------------------------------+
| [HP Bar] [EXP Bar] [Vàng: 150]              [Nhiệm vụ: 25/50] [Pause II]|
|                                                                         |
|                                                                         |
|                               PLAYER                                    |
|                                                                         |
|                                                                         |
|      ( VIRTUAL JOYSTICK )                             [ ULTIMATE 'F' ]  |
|          +---------+                                                    |
|          |    ^    |                                  [ DASH 'Space' ]  |
|       <  |  ( o )  |  >                                                 |
|          |    v    |                                  [ ATTACK 'J' ]    |
|          +---------+                                    (Nút To Nhất)   |
+-------------------------------------------------------------------------+
```

### 2.1. Thành Phần & Cơ Chế Hoạt Động

1. **Virtual Joystick (Analog Stick Ảo - Góc Trái Dưới):**
   - **Cấu tạo:** Bao gồm `JoystickBase` (vòng tròn nền trong suốt) và `JoystickKnob` (cần gạt tâm).
   - **Cơ chế:**
     - Cho phép kéo thả trong bán kính tối đa 60px.
     - Trả về vector hướng chuẩn hóa `Vector2(x, y)` từ `-1.0` đến `1.0`.
     - Hỗ trợ **Dynamic Joystick** (chạm vào bất kỳ điểm nào ở nửa trái màn hình thì Joystick tự xuất hiện tại ngón tay) hoặc **Static Joystick** (cố định ở góc trái).
     - Tự động đồng bộ với phím cứng bàn phím (`WASD` / Mũi tên). Khi nhả chạm, núm gạt tự đàn hồi về tâm (`Tween`).

2. **Cụm Nút Hành Động (Action Buttons - Góc Phải Dưới):**
   - **Nút Tấn Công Chủ Động (Attack Button - Kích thước lớn nhất Ø72px):**
     - Cho phép người chơi chủ động vung đòn / bắn đòn tấn công theo hướng Joystick đang chỉ (hoặc theo hướng nhân vật quay mặt).
     - Khi bấm: Kích hoạt hoạt ảnh vung vũ khí `play_attack_animation()`, tạo đòn chém/bắn tức thì kèm hiệu ứng âm thanh vung kiếm/chày.
     - Đồng bộ phím nóng bàn phím: Phím `J` hoặc Click chuột trái (`LMB`).
   - **Nút Lướt Né Chiêu (Dash Button - Kích thước Ø56px):**
     - Lướt nhanh về phía trước một khoảng 180px, tạo hiệu ứng bóng mờ (Afterimage trail), miễn nhiễm sát thương (i-frame) trong 0.25 giây.
     - Hồi chiêu 2.0 giây (có vòng tròn phủ mờ Cooldown mờ dần).
     - Đồng bộ phím nóng: Phím `Space` hoặc `Shift`.
   - **Nút Chiêu Nộ Tối Thượng (Ultimate Button - Kích thước Ø60px):**
     - Tích lũy khi đánh bại quái vật (Thanh nộ 0% -> 100%).
     - Khi đầy 100%: Nút phát sáng hiệu ứng lửa vàng lung linh, người chơi nhấn vào sẽ kích hoạt chiêu "Sấm Sét Hư Không / Cuồng Bạo", tiêu diệt quái diện rộng và tăng 50% tốc đánh trong 5 giây.
     - Đồng bộ phím nóng: Phím `F` hoặc `E`.

3. **Tùy Chọn Ẩn/Hiện Trong Cài Đặt:**
   - Trong Menu Settings, thêm nút chuyển đổi: `[Bật/Tắt Phím Ảo Trên Màn Hình]`. Người chơi chơi trên PC có thể ẩn đi nếu muốn góc nhìn thoáng, hoặc bật lên bất cứ lúc nào.

---

## 3. Tổng Hợp Danh Mục & Đặc Tả Kỹ Thuật Toàn Bộ Assets Cần Thiết

Dưới đây là bảng phân loại và kiểm kê chi tiết số lượng tài nguyên (**Asset Inventory**) cần có cho toàn bộ dự án để đạt độ hoàn thiện cao nhất:

### 3.1. Tổng Kết Định Lượng (Số Lượng Cụ Thể)

| Phân Loại Asset | Hiện trạng trong repository | Còn cần cho các thay đổi hiện tại |
| :--- | :--- | :--- |
| **1. Sprite Nhân Vật** | Đủ asset cho 4 nhân vật | Không cần ảnh mới |
| **2. Sprite Kẻ Địch & Boss** | Có basic, monster, fast, ranged, bullet, boss, pet | Không cần ảnh mới |
| **3. Sprite Vũ Khí & FX** | Có vũ khí cơ bản và đạn; hiệu ứng tiến hóa/ultimate có thể dựng bằng code | Không bắt buộc thêm |
| **4. Pickups** | Có EXP, coin, meat, magnet, bomb, chest | Không cần ảnh mới |
| **5. Touch Controls UI** | Có joystick base/knob, attack/dash và icon ultimate (`btn_utilmate.png`) | Không cần ảnh mới; tên file icon ultimate cần giữ khớp code |
| **6. UI hệ thống/cửa hàng** | Có icon talent; panel pause/shop dựng bằng Control/StyleBox | Không cần ảnh mới |
| **7. SFX** | Có fanfare thắng và một hiệu ứng âm thanh hiện hữu | Các SFX tấn công/nhặt đồ chuyên biệt chưa có; không tự tạo file mới |
| **8. BGM** | Có `assets/music/background_music.ogg` | Chưa có BGM riêng cho menu/boss |
| **Tổng** | Không dùng tổng 56 asset cũ vì cách đếm trùng/thiếu không nhất quán | Đối chiếu file theo nhóm khi bổ sung asset mới |

---

### 3.2. Bảng Chi Tiết Từng Loại Asset & Đặc Tả Kỹ Thuật

#### Danh Mục 1: Nhân Vật Chơi Được (Characters)
*Phong cách: 2D Cartoon / Pixel-art bán hiện đại, màu sắc tươi sáng, nền trong suốt RGBA.*

| STT | Tên Asset | Kích Thước | Định Dạng | Mô Tả & Sử Dụng | Trạng Thái |
| :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | `player_default` (Lil' Boy Domixi) | 64x64 / 128x128 | PNG | Nhân vật mặc định, đủ frame idle, run, attack, jump | **Đã có** |
| 2 | `player_red_hair` (Chiến Binh Đỏ) | 64x64 / 128x128 | PNG | Nhân vật cận chiến, máu trâu, sát thương chày | **Đã có** |
| 3 | `player_mage_vu` (Pháp Sư Vũ) | 64x64 / 128x128 | PNG | Nhân vật cầm điện thoại/phép thuật, áo choàng tím | **Đã có** |
| 4 | `player_sniper` (Xạ Thủ Mía) | 64x64 / 128x128 | PNG | Nhân vật đeo kính ngắm, chuyên đạn tầm xa | **Đã có** |

#### Danh Mục 2: Kẻ Địch & Boss (Enemies & Bosses)
*Yêu cầu: Độ tương phản cao so với hình nền để người chơi dễ quan sát và né tránh.*

| STT | Tên Asset | Kích Thước | Định Dạng | Mô Tả & Hành Vi AI | Trạng Thái |
| :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | `enemy_basic` (Quái thường / Zombie) | 48x48 | PNG | Di chuyển vừa phải, bao vây số lượng đông | **Đã có** |
| 2 | `enemy_monster1` (Quái đột biến) | 64x64 | PNG | Máu nhiều hơn, đi lắt léo | **Đã có** |
| 3 | `enemy_fast` (Chó săn / Dơi Hư Không) | 40x40 | PNG | Kích thước nhỏ, tốc độ di chuyển nhanh x1.5 | **Đã có** |
| 4 | `enemy_ranged` (Quái Bắn Xa / Cung Thủ) | 48x48 | PNG | Đứng giữ khoảng cách và bắn đạn vào người chơi | **Đã có** |
| 5 | `projectile_enemy` (Cầu Lửa / Gai Độc) | 24x24 | PNG | Viên đạn do quái tầm xa bắn ra | **Đã có** |
| 6 | `boss_void_king` (Trùm Hư Không) | 128x128 | PNG | Kích thước khổng lồ, oai vệ, có hào quang đỏ tím | **Đã có** |
| 7 | `companion_pet` (Chó Cưng Tộc Trưởng) | 36x36 | PNG | Bạn đồng hành tự chạy nhặt ngọc EXP giúp player | **Đã có** |

#### Danh Mục 3: Vũ Khí & Đạn Kỹ Năng (Weapons & Projectiles)

| STT | Tên Asset | Kích Thước | Định Dạng | Mô Tả | Trạng Thái |
| :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | `sugarcane` (Bã mía) | 32x32 | PNG | Cây mía bắn xoay về phía trước | **Đã có** |
| 2 | `shisa` (Bình Shisa) | 32x32 | PNG | Icon và bình phun khói | **Đã có** |
| 3 | `bat` (Cái chày gỗ) | 32x32 | PNG | Chày đập cận chiến | **Đã có** |
| 4 | `shield` (Khiên phòng thủ) | 48x48 | PNG | Vòng sáng khiên bảo vệ quanh người | **Đã có** |
| 5 | `phone` (Điện thoại alo Vũ) | 32x32 | PNG | Điện thoại phát sóng âm gây sợ hãi | **Đã có** |
| 6 | `evo_gatling_cane` (Đại Bác Mía) | — | Code/FX | Tiến hóa bắn chùm, dùng sprite/đạn hiện có | **Không cần ảnh mới** |
| 7 | `evo_thunder_bat` (Chày Sấm Sét) | — | Code/FX | Tăng sát thương/tốc độ đòn chày | **Không cần ảnh mới** |
| 8 | `evo_toxic_smoke` (Bão Khói Tím) | — | Code/FX | Tăng vùng ảnh hưởng và sát thương Shisa | **Không cần ảnh mới** |
| 9 | `ultimate_nova` (Sóng Sốc Nộ Chiêu) | — | Code/FX | Vùng ultimate dùng hiệu ứng runtime | **Không cần ảnh mới** |

#### Danh Mục 4: Vật Phẩm Tương Tác Trên Sàn (Pickups & Collectibles)
*Yêu cầu: Có hiệu ứng nhấp nháy hoặc xoay nhẹ để kích thích người chơi chạy lại nhặt.*

| STT | Tên Asset | Kích Thước | Định Dạng | Tác Dụng Trong Game | Trạng Thái |
| :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | `exp_gem` (Ngọc kinh nghiệm xanh) | 24x24 | PNG | Tăng thanh EXP lên cấp | **Đã có** |
| 2 | `gold_coin` (Đồng tiền vàng) | 24x24 | PNG | Dùng mua nhân vật & nâng cấp vĩnh viễn | **Đã có** |
| 3 | `pickup_meat` (Bình Máu / Đùi Gà) | 32x32 | PNG | Hồi phục 35 HP (không phải phần trăm máu) | **Đã có** |
| 4 | `pickup_magnet` (Nam Châm Hút Đồ) | 32x32 | PNG | Hút lập tức toàn bộ Ngọc EXP trên bản đồ | **Đã có** |
| 5 | `pickup_bomb` (Quả Bom Hủy Diệt) | 32x32 | PNG | Gây sát thương kết liễu quái thường trong scene, không ảnh hưởng boss | **Đã có** |
| 6 | `pickup_chest` (Rương Kho Báu) | 40x40 | PNG | Thưởng 60 vàng và hồi đầy máu; có thể rơi từ boss | **Đã có** |

#### Danh Mục 5: Giao Diện Phím Ảo & Nút Cảm Ứng (Touch Controls UI)
*Yêu cầu: Nền bán trong suốt (Alpha ~ 60-70%), có viền dạ quang (glow) tinh tế.*

| STT | Tên Asset | Kích Thước | Định Dạng | Mô Tả Thiết Kế | Trạng Thái |
| :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | `joystick_base.png` | 140x140 | PNG | Vòng tròn mờ bên ngoài của cần gạt Joystick | **Đã có** |
| 2 | `joystick_knob.png` | 64x64 | PNG | Núm tròn gạt tâm bên trong có vân tròn nổi bật | **Đã có** |
| 3 | `btn_attack.png` | 72x72 | PNG | Nút tròn to biểu tượng thanh kiếm/nắm đấm | **Đã có** |
| 4 | `btn_dash.png` | 56x56 | PNG | Nút tròn biểu tượng chiếc giày lướt / tia gió | **Đã có** |
| 5 | `btn_utilmate.png` | 60x60 | PNG | Icon Ultimate (tên file hiện có; code dùng đúng path) | **Đã có** |

#### Danh Mục 6: Giao Diện Hệ Thống & Cửa Hàng Vĩnh Viễn (System UI & Meta Shop)

| STT | Tên Asset | Kích Thước | Định Dạng | Mô Tả | Trạng Thái |
| :--- | :--- | :---: | :---: | :--- | :--- |
| 1 | Background Menu & Sảnh | 1280x720 | JPG/PNG | Ảnh nền sảnh chính và chọn bản đồ | **Đã có** |
| 2 | Nút Play, Quit, Settings | Custom | PNG | Các nút bấm gỗ/kim loại phong cách meme | **Đã có** |
| 3 | `icon_talent_max_hp` | 40x40 | PNG | Icon nâng cấp Máu vĩnh viễn | **Đã có** |
| 4 | `icon_talent_speed` | 40x40 | PNG | Icon nâng cấp Tốc độ di chuyển vĩnh viễn | **Đã có** |
| 5 | `icon_talent_damage`| 40x40 | PNG | Icon nâng cấp Sát thương toàn thể vĩnh viễn | **Đã có** |
| 6 | `icon_talent_pickup_range`| 40x40 | PNG | Icon nâng cấp Phạm vi hút đồ vĩnh viễn | **Đã có** |
| 7 | `icon_talent_greed` | 40x40 | PNG | Icon nâng cấp Tỉ lệ nhận vàng vĩnh viễn | **Đã có** |
| 8 | `ui_pause_panel` | — | StyleBox | Khung menu tạm dừng được dựng bằng UI Godot | **Không cần ảnh mới** |

#### Danh Mục 7: Âm Thanh Hiệu Ứng (SFX) & Nhạc Nền (BGM)
*Định dạng: WAV / OGG cho SFX độ trễ thấp; OGG loop cho nhạc nền.*

| STT | Tên File Âm Thanh | Loại | Mô Tả | Trạng Thái |
| :--- | :--- | :---: | :--- | :--- |
| 1 | `assets/music/background_music.ogg` | BGM | Nhạc nền hiện được dùng trong lượt chơi | **Đã có** |
| 2 | `scenes/ui/emand_edroff-victory-bell-success-fanfare-576275.mp3` | SFX | Fanfare chiến thắng có sẵn | **Đã có** |
| 3 | `bgm_menu.ogg` | BGM | Nhạc nền sảnh chờ thư giãn, vui nhộn | **Cần thêm mới** |
| 4 | `bgm_boss.ogg` | BGM | Nhạc nền căng thẳng kịch tính khi Boss xuất hiện | **Cần thêm mới** |
| 5 | `sfx_attack_swing.wav` | SFX | Tiếng vút gió vung chày / chém kiếm | **Cần thêm mới** |
| 6 | `sfx_dash.wav` | SFX | Tiếng lướt gió tốc độ cao khi bấm Dash | **Cần thêm mới** |
| 7 | `sfx_ultimate.wav` | SFX | Tiếng sấm rền sấm sét khi nổ chiêu Nộ | **Cần thêm mới** |
| 8 | `sfx_enemy_hit.wav` | SFX | Tiếng va chạm "bốp / chát" khi quái ăn đòn | **Cần thêm mới** |
| 9 | `sfx_gem_pickup.wav`| SFX | Tiếng keng keng vui tai khi hút ngọc EXP | **Cần thêm mới** |
| 10| `sfx_coin_pickup.wav`| SFX | Tiếng tiền xu rơi rủng rỉnh | **Cần thêm mới** |
| 11| `sfx_bomb_explode.wav`| SFX | Tiếng nổ rền vang khi nhặt quả Bom sàn | **Cần thêm mới** |
| 12| `sfx_level_up.wav` | SFX | Tiếng chuông thăng cấp rạng rỡ | **Cần thêm mới** |
| 13| `sfx_boss_warning.wav`| SFX | Còi báo động hú giật gân khi Boss sắp tới | **Cần thêm mới** |
| 14| `sfx_game_over.wav` | SFX | Âm thanh u ám báo hiệu bị hạ gục | **Cần thêm mới** |

---

## 4. Phương Án Tạo Lập & Tích Hợp Assets

Trong các sửa đổi hiện tại không tạo ảnh mới:
1. Dùng lại sprite nhân vật/quái/vật phẩm/joystick và icon đã có trong `assets/`.
2. Dùng `Control`, `StyleBox`, vẽ trực tiếp bằng Godot cho panel, hazard và hiệu ứng kỹ năng; đảm bảo đường dẫn icon Ultimate là `assets/sprites/ui/btn_utilmate.png`.
3. Âm thanh chỉ phát từ file đã có và đi qua các bus `BG`/`DR`; các SFX chuyên biệt còn thiếu cần được bổ sung riêng khi có nguồn âm thanh phù hợp.

---

## 5. Trạng Thái Sau Đợt Hoàn Thiện

- **Đã nối/hoàn thiện trong project:** touch HUD và tùy chọn ẩn/hiện; mouse/keyboard action; dash và ultimate theo thông số; rage từ hạ quái; hiệu lực 5 talent; tiến hóa 5 vũ khí theo max level + passive; map hazards/spawn profile; quest; achievements có lưu/thưởng một lần; screen shake; audio manager dùng file hiện có; save/load settings/profile; sửa icon path.
- **Còn cần play-test:** kiểm tra tương tác UI/cảm ứng trên thiết bị thật, cân bằng map/quest/evolution và xác minh toàn bộ vòng đời profile.
- **Còn ngoài phạm vi asset hiện có:** SFX chuyên biệt cho attack/dash/nhặt đồ/game over và nhạc menu/boss; chưa tạo hoặc tải thêm âm thanh.
- **Còn lại về sản phẩm:** nội tại/kỹ năng riêng từng nhân vật và FSM rõ ràng cho AI chưa được triển khai trong đợt này.
- **Validation:** chưa có Godot executable trong môi trường hiện tại; cần mở project bằng Godot 4.7 để chạy import/startup và smoke-test. Không tuyên bố đạt 60 FPS nếu chưa benchmark.
