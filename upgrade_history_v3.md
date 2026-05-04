# История обновления проекта до MLX Swift LM 3.x

## 1. Выявленные проблемы
При обновлении библиотек MLX до версии 3.x возникли следующие ошибки:
- `In expansion of macro 'hubDownloader'`: макросы загрузки стали устаревшими.
- `no such module 'MLXLMHuggingFace'`: попытка использовать модуль, которого нет в текущем составе пакетов.
- `Missing package product 'MLXLMTokenizers'`: конфликт имен целей `Tokenizers` между разными пакетами в Swift Package Manager.

## 2. Принятые решения и исправления

### Изменение API загрузки
- **Было:** Использование макросов `#hubDownloader` или старого `HubApi`.
- **Стало:** Переход на `LLMModelFactory.shared.loadContainer(from: HubClient.default, configuration: ...)`.
- **Файлы:** `LLMEngine.swift`, `EmbeddingEngine.swift`.

### Коррекция импортов
После анализа `Package.swift` репозитория `swift-hf-api-mlx` было установлено, что правильный модуль называется `MLXLMHFAPI`.
- **Исправление:** Замена `import MLXLMHuggingFace` $\to$ `import MLXLMHFAPI`.
- **Стек импортов:**
  ```swift
  import MLXHuggingFace    // Базовый клиент
  import MLXLMHFAPI        // Адаптер для MLXLM (v3.x)
  ```

### Решение проблем с зависимостями в Xcode
Для устранения конфликта `multiple packages declare targets with a conflicting name: 'Tokenizers'`:
1. Очистка кеша пакетов (`Reset Package Caches`).
2. Переустановка пакетов в строгом порядке:
   - `mlx-swift-lm`
   - `swift-tokenizers-mlx`
   - `swift-hf-api-mlx`
3. Добавление продуктов `MLXLMHFAPI`, `MLXLMTokenizers` и `MLX` в Target приложения.

## 3. Итоговый стек технологий
- **Core**: `MLXLMCommon`, `MLXLLM`, `MLX`
- **HuggingFace Bridge**: `MLXLMHFAPI` (из `swift-hf-api-mlx`)
- **Tokenizers**: `MLXLMTokenizers` (из `swift-tokenizers-mlx`)
- **Client**: `HubClient.default`
