# Rick & Morty Episodes

Aplicação Flutter offline-first para consultar um episódio da [Rick and Morty API](https://rickandmortyapi.com/documentation#get-a-single-episode) pelo número e listar seus personagens em ordem alfabética.

## Comportamento

- Informe o número do episódio e toque em **Buscar**.
- O episódio e todos os personagens são carregados pela API REST JSON.
- O resultado completo é salvo localmente por número de episódio.
- O episódio concluído é salvo localmente mesmo quando algum personagem falha; os personagens disponíveis permanecem no cache para uso offline e nova tentativa.
- Em uma nova consulta, o cache aparece imediatamente e é atualizado em segundo plano.
- Sem conexão, a última versão salva continua disponível.
- Os personagens são carregados em lote por `Stream`, com loading e erro tratados individualmente; há fallback para as URLs separadas quando necessário.
- Respostas HTTP 429 são repetidas com backoff exponencial limitado e suporte ao header `Retry-After`.
- Imagens de personagens usam `CachedNetworkImage` com cache persistente e fallback visual.

## Organização

```text
lib/
├── core/di/                         # composição das dependências
└── features/episode/
    ├── data/                        # fontes remota/local, models e repository
    ├── domain/                      # entidades e contratos
    └── presentation/               # estado, widgets, tela e ChangeNotifier
packages/character/                 # domínio e requests de personagens
packages/network/                   # cliente HTTP/JSON reutilizável
```

Os testes específicos de cada package ficam em `packages/<nome>/test`; a
pasta `test/` na raiz contém somente testes da aplicação, organizados por
`core` e `features/episode/<camada>`, sem arquivos diretamente na sua raiz.

O estado da tela é gerenciado por `EpisodeViewModel` (`ChangeNotifier`) e o campo do número usa `ValueNotifier`. A camada de domínio não conhece Flutter, HTTP ou persistência. O package `character` expõe eventos tipados de carregamento para que um erro em um personagem não interrompa o stream dos demais.

A orquestração entre episódio e personagens fica exclusivamente no
`EpisodeRepositoryImpl`. As regras de fronteiras e responsabilidades estão
documentadas em `AGENTS.md`.

## Executar

```bash
make get
make run-dev
```

As entradas disponíveis são `lib/main_dev.dart`, `lib/main_stg.dart` e
`lib/main_prd.dart` (também mantida em `lib/main.dart` para produção). Os
ambientes `dev` e `stg` carregam fixtures locais em
`assets/fixtures/<ambiente>`; `prd` usa a API oficial.

```bash
make run-stg
make run-prd
```

Os comandos de execução usam `--dart-define=APP_ENV=...` e permitem passar
outros parâmetros ao Flutter conforme necessário. Os principais atalhos do
dia a dia estão disponíveis no `Makefile`, incluindo `make analyze`,
`make test`, `make dart-test`, `make format` e `make clean`.

## Validar

```bash
make analyze
make test
```

`make test` executa a suíte da aplicação e também as suítes isoladas de
`packages/network` e `packages/character`.

## Regras para agentes

As regras de navegação, arquitetura, limites e validação obrigatória estão em
[`AGENTS.md`](AGENTS.md). Leia esse arquivo antes de qualquer alteração no
projeto.
