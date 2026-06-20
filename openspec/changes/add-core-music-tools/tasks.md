## 1. Bootstrap do projeto Flutter

- [x] 1.1 Executar `flutter create` (suporte iOS + Android) na raiz do repositório e ajustar `applicationId`/`bundle id`
- [x] 1.2 Verificar compatibilidade dos pacotes de áudio com Flutter 3.19 (iOS/Android) e elevar o Flutter se necessário; registrar a decisão no README
- [x] 1.3 Adicionar dependências base: state management (Riverpod) e pacotes de captura/áudio escolhidos
- [x] 1.4 Configurar `flutter analyze`/formatador e um script de testes (`flutter test`); documentar os comandos em `AGENTS.md`
- [x] 1.5 Configurar permissões de microfone: `Info.plist` (iOS, com `NSMicrophoneUsageDescription`) e `AndroidManifest.xml` (Android, `RECORD_AUDIO`)

## 2. Núcleo: design system e tema

- [x] 2.1 Criar `core/theme` com paleta de cores, tipografia e métricas de espaçamento
- [x] 2.2 Criar `core/design_system` com widgets base e helpers de animação reutilizáveis (`AnimationController`/vsync)
- [x] 2.3 Aplicar o `ThemeData` global no `MaterialApp` e validar 60 fps em animações de exemplo

## 3. Núcleo: motor de teoria musical

- [x] 3.1 Implementar modelo de nota (classe com nome, acidente e oitava) e conversão frequência↔nota (A4 = 440 Hz)
- [x] 3.2 Implementar distância em semitons e geração de escalas maior/menor (e modos) a partir de uma tônica
- [x] 3.3 Implementar construção de acordes (tríades/tétrades) e derivação do campo harmônico (graus I–VII com acordes)
- [x] 3.4 Escrever testes unitários cobrindo escalas, acordes e campos harmônicos (ex.: campo maior de Dó, campo menor de Lá)

## 4. Núcleo: serviço de áudio e detecção de pitch

- [x] 4.1 Criar interface `AudioCaptureService` (iniciar/parar, stream de frames PCM) e implementação multiplataforma
- [x] 4.2 Implementar algoritmo de detecção de pitch YIN em Dart sobre os frames PCM, com threshold configurável
- [x] 4.3 Adicionar suavização temporal (histórico/mediana), noise gate e histerese para estabilizar a nota
- [x] 4.4 Expor um stream de "nota detectada + desvio em cents + confiança" via Riverpod
- [x] 4.5 Escrever testes unitários do YIN/suavização usando amostras senoidais de frequência conhecida

## 5. Núcleo: motor do metrônomo

- [x] 5.1 Implementar scheduler de tempo em isolate (ou clock de áudio) com lookahead e correção de drift
- [x] 5.2 Suportar BPM configurável (20–280) e assinaturas de compasso (2/4, 3/4, 4/4, 6/8) com acento no tempo 1
- [x] 5.3 Implementar geração do clique (oscilador/amostra curta de baixa latência, timbre distinto para o acento)
- [x] 5.4 Escrever teste de estabilidade de tempo (drift < 0,5% em uma sessão simulada)

## 6. App shell e navegação

- [x] 6.1 Implementar `bottom navigation` com 3 abas (Afinador, Campo Harmônico, Metrônomo) preservando o estado de cada aba
- [x] 6.2 Implementar fluxo de permissão de microfone (solicitação com justificativa, tratamento de negação, ação para abrir configurações)
- [x] 6.3 Garantir liberação do microfone/áudio ao sair da feature ou ir para segundo plano (lifecycle)

## 7. Feature: Metrônomo

- [x] 7.1 Criar tela de controle (iniciar/parar, seletor de BPM, seletor de compasso)
- [x] 7.2 Conectar a UI ao motor do metrônomo via Riverpod
- [x] 7.3 Implementar animação de pêndulo (`CustomPainter`) sincronizada com os tempos
- [x] 7.4 Validar temporização precisa e feedback sonoro/visual em dispositivo real

## 8. Feature: Afinador

- [x] 8.1 Criar tela do afinador com alternador entre modo cromático e modo por corda
- [x] 8.2 Exibir nota (com oitava), desvio em cents e indicador visual (grave/afinado/agudo) consumindo o stream de pitch
- [x] 8.3 Implementar modo por corda (seleção E2–E4) e avaliação da corda alvo
- [x] 8.4 Implementar visualização interativa das cordas (`CustomPainter`) reagindo ao pitch/corda ativa
- [x] 8.5 Validar estabilidade da leitura e estados sem permissão; testar em dispositivo real

## 9. Feature: Visualizador de campo harmônico

- [x] 9.1 Aceitar tônica via nota detectada pelo microfone e via seleção manual
- [x] 9.2 Calcular e exibir campo harmônico (maior/menor) com graus I–VII e acordes, consumindo `core/music_theory`
- [x] 9.3 Implementar visualização circular interativa (`CustomPainter`) com tônica destacada e seleção de grau (detalhes do acorde)
- [x] 9.4 Atualizar o círculo em tempo real ao mudar a tônica; testar fluidez em dispositivo real

## 10. Validação e polimento

- [x] 10.1 Rodar `flutter analyze` e `flutter test` com tudo passando
- [ ] 10.2 Testar em iOS e Android reais: latência de áudio, precisão do metrônomo e desempenho das animações
- [x] 10.3 Revisar acessibilidade (contraste, tamanhos de toque) e corrigir gargalos de CPU/bateria apontados no design
