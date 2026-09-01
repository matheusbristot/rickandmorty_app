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
packages/cache/                     # contrato de cache e implementação local
```

Os testes específicos de cada package ficam em `packages/<nome>/test`; a
pasta `test/` na raiz contém somente testes da aplicação, organizados por
`core` e `features/episode/<camada>`, sem arquivos diretamente na sua raiz.

O estado da tela é gerenciado por `EpisodeViewModel` (`ChangeNotifier`) e o campo do número usa `ValueNotifier`. A camada de domínio não conhece Flutter, HTTP ou persistência. O package `character` expõe eventos tipados de carregamento para que um erro em um personagem não interrompa o stream dos demais.

O package `cache` fornece a abstração de armazenamento chave-valor usada pela
fonte local de episódios. Sua implementação padrão usa
`SharedPreferencesAsync`; a dependência concreta fica montada no composition
root (`lib/core/di`), enquanto a feature depende apenas do contrato `Cache`.
Os episódios são persistidos como JSON por número, permitindo exibição
imediata do cache, atualização em segundo plano e funcionamento offline.

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

# build local do APK de produção usando .env.prd
make build-prd-local
```

Os comandos de execução usam `--dart-define=APP_ENV=...` e permitem passar
outros parâmetros ao Flutter conforme necessário. Os principais atalhos do
dia a dia estão disponíveis no `Makefile`, incluindo `make analyze`,
`make test`, `make dart-test`, `make format` e `make clean`.

`make build-prd-local` lê `API_BASE_URL` do arquivo local `.env.prd` e injeta
o valor como `PRD_API_BASE_URL` durante a compilação. O arquivo `.env.prd` não
é versionado.

## Validar

```bash
make analyze
make test
```

`make test` executa a suíte da aplicação e também as suítes isoladas de
`packages/network` e `packages/character`.

## CI/CD

Pull requests direcionados para `main` e pushes após merges em `main` executam
análise, todos os testes e o build Android de debug. Quando a versão do
`pubspec.yaml` muda em `main`, um segundo job gera o APK de produção com o
flavor `prd`, publica o arquivo como artefato do GitHub Actions por 90 dias e
cria uma GitHub Release publicada com o APK anexado. A tag da release segue o
formato `v<versão>`, como `v1.0.0`.

Os ambientes são definidos por `--dart-define` no momento do build e não são
assets do aplicativo. O job de produção não publica na Google Play e usa a
assinatura debug existente no projeto. Configure o secret `ENV_PRD` no GitHub
Actions com o conteúdo do arquivo `.env.prd`; a CI extrai `API_BASE_URL` e o
injeta como `PRD_API_BASE_URL` somente durante a compilação de produção. O
ambiente `prd` não possui URL padrão e falha se essa variável não for definida.

## Regras para agentes

As regras de navegação, arquitetura, limites e validação obrigatória estão em
[`AGENTS.md`](AGENTS.md). Leia esse arquivo antes de qualquer alteração no
projeto.
