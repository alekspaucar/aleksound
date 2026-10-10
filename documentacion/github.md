# Git y GitHub

## Alcance

El repositorio debe comenzar en `alesound`. Comprueba:

```bash
git rev-parse --show-toplevel
```

Debe devolver la carpeta del proyecto. Si devuelve `/Users/erickvzh`, no añadas archivos: estás mirando un repositorio superior con contenido personal. Un repositorio independiente del proyecto evita esa mezcla.

## Versionado

Código, assets originales, pruebas, configuraciones de plataformas, README, `documentacion/`, `pubspec.yaml` y `pubspec.lock`.

Se excluyen `.claude/`, `.codex/`, `.agents/`, `.cursor/`, `.gemini/`, `CLAUDE.md`, `CODEX.md`, `AGENTS.md`, `GEMINI.md`, instrucciones Copilot, cachés, configuración local, secretos y firma. No se ignoran todos los Markdown: la documentación del producto acompaña al código.

`.gitignore` no retira archivos que ya estaban versionados. Revisa el estado antes de publicar.

## Primera publicación

Crea un repositorio vacío en tu cuenta y selecciona su visibilidad. En el repositorio local independiente:

```bash
git status --short
git add README.md documentacion lib assets test tools web ios android pubspec.yaml pubspec.lock analysis_options.yaml .gitignore .metadata
git diff --cached --stat
git commit -m "Crear prototipo de Aleksound"
git remote add origin URL_DEL_REPOSITORIO
git push -u origin main
```

Sustituye el destino real. Si ya hay `origin`, inspecciónalo antes de cambiarlo. No se ha elegido ni publicado un repositorio remoto en esta etapa.

`AGENTS.md` y `CLAUDE.md` locales apuntan a documentación compartida y están ignorados. Las decisiones del producto deben registrarse en `documentacion/`.
