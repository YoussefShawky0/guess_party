# Waiting Room Refactoring Documentation

## Overview
تم تقسيم ملف `waiting_room_view.dart` (233 سطر) إلى عدة widgets منفصلة لتحقيق clean code architecture.

## New Widgets Structure

### 1. `room_lifecycle_manager.dart`
**المسؤولية**: إدارة دورة حياة التطبيق والتعامل مع حالات الخلفية/المقدمة

**Features**:
- `WidgetsBindingObserver` للاستماع لتغيرات حالة التطبيق
- تحديث `is_online` للاعب عند الانتقال للخلفية/المقدمة
- تنظيف البيانات عند الخروج (dispose)
- استخدام `PopScope` للتعامل مع زر الرجوع
- `InheritedWidget` لمشاركة بيانات اللاعب عبر widget tree

**Parameters**:
- `roomId`: معرف الغرفة
- `child`: الـ widget الفرعي
- `onPlayerIdentified`: callback عند التعرف على اللاعب

### 2. `room_status_listener.dart`
**المسؤولية**: الاستماع لتغييرات حالة الغرفة في الوقت الفعلي

**Features**:
- استخدام `Supabase Realtime` للاستماع لتحديثات جدول `rooms`
- التعامل مع حالة `finished` (المضيف غادر)
- التعامل مع حالة `active` (اللعبة بدأت)
- إظهار رسائل Snackbar للمستخدم
- التنقل التلقائي عند تغيير الحالة

**Parameters**:
- `roomId`: معرف الغرفة
- `builder`: دالة بناء الـ child widget

### 3. `waiting_room_app_bar.dart`
**المسؤولية**: عرض شريط التطبيق العلوي مع زر الرجوع

**Features**:
- زر رجوع مع معالجة خاصة
- استدعاء `leaveRoomSession` عند الضغط
- التنقل للصفحة الرئيسية
- يظهر للجميع (host و players)

**Parameters**:
- `currentPlayerId`: معرف اللاعب الحالي
- `roomId`: معرف الغرفة
- `isHost`: هل اللاعب host؟
- `roomCubit`: reference للـ cubit

### 4. `waiting_room_body.dart`
**المسؤولية**: عرض محتوى الصفحة الرئيسي

**Features**:
- `RoomCodeCard`: عرض كود الغرفة
- `ShareRoomButton`: زر مشاركة الكود
- `PlayersList`: قائمة اللاعبين
- `StartGameButton`: زر بدء اللعبة (للـ host فقط)
- Responsive design (tablet/mobile)

**Parameters**:
- `roomId`: معرف الغرفة
- `roomCode`: كود الغرفة
- `isHost`: هل اللاعب host؟
- `playerCount`: عدد اللاعبين
- `onStartGame`: callback عند بدء اللعبة

## Main View Structure

```dart
WaitingRoomView (StatelessWidget)
  └─ BlocProvider (RoomCubit)
      └─ WaitingRoomContent (StatefulWidget)
          └─ RoomLifecycleManager
              └─ RoomStatusListener
                  └─ Scaffold
                      ├─ WaitingRoomAppBar
                      └─ BlocConsumer<RoomCubit>
                          └─ WaitingRoomBody
```

## Benefits of Refactoring

### 1. **Separation of Concerns**
- كل widget له مسؤولية واحدة واضحة
- سهولة الصيانة والتطوير

### 2. **Reusability**
- يمكن إعادة استخدام الـ widgets في أماكن أخرى
- مثال: `RoomStatusListener` يمكن استخدامه في شاشة اللعبة

### 3. **Testability**
- كل widget يمكن اختباره بشكل منفصل
- Unit tests و Widget tests أسهل

### 4. **Readability**
- الكود أصبح أكثر وضوحًا
- سهل الفهم للمطورين الجدد

### 5. **Maintainability**
- التعديلات على feature معين لا تؤثر على الباقي
- تقليل احتمالية الأخطاء

## Code Reduction

**Before**: 233 lines in one file
**After**: 
- `waiting_room_view.dart`: ~130 lines
- `room_lifecycle_manager.dart`: ~150 lines
- `room_status_listener.dart`: ~90 lines
- `waiting_room_app_bar.dart`: ~47 lines
- `waiting_room_body.dart`: ~55 lines

## Next Steps

1. ✅ Test the refactored code
2. ✅ Verify all functionality works
3. ⏳ Apply same pattern to other screens
4. ⏳ Add more unit tests
5. ⏳ Implement game screen
