# Horizon portatil para Windows x64

## Instalar e abrir

1. Baixe o repositorio como ZIP e extraia-o. Nao execute os arquivos dentro do ZIP.
2. Abra `packaging\windows-portable`.
3. Execute `Instalar-e-Iniciar.cmd`.
4. Entre com uma conta Microsoft que possua Minecraft: Java Edition e use **Play**.

O instalador baixa o `horizon-launcher-windows-x64.zip` da versao oficial mais recente,
confere o SHA-256 publicado pelo GitHub e extrai apenas `horizon-launcher.exe`. O launcher,
as configuracoes, os downloads e os mundos ficam em `data` ao lado dos scripts.

Nas proximas vezes, use `Iniciar-Horizon.cmd`.

## Build nativo e mods

O inicializador procura o toolchain Rust/MinGW baixado pelo launcher. Quando ele existe, copia os
headers do MinGW para `%USERPROFILE%\.horizon-build-include` e passa esse caminho curto ao GCC.
Isso evita erros como:

```text
fatal error: sec_api/string_s.h: No such file or directory
fatal error: corecrt_stdio_config.h: No such file or directory
```

O reparo também adapta as fontes locais do TreeFall que ainda usam `Dim::min_y/max_y` e um binding
imutavel no hook de velocidade. A adaptacao foi compilada com Horizon `d91cab6`; mods presos a outra
revisao ainda podem exigir uma versao compativel do proprio mod.

Se o primeiro build nativo baixar o toolchain e falhar antes da copia dos headers, feche o launcher,
abra novamente por `Iniciar-Horizon.cmd` e repita o build.

## O que nao vai para o Git

`horizon-launcher.exe` e a pasta `data` sao ignorados pelo repositorio. Eles podem conter downloads,
configuracoes, credenciais vinculadas ao Windows e mundos do jogador. O repositorio nao inclui
arquivos, codigo ou assets do Minecraft.
