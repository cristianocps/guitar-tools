## 1. Setup

- [x] 1.1 Baixar e incluir `guitar.json` do `chords-db` em `assets/chords/`
- [x] 1.2 Registrar o asset em `pubspec.yaml`
- [x] 1.3 Criar estrutura `lib/features/training/chords/` com subpastas `learn`, `challenge`, `sequence`
- [x] 1.4 Criar estrutura `lib/core/chords/` para modelos, parser e renderer

## 2. Modelos e parser de acordes

- [x] 2.1 Criar `ChordPosition` com frets, fingers, barres, baseFret e midi
- [x] 2.2 Criar `Chord` com key, suffix e lista de posições
- [x] 2.3 Criar `ChordsDbParser` para carregar e parsear `assets/chords/guitar.json`
- [x] 2.4 Criar `ChordRepository` para buscar acordes por key/suffix e listar por nível
- [x] 2.5 Adicionar testes unitários para o parser e busca de acordes

## 3. Renderização do diagrama

- [x] 3.1 Criar `ChordDiagramPainter` desenhando cordas, trastes, bolinhas e números de dedos
- [x] 3.2 Adicionar suporte a pestanas (barres) no painter
- [x] 3.3 Mostrar "O" e "X" para cordas abertas e mudas
- [x] 3.4 Criar widget `ChordDiagram` reutilizável
- [x] 3.5 Adicionar testes de widget/golden para o diagrama

## 4. Modo Aprender

- [x] 4.1 Criar `ChordLearnController` com som de referência e validação por pitch
- [x] 4.2 Tocar notas do acorde individualmente e em conjunto via `ToneGenerator`
- [x] 4.3 Validar execução do usuário com `PitchChallengeValidator` considerando janela de tempo
- [x] 4.4 Criar tela `ChordLearnScreen` com diagrama e feedback
- [x] 4.5 Permitir alternar entre posições do mesmo acorde

## 5. Modo Desafio

- [x] 5.1 Criar catálogo de níveis de acordes (abertos, barra, 7ª, etc.)
- [x] 5.2 Criar `ChordChallengeController` para sortear acordes e validar
- [x] 5.3 Implementar timer por acorde no desafio
- [x] 5.4 Criar tela `ChordChallengeScreen` com placar e feedback
- [x] 5.5 Calcular estrelas e persistir progresso via `TrainingProgressRepository`

## 6. Modo Sequência

- [x] 6.1 Criar catálogo de progressões por nível
- [x] 6.2 Criar `ChordSequenceController` sincronizando metrônomo e troca de acordes
- [x] 6.3 Validar troca de acorde dentro da janela do compasso
- [x] 6.4 Criar tela `ChordSequenceScreen` mostrando o acorde atual e o próximo
- [x] 6.5 Aumentar BPM entre níveis progressivamente

## 7. Navegação e integração

- [x] 7.1 Criar `ChordsHomeScreen` com cards para Aprender, Desafio e Sequência
- [x] 7.2 Criar `ChordListScreen` para listar acordes por nível
- [x] 7.3 Adicionar entrada "Acordes" no `TrainingHomeScreen`
- [x] 7.4 Conectar desbloqueio de níveis com `UserProgress`

## 8. Testes e qualidade

- [ ] 8.1 Escrever testes unitários para controllers de acordes
- [ ] 8.2 Escrever testes de widget para telas com mocks de áudio
- [x] 8.3 Rodar `flutter pub get`, `flutter analyze` e `flutter test`
- [x] 8.4 Resolver warnings do analyzer e falhas de teste
