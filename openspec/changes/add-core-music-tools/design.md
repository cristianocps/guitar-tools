## Context

Projeto greenfield: não há código existente. O objetivo é construir um app mobile multiplataforma (iOS e Android) reunindo três utilitários para músicos — afinador, visualizador de campo harmônico e metrônomo — com forte apelo visual e visualizações interativas em tempo real. Os utilitários compartilham duas necessidades técnicas centrais: (1) captura e análise de áudio do microfone e (2) animações fluidas e precisas. Este documento define as decisões de arquitetura que sustentam os requisitos detalhados nos specs e as tarefas de implementação.

Ambiente de desenvolvimento disponível: Flutter `3.19.0-stable` e Node `21` gerenciados via `mise`. Esta é a stack-alvo inicial.

## Goals / Non-Goals

**Goals:**
- Definir uma arquitetura de app Flutter modular, com pacotes de feature isolados e um núcleo compartilhado (design system + serviços).
- Estabelecer um serviço de áudio reutilizável (captura de microfone + detecção de pitch) consumido pelo afinador e pelo visualizador de campo harmônico.
- Garantir temporização precisa para o metrônomo e baixa latência para análise de áudio.
- Escolher o motor de animação/visualização capaz de renderizar cordas vibrantes, círculo harmônico e pêndulo a 60 fps.
- Prover um módulo puro de teoria musical (notas, semitons, escalas, acordes, graus do campo harmônico) reutilizável e testável.

**Non-Goals:**
- Backend, contas de usuário, sincronização em nuvem ou telemetria (tudo on-device nesta versão).
- Suporte a instrumentos além de violão/guitarra de 6 cordas na afinação guiada (o modo cromático continua genérico).
- Detecção de acordes/polifonia (apenas pitch monofônico).
- Funcionalidades pagas, anúncios ou integrações com serviços de streaming.
- Exportação de áudio, gravação ou compartilhamento.

## Decisions

### 1. Stack: Flutter (Dart), single codebase iOS + Android
**Escolha:** Flutter 3.19.
**Razão:** O requisito central é "visualmente deslumbrante" com animações interativas customizadas (cordas, círculo, pêndulo). O `CustomPainter` + `AnimationController` do Flutter permite desenho vetorial e animação de alta performance a partir de um único código-base para iOS e Android. Flutter já está configurado no ambiente (`mise`).
**Alternativas consideradas:**
- *React Native + Expo:* bom ecossistema, mas animações customizadas via Skia/Reanimated adicionam complexidade; DSP de áudio em JS é menos determinístico.
- *Nativo (Swift/Kotlin):* máxima performance de áudio, porém duplica esforço e mantém duas bases de código.
- *Kotlin Multiplatform:* viável, mas ecossistema de UI/animação menos maduro que Flutter para este caso.

### 2. Arquitetura: feature-first + núcleo compartilhado
**Escolha:** Estrutura de pacotes em `lib/`:
- `core/theme`, `core/design_system` (cores, tipografia, widgets base, animações reutilizáveis).
- `core/audio` (serviço de captura de microfone + pipeline de detecção de pitch).
- `core/music_theory` (módulo puro: notas, semitons, escalas, acordes, campo harmônico).
- `core/metronome_engine` (scheduler de tempo preciso).
- `features/tuner`, `features/harmonic_field`, `features/metronome` (UI + integração com os serviços).
**Razão:** isola responsabilidades, facilita testes unitários do domínio (teoria musical, pitch, timing) e permite reutilizar os serviços entre features. A UI fica desacoplada da lógica de áudio.

### 3. Detecção de pitch: DSP em Dart sobre stream PCM
**Escolha:** Capturar frames PCM do microfone (plugin multiplataforma de áudio) e executar um algoritmo de detecção de pitch em Dart — **YIN** (com threshold configurável) — complementado por suavização temporal e noise gate.
**Razão:** YIN oferece bom equilíbrio de precisão e custo para pitch monofônico de instrumentos; implementá-lo em Dart mantém toda a lógica em uma camada testável e multiplataforma, sem depender de código nativo por instrumento.
**Alternativas consideradas:**
- *TarsosDSP (Android only):* excelente, porém não portável para iOS.
- *Platform channels com DSP nativo:* maior precisão potencial, mas duplica implementação e dificulta testes.
- *FFT pura com pico espectral:* simples, porém imprecisa para a fundamental de instrumentos ricos em harmônicos.

### 4. Estado e reatividade: Riverpod
**Escolha:** Riverpod para injeção de dependência e estado (stream de pitch, estado do metrônomo, configurações).
**Razão:** testável, type-safe e lida bem com streams (necessário para o áudio contínuo).
**Alternativas:** Provider (mais simples, menos robusto para streams), Bloc (mais verboso), GetX (opinião de arquitetura excessiva).

### 5. Metrônomo: scheduler orientado por clock de áudio/isolate
**Escolha:** O motor do metrônomo agenda ticks a partir de um relógio de alta resolução (isolate dedicado e/ou callback do buffer de áudio) com correção de drift, em vez de `Timer`/`Future.delayed`.
**Razão:** timers de Dart sofrem jitter de event loop, inaceitável para tempo musical. Um scheduler isolado com lookahead produz timing estável. O som do clique é gerado por um oscilador/amostra curta para latência mínima.
**Alternativas:** `Timer.periodic` (rejeitado por jitter), animação como fonte de tempo (rejeitada: a animação segue o motor, não o contrário).

### 6. Visualizações: CustomPainter + AnimationController
**Escolha:** Renderizar cordas vibrantes, círculo de campo harmônico e pêndulo com `CustomPainter`, animados por `AnimationController` (vsync), com a UI consumindo o estado dos serviços.
**Razão:** controle total do visual e performance adequada; reutiliza o design system. A animação é _slave_ do estado (ex.: a corda reage ao pitch detectado; o pêndulo segue o motor do metrônomo).
**Alternativas:** *Rive* para animações complexas (mantida como opção futura para microinterações), *Lottie* (inadequado para dados em tempo real).

### 7. Teoria musical como módulo puro
**Escolha:** `core/music_theory` implementa notas (com oitavas), distância em semitons, escalas maior/menor (e modos), construção de acordes (tríades/tétrades) e derivação do campo harmônico (graus I–VII com seus acordes) a partir de uma tônica.
**Razão:** o afinador produz uma nota; o visualizador consome essa nota para gerar o campo harmônico. Centralizar a teoria evita duplicação e torna o comportamento testável independentemente de áudio/UI. Frequência de referência A4 = 440 Hz por padrão (configurável no futuro).

## Risks / Trade-offs

- **[Precisão da detecção de pitch em dispositivos ruidosos/oitavas erradas]** → Mitigação: YIN com threshold ajustado, janela de histórico com mediana/média, noise gate e histerese para estabilizar a nota exibida.
- **[Latência e taxa de amostragem variando entre iOS/Android]** → Mitigação: buffer adaptativo, solicitação de modo de baixa latência, processamento em chunks fixos; testes em dispositivos reais.
- **[Drift/jitter do metrônomo]** → Mitigação: scheduler em isolate com lookahead e correção de drift ancorada num relógio monotônico; testes de estabilidade de tempo.
- **[Disponibilidade/manutenção do plugin de microfone]** → Mitigação: isolar `core/audio` atrás de uma interface; trocar a implementação por platform channels finos se um pacote não cobrir ambas as plataformas.
- **[Permissão de microfone negada]** → Mitigação: fluxo de UI que explica o uso, estado gracioso (afinador/visualizador indisponíveis, demais features funcionam) e botão para reabrir as configurações.
- **[Consumo de bateria/CPU com análise contínua]** → Mitigação: capturar/processar áudio apenas enquanto a feature ativa estiver em primeiro plano; liberar o microfone ao sair.
- **[Flutter 3.19 vs pacotes de áudio recentes]** → Mitigação: validar compatibilidade dos pacotes escolhidos com a 3.19 antes de travar versões; elevar Flutter se necessário (decisão de tarefa inicial).

## Migration Plan

Greenfield — não há migração. Plano de bootstrap:
1. `flutter create` do app com suporte iOS+Android; travar versões; adicionar dependências e configurar permissões (`Info.plist`/`AndroidManifest.xml`).
2. Implementar `core` (theme/design_system, music_theory, audio, metronome_engine) com testes de domínio.
3. Construir as features na ordem: app-shell/navegação → metronome (sem microfone) → instrument-tuner → harmonic-field-visualizer.
Rollback por feature: cada utilitário é independente e pode ser desativado na navegação sem afetar os demais.

## Open Questions

- Pacotes exatos de captura/áudio a adotar (validar compatibilidade com Flutter 3.19 em iOS e Android) — resolvido na primeira tarefa de implementação.
- Plataforma de lançamento inicial: iOS e Android em paralelo ou Android-first? (Recomendação: Android-first para iteração rápida, com iOS em seguida.)
- A4 = 440 Hz como referência fixa nesta versão (configurável em versões futuras).
