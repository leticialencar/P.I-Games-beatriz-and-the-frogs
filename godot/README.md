# Frog Hunt! — versão Godot

Projeto migrado a partir da versão em Python/Pygame.

## Como abrir

1. Instale o **Godot 4** (recomendado: snap `godot-4` ou download em https://godotengine.org)
2. Abra o Godot → **Import** → selecione a pasta `godot/` deste repositório (arquivo `project.godot`)
3. Clique em **Play** (F5)

## Estrutura

```
godot/
  assets/          # sprites, sons, fonte (mesmos da versão Pygame)
  scenes/          # MainMenu, Loading, Game, EndGame, Player, Frog
  scripts/         # lógica em GDScript
  project.godot
```

## Controles

- **WASD / setas** — mover a Bea
- **E** — pegar sapinho próximo
- Menu: **Jogar**, **Sobre a Bea**, **Sair**

## Observação

O menu e a tela final estão em versão funcional (mais simples visualmente que o Pygame). A lógica da partida (movimento, spawn, captura, timer de 60s) já espelha o jogo original.
