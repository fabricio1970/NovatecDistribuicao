# BUILD-01 - Mapa do pipeline atual

Data do levantamento: 2026-08-20

Status do mapeamento: READY

Este documento registra o pipeline existente antes da criacao de
`CompilarTudo.bat`. Nao houve alteracao funcional no cliente ou no servidor.
Foi aplicada somente uma correcao de compilacao na guarda condicional de uma
chamada de instrumentacao DEBUG, descrita nos testes abaixo. Os BAT de
publicacao existentes nao foram executados; portanto, nenhum `git commit` ou
`git push` foi feito.

## Resultado dos testes

Ferramentas usadas:

- Delphi 12 Athens: `C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc32.exe`
- Versao confirmada: dcc32 36.0
- Ambiente Delphi: `C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat`
- MSBuild: `C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe`

Os scripts de compilacao neutralizam `PostBuildEvent` por propriedade de linha
de comando, preservam o `FileVersion` configurado nos DPROJ e direcionam o EXE
diretamente para `cliente\` ou `servidor\`. Isso evita commit/push e mantem a
validacao pre-build do servidor.

### Servidor

Comando testado:

```bat
CompilarServidor.bat
```

Resultado: PASS.

- Validacao: `OK: nenhuma conexao ou servico esta ativo em tempo de design.`
- Compilacao: 305080 linhas, dcc32 36.0.
- Saida gerada: `D:\sistemas\novatec\NovaTecDistribuicao\servidor\NovatecServidor.exe`.
- Exit code do MSBuild: `0`.
- FileVersion observado no executavel gerado: `6.0.0.42`.
- O script desativa o incremento automatico somente nesta compilacao, sem
  alterar o DPROJ.
- O serial comum e calculado como o maior `FileVersion` entre os dois DPROJ;
  neste teste, cliente e servidor foram gerados com `6.0.0.42`.

### Cliente

Comando testado:

```bat
CompilarCliente.bat
```

Resultado: PASS apos correcao de compilacao sem mudanca funcional.

- Exit code do MSBuild: `0`.
- Compilacao: 1323202 linhas.
- Saida gerada: `D:\sistemas\novatec\NovaTecDistribuicao\cliente\NovatecCliente.exe`.
- FileVersion observado no executavel gerado: `6.0.0.42`.
- O serial comum e calculado como o maior `FileVersion` entre os dois DPROJ;
  neste teste, cliente e servidor foram gerados com `6.0.0.42`.

Correcao aplicada em `cliente\src\modules\producao\op\UOrdemProducao.Sql.pas`:
a chamada `CodeSite.Send` foi colocada sob `{$IFDEF DEBUG}`, alinhando-a com a
importacao condicional de `CodeSiteLogging`. O Release deixou de referenciar
um simbolo que nao existe nessa configuracao; o comportamento de DEBUG foi
preservado.

### Validador design-time

Teste direto de `NovoServidor\validar_conexoes_design_time.bat`:

```bat
validar_conexoes_design_time.bat
```

Resultado: PASS, exit code `0`.

Conclusao de teste: os caminhos de compilacao do cliente e do servidor estao
funcionais com o ambiente Delphi 12 Athens validado.

## Projetos oficiais

Cliente oficial confirmado:

```text
D:\sistemas\novatec\cliente\NovatecCliente.dproj
```

- `MainSource`: `NovatecCliente.dpr`
- Plataforma padrao: `Win32`
- Configuracao padrao: `Debug`
- Configuracao alvo: `Release/Win32`
- Saida configurada: `..\_bin\$(Config)`
- Saida efetiva alvo: `D:\sistemas\novatec\_bin\Release\NovatecCliente.exe`

Servidor confirmado exatamente como solicitado:

```text
D:\sistemas\novatec\NovoServidor\NovatecServidor.dproj
```

- `MainSource`: `NovatecServidor.dpr`
- Plataforma padrao: `Win32`
- Configuracao alvo: `Release/Win32`
- Saida configurada: `..\_Bin\$(Config)`
- Saida efetiva alvo: `D:\sistemas\novatec\_Bin\Release\NovatecServidor.exe`

`_Bin` e `_bin` sao equivalentes no Windows. A proposta deve escolher uma
grafia canonica, mas nao deve alterar os DPROJ nesta fase.

## Scripts localizados

### Distribuicao

- `NovaTecDistribuicao\PublicarCliente.bat`
- `NovaTecDistribuicao\PublicarServidor.bat`

Ambos os BAT fazem, nesta ordem: verificacao do EXE de origem, leitura de
`FileVersion` via PowerShell, copia para a area de distribuicao, escrita de
`version.txt`, `git add`, `git commit` e `git push origin main`. Os comandos de
Git estao ativos no script atual.

O retorno atual e `0` em sucesso ou quando nao ha alteracao staged; e `1` nos
erros de arquivo, versao, copia, Git commit ou push. O `git push` atual nao
deve ser chamado durante BUILD-01.

### Servidor

- `NovoServidor\validar_conexoes_design_time.bat`
- `NovoServidor\validar_conexoes_design_time.ps1`
- `NovoServidor\configurar-dpr.bat`
- `NovoServidor\configurar-dpr.ps1`
- `NovoServidor\INSTALAR_EM_PROJETO.ps1`

Somente `validar_conexoes_design_time.bat/.ps1` pertence diretamente ao build.
O PS1 percorre DFM e rejeita `Connected=True` e `Active=True`, exceto os casos
locais previstos para `TClientDataSet` com `PersistDataPacket` e `TJvTrayIcon`.

### Cliente

- `cliente\configurar-dpr.bat`
- `cliente\configurar-dpr.ps1`
- `cliente\INSTALAR_EM_PROJETO.ps1`

Esses scripts configuram o contexto do agente e nao sao etapas de compilacao
ou publicacao.

### Outros BAT encontrados

- `_Bin\Debug\point.bat`: encerra `ConFlexClient`; nao e etapa de build/publicacao.

Nao foram localizados arquivos `CMD` na arvore examinada.

## Build Events atuais

### Cliente

O evento final especifico de `Release/Win32` esta em
`cliente\NovatecCliente.dproj:1214-1220` e equivale a:

```bat
echo POSTBUILD EXECUTADO > D:\sistemas\conflex3c\NovaTecDistribuicao\postbuild_cliente.txt&cmd.exe /c call "D:\sistemas\conflex3c\NovaTecDistribuicao\PublicarCliente.bat" >> D:\sistemas\conflex3c\NovaTecDistribuicao\postbuild_cliente.log 2>&1&
```

O bloco anterior em `:153-156` tambem contem o mesmo post-build, mas com
`2>` e `1` quebrados em linhas separadas. O bloco final e o que prevalece
textualmente para Release/Win32 e ainda termina com `&` extra.

Mapeamento funcional:

1. compila o cliente;
2. grava o marcador `postbuild_cliente.txt`;
3. chama `PublicarCliente.bat`;
4. acrescenta stdout e stderr em `postbuild_cliente.log`;
5. ignora o exit code do post-build (`PostBuildEventIgnoreExitCode=True`).

### Servidor

O evento final especifico de `Release/Win32` esta em
`NovoServidor\NovatecServidor.dproj:712-720` e pretende equivaler a:

```bat
echo POSTBUILD EXECUTADO > D:\sistemas\conflex3c\NovaTecDistribuicao\postbuild_servidor.txt&cmd.exe /c call "D:\sistemas\conflex3c\NovaTecDistribuicao\PublicarServidor.bat" >> D:\sistemas\conflex3c\NovaTecDistribuicao\postbuild_servidor.log 2>&1
```

O texto persistido esta quebrado entre `2>` e `&1`. O bloco anterior em
`:124-126` esta quebrado entre `2>` e `1`. O servidor ainda possui
`PreBuildEvent=call "$(PROJECTDIR)\validar_conexoes_design_time.bat"` no bloco
final, mas em Release/Win32 `PreBuildEventIgnoreExitCode=True`; portanto, a
validacao pode falhar sem impedir a compilacao atual.

### Redirecionamento

A forma canonica que deve ser usada em qualquer script/evento futuro e:

```bat
>> "arquivo.log" 2>&1
```

`2>&1` precisa estar na mesma linha e sem `&` sobrando. O `&` imediatamente
antes de `cmd.exe` e apenas separador de comandos; o `&` depois de `2>&1` no
evento do cliente e sintaxe residual/problemática.

## Caminhos legados `D:\sistemas\conflex3c`

Nao foi feita substituicao cega. A classificacao abaixo separa referencias
ativas de build, referencias de dependencias confirmadas e historico de IDE.

### Referencias ativas com destino confirmado

| Origem legada | Equivalente confirmado | Onde aparece | Acao BUILD-02 |
| --- | --- | --- | --- |
| `D:\sistemas\conflex3c\NovaTecDistribuicao` | `D:\sistemas\novatec\NovaTecDistribuicao` | dois BAT e dois DPROJ | usar a raiz atual |
| `D:\sistemas\conflex3c\_Bin\Release\NovatecCliente.exe` | `D:\sistemas\novatec\_bin\Release\NovatecCliente.exe` | `PublicarCliente.bat` | confirmar com compilacao cliente |
| `D:\sistemas\conflex3c\_Bin\Release\NovatecServidor.exe` | `D:\sistemas\novatec\_Bin\Release\NovatecServidor.exe` | `PublicarServidor.bat` | confirmado pelo build do servidor |
| `D:\sistemas\conflex3c\dataset-serialize\src\...` | `D:\sistemas\novatec\dataset-serialize\src\...` | `NovatecCliente.dproj` search path | destino existe; validar cada subpasta |
| `D:\sistemas\conflex3c\RESTRequest4Delphi\src\...` | `D:\sistemas\novatec\RESTRequest4Delphi\src\...` | `NovatecCliente.dproj` search path | destino existe; validar cada subpasta |
| `D:\sistemas\conflex3c\_Dcu\Cliente\Debug` | `D:\sistemas\novatec\_dcu\Cliente\Debug` | search path legado | nao usar como origem de fonte; revisar no build |
| `D:\sistemas\conflex3c\_Dcu\Cliente\Release` | `D:\sistemas\novatec\_dcu\Cliente\Release` | search path legado | nao usar como origem de fonte; revisar no build |

Os destinos de diretorio acima foram verificados e existem. As dependencias
externas `D:\acbr`, `D:\componentes` e `D:\sistemas\Lib_Novo` nao pertencem
ao prefixo legado e nao devem ser remapeadas.

### Referencias de historico/editor, sem substituicao automatica

O prefixo tambem aparece em `*.dproj.local`, `*.dsk` e transacoes antigas,
incluindo caminhos para `cliente\Unit1.pas`, `cliente\ConFlexClientRst.dproj`,
`NovoServidor\conflexsvrRst.dproj`, unidades antigas e arquivos removidos.
Esses registros nao dirigem o build. O projeto oficial atual e
`NovatecCliente.dproj`/`NovatecServidor.dproj`; portanto, nao se deve trocar o
texto historico por esses nomes sem uma decisao especifica.

## Compilacao de linha de comando

Forma exata validada para cada DPROJ, apos carregar o ambiente de Delphi 12
Athens via `rsvars.bat`:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
MSBuild.exe "D:\sistemas\novatec\NovoServidor\NovatecServidor.dproj" /t:Build /p:Config=Release /p:Platform=Win32
MSBuild.exe "D:\sistemas\novatec\cliente\NovatecCliente.dproj" /t:Build /p:Config=Release /p:Platform=Win32
```

Para o teste BUILD-01 foi acrescentado `/p:PostBuildEvent=` para bloquear
somente a publicacao automatica atual. Em BUILD-02, o orquestrador devera
controlar o post-build e nao depender desses eventos laterais.

O dcc32 sozinho compila um DPR, nao e a interface correta para aplicar todas
as propriedades e Build Events de um DPROJ. Por isso, a interface de build
validada e MSBuild + CodeGear.Delphi.Targets, com dcc32 selecionado pelo
ambiente 23.0.

## Git

- Root: `D:\sistemas\novatec\NovaTecDistribuicao`
- Branch atual: `main`
- Remote: `origin git@github.com:fabricio1970/NovatecDistribuicao.git`
- Estado: `main` esta `ahead 2` de `origin/main`.
- `.gitignore` na raiz: nao existe.
- `.gitattributes`: EXE de `cliente` e `servidor` usam Git LFS.

Arquivos atualmente versionados:

```text
.gitattributes
cliente/NovatecCliente.exe
cliente/README.txt
cliente/version.txt
servidor/NovatecServidor.exe
servidor/README.txt
servidor/version.txt
```

Nao devem entrar no Git como artefatos de build: `_bin`, `_Bin`, `_dcu`,
`*.dcu`, `*.dcp`, `*.map`, `*.identcache`, `*.stat`, `*.dproj.local`,
`*.dsk`, logs de build e post-build, arquivos temporarios e dumps. Os EXE de
distribuicao sao a excecao existente: ja sao versionados via LFS. Os novos
scripts de automacao e a documentacao devem ser adicionados conscientemente,
nao como efeito colateral de `git add .`.

O estado observado durante BUILD-01 tambem possui arquivos nao versionados
preexistentes (`.opencode/`, BAT de publicacao, marcadores e arquivos de
teste). Eles nao foram removidos, adicionados, commitados ou enviados.

## Proposta de estrutura

Implementado:

```text
NovaTecDistribuicao\
  CompilarTudo.bat
  CompilarServidor.bat
  CompilarCliente.bat
  ObterVersaoBuild.ps1
  scripts\
  logs\
  docs\
    build-pipeline-map.md
```

Responsabilidades:

- `CompilarServidor.bat`: validar design-time, compilar servidor Release/Win32,
  validar EXE e retornar o erro real.
- `CompilarCliente.bat`: compilar cliente Release/Win32, validar EXE e retornar
  o erro real.
- `CompilarTudo.bat`: chamar os dois com `call`, interromper no primeiro erro e
  devolver o exit code da etapa que falhou.
 - `scripts\`: apenas helpers tecnicos sem commit/push implicito.
- `logs\`: saida de compilacao, com stdout/stderr unidos por `2>&1`.
- `docs\`: mapas, contratos e resultados de teste.

## Fluxo e exit codes propostos

Regra principal: compilacao falha significa nao publicar. Nenhum wrapper deve
converter falha em sucesso.

- `0`: sucesso completo ou publicacao sem alteracao, conforme contrato do
  publicador.
- `1`: erro operacional ja usado pelos BAT de publicacao atuais.
- `10`: uso/configuracao ou ferramenta ausente.
- `20`: validacao design-time falhou.
- `30`: MSBuild/dcc32 falhou; propagar o exit code real quando possivel.
- `40`: executavel esperado nao existe ou nao foi possivel ler a versao.
- `50`: copia/geracao do artefato falhou.
- `60`: Git add/commit/push falhou, caso a publicacao continue incluindo Git.

Fluxo desejado para BUILD-02:

1. preparar ambiente Delphi;
2. validar pre-condicoes;
3. validar conexoes design-time do servidor;
4. compilar servidor Release/Win32;
5. verificar `NovatecServidor.exe`;
6. compilar cliente Release/Win32;
7. verificar `NovatecCliente.exe`;
8. somente depois executar uma publicacao explicitamente autorizada;
9. retornar `0` apenas quando todas as etapas exigidas passarem.

No estado atual, esse fluxo conclui as etapas de compilacao com exit code `0`.

## Pendencias para BUILD-02

- alinhar, em mudanca separada, os `version.txt` da distribuicao com o
  `FileVersion` dos DPROJ;
- corrigir, em mudanca separada e revisada, as referencias ativas ao caminho
  legado;
- remover a dependencia de publicacao por Build Event ou tornar seu contrato
  de erro explicito;
- decidir se commit/push continuam dentro de publicacao ou ficam fora do build;
- somente entao implementar os tres BAT propostos.
