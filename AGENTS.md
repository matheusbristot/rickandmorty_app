# Regras para agentes e colaboradores

Este arquivo é obrigatório para qualquer agente que leia, altere ou revise o
projeto. As regras abaixo existem para preservar Clean Architecture, SOLID e o
comportamento offline-first.

## Como navegar pelo projeto

Antes de modificar código:

1. Leia `README.md`, `pubspec.yaml`, `analysis_options.yaml` e os testes da
   feature alterada.
2. Localize símbolos com `rg`, começando pelo contrato (`domain`) e seguindo
   até a implementação (`data`) e a composição (`lib/core/di`).
3. Leia os testes da área antes de alterar o comportamento.
4. Confirme o fluxo completo: tela → ViewModel → caso de uso → repositório →
   data source/package.
5. Preserve alterações existentes e não reescreva arquivos fora do escopo.

Mapa rápido:

```text
lib/core/di/                         composição e injeção de dependências
lib/features/episode/domain/         entidades, contratos e casos de uso
lib/features/episode/data/           models, repositórios e data sources
lib/features/episode/presentation/   estado, ViewModel e widgets
packages/network/                    HTTP, JSON e erros de rede reutilizáveis
packages/cache/                      contrato de cache e SharedPreferences
packages/character/                  carregamento e contrato de personagens
packages/network/test/               testes isolados do package network
packages/character/test/             testes isolados do package character
test/core/                           testes de infraestrutura/configuração
test/features/episode/               testes organizados por camada da feature
test/support/                        mocks e fixtures reutilizáveis da suíte
```

## Direção das dependências

As dependências devem apontar para dentro:

```text
presentation → domain ← data
                    ↑
             packages reutilizáveis
```

- `domain` não pode importar Flutter, HTTP, SharedPreferences ou widgets.
- `presentation` depende de abstrações de `domain`, nunca de data sources,
  clients HTTP ou cache concreto.
- `data` implementa contratos de `domain`; somente o repositório orquestra
  múltiplas fontes e casos de negócio.
- `lib/core/di` é o composition root. A construção de implementações concretas
  deve ficar concentrada ali, salvo composição interna de um package.
- `packages/cache` é o único local autorizado a importar
  `shared_preferences`.

## Contratos e implementações

Toda dependência substituível deve ter abstração explícita:

- Use `abstract interface class Nome` para contratos de serviços, repositórios,
  data sources e casos de uso.
- A classe concreta deve usar o mesmo nome com sufixo `Impl` e ser declarada
  como `final class NomeImpl implements Nome`.
- Para a ViewModel, que precisa herdar de `ChangeNotifier`, use uma classe
  abstrata (`EpisodeViewModel`) e uma implementação final `Impl`.
- A ViewModel também possui contrato: `EpisodeViewModel` é a abstração e
  `EpisodeViewModelImpl` é a implementação concreta.
- Não injete uma implementação concreta em outra camada. Faça a injeção pelo
  contrato e monte a implementação no composition root.
- Toda nova implementação deve respeitar este padrão e ser coberta por testes
  de comportamento quando aplicável.

## Limites de responsabilidade

### ViewModel

A ViewModel só coordena a interação da tela com casos de uso e expõe estado
observável. Ela não deve:

- conhecer `EpisodeRepository`, `CharacterRepository`, data source, cache ou
  `NetworkClient`;
- interpretar JSON, converter input ou mapear exceções técnicas;
- ordenar personagens ou correlacionar resultados por posição/index;
- conter regra de persistência, retry de rede ou composição de URLs;
- acumular lógica de redução de eventos: essa lógica pertence ao estado da
  apresentação ou a um caso de uso específico.

Eventos assíncronos devem identificar seus itens por uma chave estável, como a
URL ou o ID. Nunca use índice de lista para correlacionar requests e respostas.

### Data source, repositório e package

- Data source traduz uma fonte externa/local para dados do domínio. Não conhece
  repositório, presentation ou evento de tela.
- Status HTTP e outros detalhes de transporte devem ser traduzidos para falhas
  do domínio na fronteira de `data`; a presentation nunca inspeciona
  `statusCode`.
- Repositório coordena data sources, cache, consistência e regras de acesso;
  não deve conter código de widget.
- Casos de uso representam uma ação do domínio e devem ser pequenos e
  testáveis sem Flutter.
- Packages reutilizáveis não podem depender de `lib/features` da aplicação.

## Limites objetivos

Use estes limites para detectar cedo uma nova violação:

- no máximo 5 dependências no construtor de uma classe;
- no máximo 140 linhas em uma ViewModel e 240 linhas em uma classe nova;
- no máximo 30 linhas por método, exceto métodos declarativos de mapeamento;
- uma classe deve ter uma responsabilidade principal;
- uma alteração de feature deve adicionar ou atualizar testes do comportamento
  alterado;
- uma alteração arquitetural deve atualizar contratos, implementação,
  composição e testes afetados na mesma mudança;
- nenhuma dependência externa nova sem justificativa, boundary definido e
  teste de integração ou unidade correspondente;
- não alterar `build/`, arquivos gerados ou código de plataforma para resolver
  um problema de domínio sem justificar explicitamente a necessidade.

Quando um limite precisar ser excedido, registre no próprio change/PR: limite
excedido, motivo, impacto e plano de redução. Não silencie o problema apenas
com `ignore` do analyzer.

## Rotina obrigatória para nova feature

1. Defina o comportamento e o estado esperado da tela.
2. Crie/ajuste entidades e contratos no `domain`.
3. Crie casos de uso para ações da feature.
4. Implemente repositories/data sources atrás dos contratos.
5. Faça a ViewModel apenas coordenar casos de uso e estado.
6. Atualize o composition root em `lib/core/di`.
7. Adicione testes unitários para domínio/casos de uso, testes do estado e
   testes widget somente para renderização/interação.
8. Atualize `README.md` se o fluxo, cache, navegação ou comando de execução
   mudar.
9. Execute a rotina de validação antes de concluir.

## Rotina obrigatória para mudança arquitetural

Antes da mudança, descreva qual fronteira está sendo alterada e por quê.
Durante a mudança:

- altere primeiro o contrato e seus consumidores;
- mova a responsabilidade para a camada correta, sem criar atalho entre
  camadas;
- preserve compatibilidade ou atualize todos os usos encontrados com `rg`;
- adicione testes quando a mudança representar uma nova invariável ou
  comportamento do projeto;
- cubra cenários de sucesso, erro, cache/offline e concorrência quando forem
  afetados.

Não faça uma refatoração ampla junto com uma feature sem necessidade. Se a
mudança revelar outro problema, registre-o como próximo passo em vez de
misturá-lo silenciosamente.

## Padrão obrigatório para testes

Todo teste deve ser organizado explicitamente nas três fases, nesta ordem:

```dart
// Arrange
// Act
// Assert
```

- Use `mocktail` para dependências, I/O, repositories, data sources, clients e
  demais colaboradores externos ao objeto testado.
- Centralize mocks compartilhados em `test/support/test_mocks.dart` e dados
  repetidos em `test/support/test_fixtures.dart`.
- Prefira `when`, `thenAnswer`, `thenThrow`, `verify` e `captureAny` a spies,
  queues ou classes manuais que implementem contratos.
- Não crie mocks para funções puras, entidades ou transformações determinísticas;
  nesses casos, teste diretamente o resultado usando Arrange/Act/Assert.
- Cada teste deve validar o resultado observável e, quando relevante, as
  interações esperadas com `verify`.
- Testes de um package devem permanecer em `packages/<nome>/test` e usar apenas
  dependências e helpers daquele package; nunca importe helpers de `root/test`.
- Mocks e fixtures compartilhados entre testes de um package devem ficar em
  `packages/<nome>/test/support`; a suíte da aplicação mantém seus helpers em
  `test/support`.
- Dentro de cada suíte, espelhe a área do código testado: `core` para código de
  núcleo e `features/<feature>/<camada>` para data, domain e presentation.
- Evite arquivos diretamente na raiz de `test` ou de `packages/<nome>/test`;
  use subpastas que expressem o contexto do código testado.
- Um teste não deve depender da ordem de execução de outro teste nem compartilhar
  estado mutável entre casos.

## Validação e definição de pronto

Após qualquer alteração de código:

```bash
dart format <arquivos-alterados>
flutter analyze
flutter test
# Para cada package alterado:
(cd packages/network && dart test)
(cd packages/character && dart test)
```

Após alteração de dependências, execute `flutter pub get` na aplicação e
`dart pub get` em cada package alterado. A entrega só está pronta quando
análise e todas as suítes afetadas passam. Se alguma validação não puder ser
executada, informe o comando, o motivo e o risco restante.

Checklist final do agente:

- [ ] li as regras e os testes existentes;
- [ ] mantive as dependências na direção correta;
- [ ] usei abstração + implementação `final ...Impl`;
- [ ] não introduzi índices para correlacionar dados assíncronos;
- [ ] atualizei os testes afetados e documentei novas invariantes;
- [ ] executei format, analyze e test;
- [ ] documentei limites ou exceções, se houver.
