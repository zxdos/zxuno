# Manual

## How to build this documentation

In order to make PDF and ePub files from the source code (`.adoc` files), folow these steps:

- Install [asciidoctor](https://asciidoctor.org), [asciidoctor PDF](https://asciidoctor.org/docs/asciidoctor-pdf/) and [asciidoctor EPUB3](https://asciidoctor.org/docs/asciidoctor-epub3/)

- Run on the shell commands like these (adjusting paths as needed):

      asciidoctor-pdf -a pdf-theme=style.yml -a pdf-themesdir="..." -o ".../English ZXUno4ALL Manual.pdf" English ZXUNO+ and +UNO Manual.adoc

      asciidoctor-epub3 -o ".../English ZXUno4ALL Manual.epub" English ZXUNO+ and +UNO Manual.adoc

---

## Construcción de esta documentación

Para poder generar desde el código fuente (archivos `.adoc`), ficheros PDF y ePub, se han de seguir estos pasos (ajustando las rutas a directorios y ficheros según sea necesario):

- Instalar [asciidoctor](https://asciidoctor.org), [asciidoctor PDF](https://asciidoctor.org/docs/asciidoctor-pdf/) y [asciidoctor EPUB3](https://asciidoctor.org/docs/asciidoctor-epub3/)

- Ejecutar unos comandos similares a los siguientes

      asciidoctor-pdf -a pdf-theme=style.yml -a pdf-themesdir="..." -o ".../Manual de ZXUNO+ y +UNO.pdf" Manual de ZXUNO+ y +UNO.adoc

      asciidoctor-epub3 -o ".../Manual de ZXUNO+ y +UNO.epub" Manual de ZXUNO+ y +UNO.adoc
