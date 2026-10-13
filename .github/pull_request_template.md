## Qué cambia
<!-- En una o dos frases: qué se agrega, corrige o documenta. -->

## Por qué
<!-- El motivo. Qué pregunta, fase o problema del proyecto resuelve. -->

## Cómo lo verifiqué
<!-- El comando o la consulta exacta que ejecutaste y el resultado que obtuviste. -->

## Checklist
- [ ] La rama tiene el prefijo correcto (`feat/`, `fix/`, `docs/`, `chore/`)
- [ ] No se trabajó directamente sobre `main`
- [ ] Los scripts SQL corren de cero sin errores
- [ ] La respuesta quedó escrita en el `README.md`

## Después del merge

Reemplazar `<rama>` por el nombre de la rama que se fusionó:

```
git switch main
git pull
git branch -d <rama>
git push origin --delete <rama>
git fetch --prune
```
