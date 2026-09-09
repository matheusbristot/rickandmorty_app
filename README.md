# Rick & Morty Episodes

Aplicação Flutter offline-first para explorar personagens e consultar episódios
da [Rick and Morty API](https://rickandmortyapi.com/documentation).

## Catálogo de personagens

- A aba inicial **Personagens** carrega a primeira página automaticamente.
- Busque por nome e abra **Filtros** para abrir o bottom sheet e combinar status,
  espécie, tipo e gênero. Espécie e tipo aceitam os termos da API (por exemplo,
  Human e Parasite).
- **Aplicar** reinicia a consulta na primeira página e mostra chips dos filtros
  ativos; **Limpar** remove todos os filtros. Fechar sem aplicar ou aplicar os
  mesmos filtros não dispara uma nova consulta.
- **Carregar mais** segue a próxima página sem duplicar personagens por ID.
- O ícone de atualização e o gesto de puxar recarregam a consulta atual.
- Resultados vazios, carregamento, fim da lista e erros possuem estados próprios.
  **Tentar novamente** repete a página que falhou, mantendo os itens disponíveis.
- A aba **Episódios** mantém a consulta por número. Trocar de aba preserva o estado.

O cache do catálogo é separado por endpoint (incluindo ambiente), filtros e
número da página. Por exemplo:
`["https://rickandmortyapi.com/api/character",{"status":"alive"},3]`.
A primeira página usa o número 1. O diretório de fixtures permanece no scope
em dev/stg. Não há prefixo adicional nem URL de continuação na chave; o link
completo de próxima página permanece no conteúdo salvo para navegação. Dados
salvos aparecem antes da atualização remota; offline, somente consultas e
páginas já visitadas ficam disponíveis. É possível continuar pelas páginas
salvas usando Carregar mais mesmo se a atualização falhar. Falhas de gravação
do cache não impedem exibir uma resposta remota. O catálogo não baixa todas as
páginas antecipadamente. Mudanças de filtros descartam respostas anteriores.

A feature fica em `features/character_catalog`, com contratos e entidades
de domínio, caso de uso, fontes local/remota, repositório e estado da apresentação.
A fonte remota utiliza `PaginatedClient`; a ViewModel recebe apenas o caso de
uso. A composição fica em `lib/core/di`. O plano está em
[`docs/character-catalog-plan.md`](docs/character-catalog-plan.md).

Em dev/stg, os três personagens de demonstração são paginados em duas entradas
por página, com os mesmos filtros; em prd, a API fornece os totais e links.

## Comportamento

- Informe o número do episódio e toque em **Buscar**.
- O episódio e todos os personagens são carregados pela API REST JSON.
- O resultado completo é salvo localmente por endpoint (incluindo ambiente) e
  número de episódio. Por exemplo:
  `["https://rickandmortyapi.com/api/episode",3]`.
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
└── ...                              # entrada e código da aplicação
features/
└── <feature>/                       # package Flutter independente
    └── lib/                         # data, domain e presentation da feature
packages/
├── app_ui/                          # widgets Flutter compartilhados
├── character/                       # domínio e requests de personagens
├── network/                         # cliente HTTP/JSON reutilizável
└── cache/                           # contrato de cache e implementação local
```

Os testes específicos de cada package ficam em `packages/<nome>/test`; a
pasta `test/` na raiz contém somente testes da aplicação, organizados por
`core` e `features/episode/<camada>`, sem arquivos diretamente na sua raiz.

O estado da tela é gerenciado por `EpisodeViewModel` (`ChangeNotifier`) e o campo do número usa `ValueNotifier`. A camada de domínio não conhece Flutter, HTTP ou persistência. O package `character` expõe eventos tipados de carregamento para que um erro em um personagem não interrompa o stream dos demais.

O package `cache` fornece a abstração de armazenamento chave-valor usada pela
fonte local de episódios. Sua implementação padrão usa
`SharedPreferencesAsync`; a dependência concreta fica montada no composition
root (`lib/core/di`), enquanto a feature depende apenas do contrato `Cache`.
Os episódios são persistidos como JSON por endpoint (incluindo ambiente) e
número, permitindo exibição imediata do cache, atualização em segundo plano e
funcionamento offline.

A orquestração entre episódio e personagens fica exclusivamente no
`EpisodeRepositoryImpl`. As regras de fronteiras e responsabilidades estão
documentadas em `AGENTS.md`.

## Composição obrigatória de features

Toda pasta direta em `features/<feature_name>` deve possuir
`lib/core/di/<feature_name>_dependencies.dart`. O arquivo precisa ser importado
por `lib/core/di/app_dependencies.dart`, mantendo a composição no composition
root.

Cada feature também é um package Flutter real, com `pubspec.yaml`, entrypoint
em `lib/<feature_name>.dart` e dependência de caminho registrada no `pubspec`
da aplicação. Features só podem depender de packages reutilizáveis; importar
`package:rickandmorty_app` de dentro de uma feature é proibido para impedir
ciclos com `core`.

Essa convenção é validada por `make validate-feature-dependencies` e também é
executada automaticamente antes de `make analyze`. A CI usa esse mesmo alvo
por meio de `make analyze`, então um pull request falha enquanto a composição
da feature estiver incompleta.

## Paginação reutilizável

O package `network` exporta `PaginatedClient` e `PaginatedClientImpl`, que
interpretam o envelope `info/results` usado por characters, locations e
episodes. Cada chamada retorna `PaginatedResponse<T>` com resultados
imutáveis e `PaginationInfo` (`count`, `pages`, `next`, `prev`, `hasNext` e
`hasPrevious`). O consumidor fornece a conversão dos itens:

A paginação separa `domain/entities` (dados imutáveis, sem JSON),
`data/clients` (contrato e implementação de transporte) e `data/mappers`
(conversão e validação do envelope). `network_entities.dart` permite importar
somente as entidades, sem expor clientes HTTP ou conversores. As entidades
não possuem `fromJson`; o cliente utiliza os mappers internos para criá-las.

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

O repositório usa o Pub workspace para resolver a aplicação e todos os seus
packages com uma única versão compartilhada das dependências. `make get` deve
ser executado na raiz; ele gera o `pubspec.lock` e o `.dart_tool/package_config.json`
compartilhados. Para listar os membros do workspace, use:

```bash
dart pub workspace list
```

As entradas disponíveis são `lib/main_dev.dart`, `lib/main_stg.dart` e
`lib/main_prd.dart` (também mantida em `lib/main.dart` para produção). Os
ambientes `dev` e `stg` carregam fixtures locais em
`assets/fixtures/<ambiente>`; `prd` usa a API oficial.

```bash
make run-stg
make run-prd-local

# build local do APK de produção usando .env.prd
make build-prd-local
```

`make run-prd-local` é o atalho para abrir a aplicação em produção local.
Ele lê `API_BASE_URL` de `.env.prd`, injeta o valor como
`PRD_API_BASE_URL` e executa o flavor `prd` sem exigir export manual no shell.
`make run-prd` continua como alias do mesmo fluxo para compatibilidade.

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

O workflow **Rick Review** revisa automaticamente pull requests não rascunho
quando são abertas, reabertas, recebem novos commits ou ficam prontas para
review. Ele lê o `AGENTS.md` da base, analisa somente o diff da pull request e
publica um comentário idempotente com a persona do Rick; novos commits
atualizam o comentário anterior. Para ativá-lo, configure o secret
`OPENAI_API_KEY` no repositório. Opcionalmente, defina a variável de Actions
`OPENAI_REVIEW_MODEL` para trocar o modelo padrão (`gpt-5`). O job também pode
ser reexecutado manualmente informando o número da pull request em
**Actions → Rick Review → Run workflow**. A chave nunca é passada para código
da branch da pull request. Antes da chamada externa, o workflow bloqueia o
envio quando um arquivo sensível é alterado ou quando o scanner determinístico
encontra padrões claros de API keys, tokens, URLs de banco ou chaves privadas no
diff. A política completa para agentes está em `AGENTS.md`; o bloqueio é uma
barreira adicional e não substitui rotação imediata de uma credencial suspeita.

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
