# 📚 مرجع مشروع Guess Party

## 📖 نظرة عامة على المشروع

**Guess Party** هي لعبة حفلات جماعية (Multiplayer Party Game) مبنية بـ Flutter وSupabase. اللعبة مستوحاة من نمط "Impostor Games" حيث:

- يدخل اللاعبون غرفة باستخدام كود الغرفة
- يُختار لاعب واحد سراً ليكون "المحتال" (Impostor) الذي لا يعرف الشخصية
- يقدم اللاعبون تلميحات عن الشخصية
- يصوت اللاعبون لتحديد المحتال
- نظام نقاط يكافئ التعرف الصحيح على المحتال

---

## 🏗️ المعمارية (Architecture)

### Clean Architecture

المشروع يتبع Clean Architecture مع 3 طبقات:

```
lib/
├── core/                      # الأدوات الأساسية المشتركة
│   ├── config/               # إعدادات Supabase
│   ├── constants/            # الثوابت
│   ├── di/                   # Dependency Injection (GetIt)
│   ├── error/                # معالجة الأخطاء
│   ├── router/               # التنقل (go_router)
│   ├── theme/                # الثيمات
│   └── utils/                # أدوات مساعدة
│
├── features/                  # الميزات الرئيسية
│   ├── auth/                 # المصادقة (Guest Login)
│   │   ├── data/            # Data Layer (Models, DataSources, Repositories)
│   │   ├── domain/          # Domain Layer (Entities, Repositories, UseCases)
│   │   └── presentation/    # Presentation Layer (Cubits, Views, Widgets)
│   │
│   ├── room/                 # إدارة الغرف
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── game/                 # منطق اللعبة
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── home/                 # الشاشة الرئيسية
│
└── shared/                    # الويدجت المشتركة
    └── presentation/
```

### الأنماط المستخدمة

- **State Management**: BLoC/Cubit Pattern
- **Dependency Injection**: GetIt (injection_container.dart)
- **Routing**: go_router
- **Real-time**: Supabase Realtime Channels
- **Error Handling**: Either Pattern من dartz

---

## 🎮 سير اللعبة (Game Flow)

### 1. **المصادقة (Authentication)**

```
SplashScreen → AuthScreen → HomeView
```

- تسجيل دخول كضيف (Guest Login)
- إنشاء مستخدم مؤقت بـ anonymous auth

### 2. **إنشاء/الانضمام للغرفة**

```
HomeView → CreateRoomView/JoinRoomView → WaitingRoomView
```

- الهوست ينشئ غرفة مع إعدادات (فئة، عدد الجولات، المدة)
- اللاعبون ينضمون بكود الغرفة
- الانتظار حتى يصل العدد الكافي (4 لاعبين كحد أدنى)

### 3. **بدء اللعبة**

```
WaitingRoomView → CountdownView → GameView
```

- الهوست يضغط "Start Game"
- تحديث حالة الغرفة → 'active'
- RoomStatusListener يستمع للتحديثات عبر Realtime
- الانتقال لصفحة العد التنازلي (3-2-1-GO!)
- الانتقال لشاشة اللعبة

### 4. **الجولة (Round)**

كل جولة تمر بـ 3 مراحل:

#### أ. **مرحلة التلميحات (Hints Phase)**

- يرى اللاعبون العاديون الشخصية (مثل: محمد صلاح)
- المحتال **لا يرى** الشخصية
- كل لاعب يكتب تلميح عن الشخصية
- التلميحات تظهر للجميع في الوقت الفعلي

#### ب. **مرحلة التصويت (Voting Phase)**

- اللاعبون يصوتون على من يعتقدون أنه المحتال
- كل لاعب يختار لاعب واحد

#### ج. **مرحلة النتائج (Results Phase)**

- حساب الأصوات
- كشف هوية المحتال
- تحديث النقاط:
  - إذا تم التعرف على المحتال: كل من صوت عليه يحصل على 10 نقاط
  - إذا لم يتم التعرف عليه: المحتال يحصل على 20 نقطة
- الانتقال للجولة التالية أو إنهاء اللعبة

### 5. **نهاية اللعبة**

```
GameView → ResultsScreen → HomeView
```

- عرض الترتيب النهائي
- الفائز هو صاحب أعلى نقاط

---

## 🗄️ قاعدة البيانات (Database Schema)

### الجداول الرئيسية

#### 1. **rooms** (الغرف)

```sql
- id: UUID (Primary Key)
- host_id: UUID (مُنشئ الغرفة)
- category: TEXT (فئة الشخصيات)
- max_rounds: INTEGER (عدد الجولات)
- current_round: INTEGER (الجولة الحالية)
- room_code: TEXT (كود الغرفة - UNIQUE)
- status: TEXT ('waiting', 'active', 'finished')
- used_character_ids: JSONB (الشخصيات المستخدمة)
- max_players: INTEGER
- round_duration: INTEGER (مدة الجولة بالثواني)
```

#### 2. **players** (اللاعبون)

```sql
- id: UUID (Primary Key)
- room_id: UUID (Foreign Key → rooms)
- user_id: UUID (معرف المستخدم من Supabase Auth)
- username: TEXT
- score: INTEGER (النقاط الحالية)
- is_host: BOOLEAN
- is_online: BOOLEAN
```

#### 3. **rounds** (الجولات)

```sql
- id: UUID (Primary Key)
- room_id: UUID (Foreign Key → rooms)
- imposter_player_id: UUID (Foreign Key → players)
- character_id: UUID (Foreign Key → characters)
- round_number: INTEGER
- phase: TEXT ('hints', 'voting', 'results')
- phase_end_time: TIMESTAMP
- imposter_revealed: BOOLEAN
```

#### 4. **characters** (الشخصيات)

```sql
- id: UUID (Primary Key)
- name: TEXT (اسم الشخصية)
- emoji: TEXT
- category: TEXT (football_players, islamic_figures, daily_products)
- difficulty: TEXT ('easy', 'medium', 'hard')
- is_active: BOOLEAN
```

#### 5. **hints** (التلميحات)

```sql
- id: UUID (Primary Key)
- round_id: UUID (Foreign Key → rounds)
- player_id: UUID (Foreign Key → players)
- content: TEXT (محتوى التلميح)
- timestamp: TIMESTAMP
```

#### 6. **votes** (الأصوات)

```sql
- id: UUID (Primary Key)
- round_id: UUID (Foreign Key → rounds)
- voter_id: UUID (Foreign Key → players)
- voted_player_id: UUID (Foreign Key → players)
- timestamp: TIMESTAMP
```

### العلاقات (Relationships)

```
rooms (1) ←→ (N) players
rooms (1) ←→ (N) rounds
players (1) ←→ (N) hints
players (1) ←→ (N) votes
rounds (1) ←→ (N) hints
rounds (1) ←→ (N) votes
characters (1) ←→ (N) rounds
```

---

## 🔐 الأمان (Security - RLS Policies)

تم تفعيل Row Level Security (RLS) على جميع الجداول:

### Players Table

- **SELECT**: يمكن قراءة اللاعبين في نفس الغرفة
- **INSERT**: يمكن للمستخدم المصادق إضافة نفسه
- **UPDATE**: يمكن تحديث بياناته الخاصة فقط
- **DELETE**: الهوست يمكنه حذف اللاعبين أو اللاعب يحذف نفسه

### Rooms Table

- **SELECT**: يمكن قراءة الغرف العامة
- **INSERT**: يمكن للمستخدم المصادق إنشاء غرفة
- **UPDATE**: الهوست فقط يمكنه تحديث الغرفة
- **DELETE**: الهوست فقط يمكنه حذف الغرفة

### Rounds/Hints/Votes

- **SELECT**: اللاعبون في نفس الغرفة
- **INSERT**: اللاعبون في نفس الغرفة
- **UPDATE/DELETE**: محظور على اللاعبين العاديين

⚠️ **ملاحظة**: المصادقة المجهولة (Anonymous Auth) مُفعّلة لتسهيل تسجيل الدخول كضيف.

---

## 🔧 الملفات الأساسية

### Core Files

#### injection_container.dart

```dart
// إعداد Dependency Injection باستخدام GetIt
// يسجل جميع الـ repositories, data sources, use cases, و cubits
```

#### app_router.dart

```dart
// إعداد التنقل باستخدام go_router
// المسارات الرئيسية:
// - /                    → SplashScreen
// - /auth                → AuthScreen
// - /home                → HomeView
// - /create-room         → CreateRoomView
// - /join-room           → JoinRoomView
// - /room/:roomId/waiting → WaitingRoomView
// - /room/:roomId/countdown → CountdownView
// - /room/:roomId/game   → GameView (جديد)
```

### Feature: Room

#### RoomCubit

```dart
// إدارة حالة الغرفة
class RoomCubit extends Cubit<RoomState> {
  Future<void> createNewRoom(...)      // إنشاء غرفة جديدة
  Future<void> joinRoomWithCode(...)   // الانضمام بالكود
  Future<void> loadRoomDetails(...)    // تحميل تفاصيل الغرفة
  Future<void> loadRoomPlayers(...)    // تحميل اللاعبين
  Future<void> startGameSession(...)   // بدء اللعبة
  Future<void> exitRoom(...)           // مغادرة الغرفة
}
```

#### RoomStatusListener

```dart
// ويدجت تستمع لتحديثات الغرفة عبر Realtime
// عند تغيير status → 'active': ينتقل للعد التنازلي
// عند تغيير status → 'finished': يعود للرئيسية
```

### Feature: Game

#### GameCubit

```dart
// إدارة حالة اللعبة
class GameCubit extends Cubit<GameState> {
  Future<void> loadGameState(...)       // تحميل حالة اللعبة
  Future<void> sendHint(...)            // إرسال تلميح
  Future<void> sendVote(...)            // إرسال صوت
  Future<void> progressPhase(...)       // الانتقال للمرحلة التالية (هوست)
  Future<void> calculateRoundScores(...) // حساب النقاط (هوست)
  Future<void> createNewRound(...)      // إنشاء جولة جديدة (هوست)
  Future<void> finishGame(...)          // إنهاء اللعبة (هوست)
}
```

#### GameView

```dart
// الشاشة الرئيسية للعبة
// تعرض:
// - معلومات الجولة (الرقم، المرحلة، الوقت)
// - الشخصية (أو تحذير للمحتال)
// - واجهة حسب المرحلة (تلميحات/تصويت/نتائج)
```

---

## ⚠️ المشاكل المحلولة

### 1. ❌ StateError: "Cannot emit new states after calling close"

**السبب**:

- عند ضغط الهوست على "Start Game"، كان يتم استدعاء `loadRoomPlayers()` أثناء التنقل
- التنقل يؤدي لإغلاق RoomCubit
- العملية الـ async تحاول عمل `emit` بعد الإغلاق → crash

**الحل**:

1. ✅ حذف استدعاء `loadRoomPlayers()` من `_handleGameStarted()` في room_status_listener.dart
2. ✅ إضافة شروط حماية `if (isClosed) return;` في RoomCubit
3. ✅ حذف التنقل المزدوج من start_game_button.dart

### 2. ❌ Countdown ترجع لـ Waiting Room

**السبب**:

- بعد العد التنازلي، كان الكود ينتقل لـ `/waiting` بدلاً من `/game`
- شاشة اللعبة (game_view.dart) كانت فارغة

**الحل**:

1. ✅ تغيير وجهة countdown_view.dart من `/waiting` إلى `/game`
2. ✅ بناء game_view.dart كاملة مع واجهة للمراحل الثلاثة
3. ✅ إضافة route في app_router.dart

### 3. ❌ Game Screen غير مُنفّذ

**الحل**:
✅ تم بناء GameView مع:

- عرض معلومات الجولة والشخصية
- مرحلة التلميحات مع input field
- مرحلة التصويت مع قائمة اللاعبين
- مرحلة النتائج مع loading indicator
- تكامل كامل مع GameCubit

---

## 🚧 المشاكل المعلقة والخطوات القادمة

### 1. ⚠️ **إنشاء الجولة الأولى تلقائياً**

**المشكلة**:

- عند بدء اللعبة، تتحدث حالة الغرفة إلى 'active'
- لكن لا يتم إنشاء الجولة الأولى تلقائياً
- هذا يسبب خطأ عند محاولة تحميل GameState

**الحلول الممكنة**:

#### الحل 1: Database Trigger (موصى به)

```sql
-- إنشاء function تُنشئ الجولة الأولى
CREATE OR REPLACE FUNCTION create_first_round()
RETURNS TRIGGER AS $$
DECLARE
  v_players UUID[];
  v_imposter_id UUID;
  v_character_id UUID;
  v_room_duration INTEGER;
BEGIN
  -- التأكد من أن الحالة تغيرت إلى 'active'
  IF NEW.status = 'active' AND OLD.status = 'waiting' THEN
    
    -- جلب اللاعبين
    SELECT ARRAY_AGG(id) INTO v_players
    FROM players
    WHERE room_id = NEW.id AND is_online = true;
    
    -- اختيار محتال عشوائي
    v_imposter_id := v_players[1 + floor(random() * array_length(v_players, 1))::int];
    
    -- اختيار شخصية عشوائية من الفئة المناسبة
    SELECT id INTO v_character_id
    FROM characters
    WHERE category = NEW.category AND is_active = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- جلب مدة الجولة
    v_room_duration := NEW.round_duration;
    
    -- إنشاء الجولة الأولى
    INSERT INTO rounds (
      room_id,
      imposter_player_id,
      character_id,
      round_number,
      phase,
      phase_end_time
    ) VALUES (
      NEW.id,
      v_imposter_id,
      v_character_id,
      1,
      'hints',
      NOW() + (v_room_duration || ' seconds')::INTERVAL
    );
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء الـ trigger
CREATE TRIGGER on_room_start
AFTER UPDATE ON rooms
FOR EACH ROW
EXECUTE FUNCTION create_first_round();
```

#### الحل 2: Edge Function (Supabase)

```typescript
// functions/create-first-round/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(...)
  const { roomId } = await req.json()
  
  // Logic to create first round
  // ...
  
  return new Response(JSON.stringify({ success: true }))
})
```

#### الحل 3: من التطبيق (مؤقت)

```dart
// في countdown_view.dart بعد العد التنازلي
void _showGoAndNavigate() {
  setState(() => _countdown = -1);
  _animationController.forward(from: 0);

  Future.delayed(const Duration(milliseconds: 1500), () async {
    if (mounted) {
      // إنشاء الجولة الأولى (للهوست فقط)
      final isHost = await _checkIfHost();
      if (isHost) {
        await context.read<GameCubit>().createNewRound(
          roomId: widget.roomId,
          roundNumber: 1,
        );
      }
      
      // الانتقال للعبة
      context.go('/room/${widget.roomId}/game');
    }
  });
}
```

### 2. 🔄 **Timer للمراحل**

**المطلوب**:

- عمل countdown timer لكل مرحلة
- الانتقال التلقائي للمرحلة التالية عند انتهاء الوقت
- مزامنة التايمر بين جميع اللاعبين

**الحل**:

```dart
// في GameView
class _TimerWidget extends StatefulWidget {
  final DateTime phaseEndTime;
  final VoidCallback onTimeUp;
  
  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    _updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _updateTime();
    });
  }
  
  void _updateTime() {
    final now = DateTime.now();
    final difference = widget.phaseEndTime.difference(now);
    setState(() {
      _remainingSeconds = difference.inSeconds > 0 ? difference.inSeconds : 0;
    });
    
    if (_remainingSeconds == 0) {
      _timer?.cancel();
      widget.onTimeUp();
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('$_remainingSeconds ثانية');
  }
}
```

### 3. 🎨 **تحسين الواجهة**

**المطلوب**:

- ✨ أنيميشن للانتقال بين المراحل
- 🎯 عرض أسماء اللاعبين مع التلميحات والأصوات
- 📊 شاشة نتائج مفصلة مع رسوم بيانية
- 🏆 شاشة الفائز النهائي

### 4. 🧪 **الاختبارات**

**المطلوب**:

- Unit Tests للـ Cubits
- Widget Tests للواجهات
- Integration Tests لسير اللعبة الكامل

**مثال**:

```dart
// test/features/game/presentation/cubit/game_cubit_test.dart
void main() {
  group('GameCubit', () {
    late GameCubit cubit;
    late MockGetGameState mockGetGameState;
    
    setUp(() {
      mockGetGameState = MockGetGameState();
      cubit = GameCubit(
        getGameState: mockGetGameState,
        // ...
      );
    });
    
    test('should emit GameLoaded when loadGameState succeeds', () async {
      // arrange
      when(mockGetGameState(...))
        .thenAnswer((_) async => Right(tGameState));
      
      // act
      await cubit.loadGameState(roomId: 'test-id', currentPlayerId: 'player-id');
      
      // assert
      expect(cubit.state, isA<GameLoaded>());
    });
  });
}
```

### 5. 🔊 **الصوت والموسيقى**

**المطلوب**:

- موسيقى خلفية للعبة
- أصوات للتلميحات والأصوات
- صوت للعد التنازلي
- صوت للفوز/الخسارة

### 6. 📱 **تحسينات UX**

**المطلوب**:

- ⏳ Loading indicators أثناء العمليات
- ✅ Success/Error messages واضحة
- 🔄 Retry mechanisms عند فشل الاتصال
- 💾 حفظ الحالة عند إعادة فتح التطبيق
- 📴 Offline indicator

### 7. 🌍 **الترجمة (Localization)**

**المطلوب**:

- دعم اللغة الإنجليزية بجانب العربية
- استخدام flutter_localizations
- فصل النصوص عن الكود

---

## 📝 ملاحظات مهمة

### Best Practices المتبعة

1. ✅ **Clean Architecture**: فصل الطبقات بشكل واضح
2. ✅ **BLoC Pattern**: state management محترف
3. ✅ **Error Handling**: Either pattern للأخطاء
4. ✅ **Real-time**: Supabase Realtime للتزامن
5. ✅ **Code Organization**: هيكلة واضحة للملفات

### نصائح للتطوير

1. 🔍 **استخدم DevTools**: لمتابعة الـ state changes
2. 📊 **راقب Supabase Dashboard**: لمتابعة Real-time events
3. 🧪 **اختبر على أجهزة متعددة**: للتأكد من التزامن
4. 📝 **وثّق التغييرات**: حدّث هذا الملف عند إضافة features
5. 🔐 **راجع RLS Policies**: قبل النشر للإنتاج

### الأخطاء الشائعة وحلولها

#### خطأ: "No rows returned"

```dart
// السبب: محاولة الوصول لبيانات غير موجودة
// الحل: تحقق من وجود البيانات أولاً
final response = await client.from('rounds')
  .select()
  .eq('room_id', roomId)
  .maybeSingle(); // بدلاً من .single()

if (response == null) {
  throw Exception('No round found');
}
```

#### خطأ: "RLS policy violation"

```dart
// السبب: محاولة الوصول لبيانات محمية بـ RLS
// الحل: تأكد من أن المستخدم مصادق ولديه الصلاحيات
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  throw Exception('User not authenticated');
}
```

#### خطأ: "setState called after dispose"

```dart
// السبب: محاولة تحديث state بعد dispose الويدجت
// الحل: تحقق من mounted قبل setState
if (mounted) {
  setState(() {
    // ...
  });
}
```

---

## 🚀 كيفية التشغيل

### المتطلبات

```bash
- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- Supabase Project مع الـ schema المُعد
```

### الخطوات

1. **Clone المشروع**

```bash
git clone <repository-url>
cd guess_party
```

1. **تثبيت Dependencies**

```bash
flutter pub get
```

1. **إعداد Supabase**

```dart
// في lib/core/config/supabase_config.dart
static const supabaseUrl = 'YOUR_SUPABASE_URL';
static const supabaseAnonKey = 'YOUR_ANON_KEY';
```

1. **تشغيل قاعدة البيانات**

```bash
# في Supabase Dashboard:
# 1. افتح SQL Editor
# 2. الصق محتوى supabase_schema.sql
# 3. نفّذ الـ script
# 4. (اختياري) نفّذ database trigger للجولة الأولى
```

1. **تشغيل التطبيق**

```bash
flutter run
```

---

## 📚 المراجع والموارد

### التوثيق

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### الحزم المستخدمة

```yaml
dependencies:
  flutter_bloc: ^8.1.3          # State Management
  equatable: ^2.0.5             # Value Equality
  dartz: ^0.10.1                # Functional Programming (Either)
  get_it: ^7.6.4                # Dependency Injection
  go_router: ^12.1.1            # Routing
  supabase_flutter: ^2.0.0      # Backend
  uuid: ^4.2.1                  # UUID Generation
```

### ملفات التوثيق الأخرى

- `README.md` - نظرة عامة على المشروع
- `REFACTORING_DOCS.md` - توثيق إعادة الهيكلة
- `SECURITY_WARNINGS.md` - تحذيرات الأمان
- `supabase_schema.sql` - schema قاعدة البيانات

---

## 🤝 المساهمة

عند إضافة ميزات جديدة:

1. ✅ اتبع Clean Architecture
2. ✅ أضف Unit Tests
3. ✅ حدّث هذا الملف المرجعي
4. ✅ اكتب كود نظيف ومُعلّق
5. ✅ استخدم أسماء واضحة للمتغيرات

---

## 📄 الترخيص

[أضف معلومات الترخيص هنا]

---

**آخر تحديث**: ${DateTime.now().toString().split[' '](0)}
**الإصدار**: 1.0.0 (Beta)
**المطور**: [اسمك]

---

💡 **نصيحة**: احتفظ بهذا الملف محدثاً دائماً. هو المرجع الشامل لكل من يعمل على المشروع!
