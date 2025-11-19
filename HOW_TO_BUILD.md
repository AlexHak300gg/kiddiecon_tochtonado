# Как собрать и запустить проект KiddieCoin

## 📱 Требования

### Общие требования
- **Flutter SDK**: версия 3.0+ ([установить](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: входит в Flutter SDK
- **Git**: для клонирования репозитория

### Для Android
- **Android Studio**: 2021.1 или выше ([установить](https://developer.android.com/studio))
- **Android SDK**: версия 21+
- **Java Development Kit (JDK)**: версия 11+

### Для iOS (только на macOS)
- **Xcode**: версия 13+
- **CocoaPods**: для управления зависимостями
- **macOS**: версия 10.15+

---

## 🚀 Установка на Windows (с Android Studio)

### Шаг 1: Установка Flutter

1. Скачайте Flutter SDK с [официального сайта](https://flutter.dev/docs/get-started/install/windows)
2. Распакуйте архив в удобное место (например, `C:\flutter`)
3. Добавьте путь `C:\flutter\bin` в переменные окружения PATH:
   - Откройте "Переменные окружения" (Environment Variables)
   - Добавьте новый путь в PATH

4. Откройте новый терминал и проверьте установку:
   ```bash
   flutter --version
   flutter doctor
   ```

### Шаг 2: Установка Android Studio

1. Скачайте и установите [Android Studio](https://developer.android.com/studio)
2. При первом запуске установите Android SDK и эмулятор
3. В Android Studio откройте настройки:
   - `File > Settings > Languages & Frameworks > Flutter`
   - Установите путь к Flutter SDK

### Шаг 3: Подготовка проекта

1. Клонируйте репозиторий:
   ```bash
   git clone <ссылка-на-репозиторий>
   cd untitled12
   ```

2. Получите зависимости Flutter:
   ```bash
   flutter pub get
   ```

3. Проверьте настройку проекта:
   ```bash
   flutter doctor -v
   ```

### Шаг 4: Настройка Firebase

1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или используйте существующий
3. Добавьте Android приложение:
   - Перейдите в Project Settings > Your apps
   - Нажмите "Add app" > "Android"
   - Следуйте инструкциям для получения `google-services.json`
4. Поместите `google-services.json` в папку `android/app/`

### Шаг 5: Подключение телефона

1. Включите режим разработчика на телефоне:
   - Android 6-9: Перейдите в "Параметры > О телефоне" и нажимайте на "Номер сборки" 7 раз
   - Android 10+: Перейдите в "Параметры > О телефоне > Информация о ПО" и нажимайте на "Номер сборки" 7 раз

2. Включите отладку по USB:
   - Откройте "Параметры > Для разработчиков > Отладка по USB"

3. Подключите телефон к компьютеру через USB кабель
4. Нажмите "Разрешить" на диалоге отладки на телефоне

### Шаг 6: Сборка и запуск приложения

#### Через Android Studio:
1. Откройте проект в Android Studio
2. Выберите подключенный телефон в меню устройств
3. Нажмите зеленую кнопку "Run" (или Shift+F10)

#### Через терминал:
```bash
# Проверить подключенные устройства
flutter devices

# Запустить приложение на подключенном устройстве
flutter run

# Или на конкретном устройстве
flutter run -d <device-id>
```

---

## 🖥️ Установка на macOS (iOS и Android)

### Шаг 1: Установка Flutter на macOS

1. Скачайте Flutter SDK для macOS:
   ```bash
   # Используя Homebrew (рекомендуется)
   brew install flutter
   
   # Или вручную с https://flutter.dev/docs/get-started/install/macos
   ```

2. Проверьте установку:
   ```bash
   flutter --version
   flutter doctor
   ```

### Шаг 2: Установка зависимостей

```bash
# Установите Java (нужно для Android)
brew install java11

# Установите Xcode Command Line Tools (нужно для iOS)
xcode-select --install

# Установите Android Studio
brew install --cask android-studio

# Установите CocoaPods (нужно для iOS)
sudo gem install cocoapods
```

### Шаг 3: Подготовка проекта

1. Клонируйте репозиторий:
   ```bash
   git clone <ссылка-на-репозиторий>
   cd untitled12
   ```

2. Получите зависимости:
   ```bash
   flutter pub get
   cd ios
   pod install --repo-update
   cd ..
   ```

3. Проверьте окружение:
   ```bash
   flutter doctor -v
   ```

### Шаг 4: Подключение телефона (Android)

Следуйте инструкциям из раздела Windows для подключения Android телефона.

### Шаг 5: Подключение iPhone (iOS)

1. Подключите iPhone через USB
2. Откройте Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. В Xcode выберите физический iPhone как target
4. Нажмите кнопку "Run" или используйте Cmd+R

### Шаг 6: Запуск приложения

```bash
# Для всех устройств
flutter run

# Для iOS
flutter run -d <device-id>

# Для Android
flutter run -d <device-id>
```

---

## 🐧 Установка на Linux

### Шаг 1: Установка Flutter

```bash
# Скачайте Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.0.0-stable.tar.xz

# Распакуйте
tar xf flutter_linux_3.0.0-stable.tar.xz

# Добавьте в PATH
export PATH="$PATH:~/flutter/bin"

# Проверьте
flutter doctor
```

### Шаг 2: Установка зависимостей

```bash
# Для Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  curl \
  git \
  unzip \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev

# Для Android
sudo apt-get install -y android-sdk android-studio
```

### Шаг 3: Подготовка проекта

Следуйте инструкциям из раздела Windows для настройки Firebase и подключения устройства.

### Шаг 4: Сборка и запуск

```bash
flutter pub get
flutter run
```

---

## 📋 Разработка в Visual Studio Code

### Установка расширений

1. Откройте VS Code
2. Перейдите в Extensions (Ctrl+Shift+X)
3. Установите расширения:
   - "Flutter" (по Dart Code)
   - "Dart" (автоматически установится с Flutter)
   - "Firebase Explorer" (опционально)

### Запуск проекта в VS Code

1. Откройте папку проекта:
   ```bash
   code .
   ```

2. Откройте интегрированный терминал (Ctrl+`)

3. Получите зависимости:
   ```bash
   flutter pub get
   ```

4. Запустите приложение:
   ```bash
   flutter run
   ```

5. Или используйте Debug конфигурацию:
   - Перейдите в Debug > Run and Debug (Ctrl+Shift+D)
   - Нажмите "Run" на главной конфигурации

### Полезные команды в VS Code

- `Ctrl+Shift+P` > "Flutter: New Project" - создать новый проект
- `Ctrl+Shift+P` > "Flutter: Run" - запустить приложение
- `Ctrl+Shift+P` > "Flutter: Hot Reload" - горячая перезагрузка
- `Ctrl+Shift+P` > "Dart: Analyze" - анализ кода
- `Ctrl+Shift+P` > "Flutter: Get Packages" - получить зависимости

---

## 🏗️ Сборка для Production

### Android APK

```bash
# Подписанный APK для Play Store
flutter build apk --release

# Или создать App Bundle
flutter build appbundle --release
```

### iOS IPA

```bash
# Только на macOS
flutter build ios --release

# После сборки используйте Xcode для архивирования и экспорта
```

---

## 🐛 Возможные проблемы и их решения

### Проблема: "flutter: command not found"
**Решение**: Добавьте Flutter в PATH:
```bash
export PATH="$PATH:~/flutter/bin"
```

### Проблема: "Android SDK not found"
**Решение**: 
```bash
flutter config --android-sdk <путь-к-Android-SDK>
flutter doctor --android-licenses
```

### Проблема: "Pod install failed"
**Решение** (на macOS):
```bash
cd ios
rm Podfile.lock
pod install --repo-update
cd ..
```

### Проблема: "Gradle error"
**Решение**:
```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### Проблема: "Could not get lock /var/lib/apt/lists/lock"
**Решение** (на Linux):
```bash
sudo apt-get update
sudo apt-get install <package-name>
```

### Проблема: "Firebase configuration not found"
**Решение**: Убедитесь, что `google-services.json` находится в `android/app/` и `GoogleService-Info.plist` в `ios/Runner/`

### Проблема: "USB device not recognized"
**Решение**: 
1. Переустановите драйверы USB
2. Попробуйте другой USB кабель
3. Включите "File Transfer" режим на телефоне

---

## 📱 Проверка окружения

Чтобы убедиться, что всё установлено правильно:

```bash
flutter doctor -v
```

Должны быть отмечены:
- ✓ Flutter SDK
- ✓ Android toolchain
- ✓ Android Studio (для Android разработки)
- ✓ Xcode (для iOS разработки на macOS)
- ✓ Connected devices

---

## 🔗 Полезные ссылки

- [Official Flutter Documentation](https://flutter.dev/docs)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Android Studio Documentation](https://developer.android.com/studio/intro)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

---

## 💡 Советы для разработки

1. **Hot Reload**: Используйте `R` в терминале для быстрой перезагрузки изменений
2. **Hot Restart**: Используйте `Shift+R` для полной перезагрузки приложения
3. **Debug**: Используйте `D` для открытия меню отладки
4. **Quit**: Используйте `Q` для выхода из режима разработки

---

## 📞 Контакты и поддержка

При возникновении проблем:
1. Проверьте версии Flutter и Dart: `flutter --version`
2. Запустите `flutter doctor -v` для диагностики
3. Очистите кэш: `flutter clean`
4. Переустановите зависимости: `flutter pub get`
5. Проверьте логи: `flutter run -v`

---

**Версия**: 1.0
**Последнее обновление**: 2024
