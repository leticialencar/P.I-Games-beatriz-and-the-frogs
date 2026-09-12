<p align="center">
    <strong>Beatriz e os Sapinhos</strong><br>
    Jogo 2D de aventura e exploração — Godot 4
</p>

<p align="center">
    🚧 <strong>Em desenvolvimento</strong>
</p>

<br>

### Sobre

Beatriz precisa percorrer mapas, capturar sapinhos e superar desafios para encontrar seus amigos e jogar bingo.  
Desenvolvido para o Projeto Integrador (Unifap) com a **Godot Engine 4**.

**Progressão:** Mapa 1 → Mapa 2 → Mapa 3 (Sapão Preto) → Festa

<br>

### Como rodar

1. Instale o [Godot 4](https://godotengine.org) (ou `sudo snap install godot-4`)
2. Abra a pasta [`godot/`](godot/) no editor
3. Aperte **F5** (Play)

<br>

### Testar no navegador (amigos / desktop)

O jogo já tem export **HTML5** em [`build/web/`](build/web/).

**Local:**
```bash
cd build/web && python3 -m http.server 8080
```
Abra `http://localhost:8080`

**Render (Static Site):**
1. Push deste branch no GitHub
2. Em [render.com](https://render.com) → **New → Static Site**
3. Conecte o repositório
4. **Publish Directory:** `build/web`
5. Deploy → compartilhe o link com a turma

Há também um [`render.yaml`](render.yaml) pronto. Para gerar o export de novo: `bash scripts/export_web.sh`

<br>

### Controles

| Ação | Tecla |
|------|--------|
| Mover | WASD / setas |
| Capturar | E / Espaço / clique esquerdo |
| Atirar (mapa 3) | F / J / clique esquerdo |
| Pausar | Esc |

<br>

### Estrutura

```
godot/                 → projeto Godot (código, cenas e assets)
godot/assets/          → sprites, sons, fundos
README.md
```

<br>

---

<div align="center">

Equipe do PI — Unifap, 2026

</div>
