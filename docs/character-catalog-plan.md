# Catálogo de personagens

## Comportamento
Aba Personagens com carregamento inicial automático e busca por nome. O botão
Filtros abre um bottom sheet com status, gênero, espécie e tipo. O formulário
mantém uma cópia temporária dos valores: fechar o sheet sem aplicar descarta
essa cópia.

Ao aplicar filtros diferentes dos ativos, a ViewModel inicia uma nova consulta
com a primeira página (`next: null`). A tela emite loading, descarta os itens e
contadores anteriores, mostra chips com os filtros ativos e oferece os botões
Filtros e Limpar. Limpar aplica o filtro vazio e retorna ao catálogo completo.

Aplicar um formulário vazio quando o catálogo já está sem filtros, ou aplicar
novamente os mesmos valores, apenas fecha o bottom sheet e não chama o caso de
uso. Carregar mais segue o link `next` até o fim. Atualizar reinicia a consulta
atual. Estados explícitos de carregamento, vazio, erro recuperável e dados em
cache permanecem disponíveis.

## Fronteiras
Feature character_catalog com entidades e contratos sem Flutter/HTTP; caso de
uso LoadCharacterCatalog; repositório coordenando fontes remota e local.
A fonte remota consome PaginatedClient e converte falhas para o domínio.
A fonte local depende apenas de Cache. Composição em lib/core/di.
A entidade Character existente é reutilizada sem alterar o carregamento por ID.

## Consistência e offline
Cache por endpoint (incluindo ambiente), filtros normalizados e número de página.
A chave é um array JSON sem prefixo: [endpoint, filtros, página]. A URL completa
de continuação permanece somente nos dados da página, para seguir o link da API.
Emite cache antes de consultar rede; falha de persistência não bloqueia resultado.
Apenas consultas/páginas já visitadas ficam disponíveis offline.
A tela agrega por ID, substitui a página em atualização e ignora respostas de
consultas anteriores. Uma falha ao carregar mais mantém os itens e permite retry.
Filtros novos não exibem resultados da consulta anterior. Como uma mudança de
filtro sempre começa na página 1, o cache continua separado por filtro e página;
uma resposta salva pode aparecer antes da atualização remota sem alterar esse
fluxo.

## Entrega
Navegação preserva a busca de episódio. Fixtures dev/stg suportam filtros e
paginação local. Testes cobrem chips, aplicação, limpeza, cancelamento, filtros
idênticos, concorrência e cache. Testes de domínio, fontes, repositório, estado,
ViewModel, widgets e fixtures usam mocktail e Arrange/Act/Assert. Validar
format, analyze, flutter test e suítes network/character antes de concluir.

## Exceção de tamanho para widgets declarativos
Os métodos de construção da tela, formulário e feedback podem ultrapassar
30 linhas devido à árvore declarativa Flutter (até 60 linhas por método).
O impacto se restringe ao layout: nenhuma regra de rede, cache ou negócio fica
nesses métodos. Os widgets já foram separados por responsabilidade; se houver
novos controles ou estados, extrair os blocos em widgets menores antes de crescer.
ViewModel e métodos imperativos permanecem dentro dos limites do projeto.
