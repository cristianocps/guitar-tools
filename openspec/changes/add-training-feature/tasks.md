## 1. Setup

- [x] 1.1 Adicionar dependências `hive`, `hive_flutter` e `hive_generator` (dev) no `pubspec.yaml`
- [x] 1.2 Inicializar Hive no `main.dart` antes de `runApp`
- [x] 1.3 Criar estrutura de diretórios `lib/features/training/` com subpastas `ear_training`, `fretboard_trainer`, `rhythm_exercises`, `technique_exercises`
- [x] 1.4 Criar estrutura `lib/core/training/` para modelos, repositórios e lógica compartilhada

## 2. Persistência e modelos

- [x] 2.1 Criar `ExerciseDefinition` com campos id, type, level, title, description, parameters, unlockedByDefault
- [x] 2.2 Criar `ExerciseAttempt` com campos id, exerciseId, score, stars, accuracy, durationMs, timestamp
- [x] 2.3 Criar `UserProgress` com mapa exerciseId → melhores estrelas e flag desbloqueado
- [x] 2.4 Implementar `TypeAdapter` do Hive para cada modelo
- [x] 2.5 Criar `TrainingProgressRepository` com métodos para salvar tentativa, carregar progresso e desbloquear níveis
- [x] 2.6 Criar `StarRating` para calcular estrelas (1: 60–74%, 2: 75–89%, 3: ≥90%)

## 3. Extensões de teoria musical

- [x] 3.1 Adicionar enum `Interval` com semitons e nomes (2ª, 3ª, 4ª, 5ª, 6ª, 7ª, 8ª)
- [x] 3.2 Adicionar `ScaleType.pentatonicMajor` e `ScaleType.pentatonicMinor` em `scale.dart`
- [x] 3.3 Adicionar utilitário para gerar notas de um intervalo a partir de uma tônica
- [x] 3.4 Adicionar mapeamento corda/casa → nota para afinação padrão de guitarra

## 4. Core de áudio

- [x] 4.1 Criar `ToneGenerator` para gerar WAV PCM de notas senoidais com duração configurável
- [x] 4.2 Criar `RhythmDetector` que escuta PCM e emite eventos de onset com threshold de noise gate
- [x] 4.3 Criar `PitchChallengeValidator` para comparar pitch detectado com pitch class esperada
- [x] 4.4 Criar provider Riverpod para estado de áudio dos exercícios

## 5. Ear Training

- [x] 5.1 Criar `EarTrainingLevelGenerator` para gerar desafios de intervalos por nível
- [x] 5.2 Criar tela `EarTrainingScreen` com área de desafio e controles (tocar, repetir, dica)
- [x] 5.3 Criar `EarTrainingExerciseController` para gerenciar rounds, validação e pontuação
- [x] 5.4 Integrar `ToneGenerator` para tocar intervalos de referência
- [x] 5.5 Integrar `PitchChallengeValidator` para validar resposta do usuário

## 6. Fretboard Trainer

- [x] 6.1 Criar `FretboardChallengeGenerator` para notas por corda/casa e sequências de escala
- [x] 6.2 Criar widget visual simplificado do braço da guitarra destacando corda/casa alvo
- [x] 6.3 Criar tela `FretboardTrainerScreen` com modos "Localize a nota" e "Scale Runner"
- [x] 6.4 Criar `FretboardExerciseController` para gerenciar rounds e validação
- [x] 6.5 Integrar pitch detection e metrônomo no modo Scale Runner

## 7. Rhythm Exercises

- [x] 7.1 Criar catálogo de padrões rítmicos por nível (seminimas, colcheias, sincopas, tercinas)
- [x] 7.2 Criar `RhythmExerciseController` para sincronizar metrônomo e onsets detectados
- [x] 7.3 Criar tela `RhythmExercisesScreen` com visualização do padrão e feedback de batidas
- [x] 7.4 Integrar `RhythmDetector` e calcular porcentagem de batidas dentro da tolerância

## 8. Technique Exercises

- [x] 8.1 Criar catálogo de exercícios de digitação (escalas/arpégios por nível)
- [x] 8.2 Criar `TechniqueExerciseController` para sequência de notas, metrônomo e validação
- [x] 8.3 Criar tela `TechniqueExercisesScreen` com exibição da sequência e progresso
- [x] 8.4 Integrar `PitchChallengeValidator` e `MetronomeEngine`

## 9. Navegação e integração

- [x] 9.1 Adicionar aba "Treino" na `BottomNavigationBar` do app
- [x] 9.2 Criar `TrainingHomeScreen` com cards para os quatro módulos
- [x] 9.3 Criar `ExerciseListScreen` reutilizável para listar níveis de cada módulo
- [x] 9.4 Conectar desbloqueio de níveis com `UserProgress` e repositório

## 10. Testes e qualidade

- [x] 10.1 Escrever testes unitários para `StarRating`, `Interval` e geradores de desafio
- [x] 10.2 Escrever testes unitários para `ToneGenerator` e `RhythmDetector`
- [x] 10.3 Escrever testes de widget para telas de treino com mocks de áudio
- [x] 10.4 Rodar `flutter pub get`, `flutter analyze` e `flutter test`
- [x] 10.5 Resolver quaisquer warnings do analyzer e falhas de teste
