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

## Paginação reutilizável

O package `network` exporta `PaginatedClient` e `PaginatedClientImpl`, que
interpretam o envelope `info/results` usado por characters, locations e
episodes. Cada chamada retorna `PaginatedResponse<T>` com resultados
imutáveis e `PaginationInfo` (`count`, `pages`, `next`, `prev`, `hasNext` e
`hasPrevious`). O consumidor fornece a conversão dos itens:

```dart
final PaginatedClient pagination = PaginatedClientImpl(networkClient);
final page = await pagination.getPage<CharacterModel>(
  'character?name=Rick',
  page: 1,
  decodeItem: CharacterModel.fromJson,
);
final next = page.info.next;
if (next != null) {
  final nextPage = await pagination.getPageUri<CharacterModel>(
    next,
    decodeItem: CharacterModel.fromJson,
  );
  // Entregue nextPage ao repositório consumidor.
}
```

`getPage` recebe um caminho relativo à URL base, preserva filtros e substitui
o parâmetro `page`. A página padrão é 1; 0 é normalizado para 1 e valores
negativos são rejeitados antes da requisição. `getPageUri` recebe uma URL
HTTP(S) absoluta e a utiliza sem alterações, permitindo seguir `next`/`prev`.
Links nulos indicam ausência de página adjacente; não há busca automática.

O envelope exige contagens inteiras não negativas, links HTTP(S) absolutos
ou nulos e uma lista de objetos. Dados inválidos geram `FormatException`;
erros do conversor são propagados. `NetworkException`, timeout e retry
permanecem sob o cliente HTTP existente. O adaptador não fecha esse cliente.

Data sources futuros devem receber o contrato `PaginatedClient`, composto em
`lib/core/di`, e converter os itens para seus models. Repositórios continuam
responsáveis por cache e consistência, enquanto as features definem acúmulo
de páginas e estado da tela. O adaptador não guarda estado entre chamadas e
não depende das features. A busca atual de um único episódio não utiliza
paginação e mantém seu fluxo offline-first.

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
