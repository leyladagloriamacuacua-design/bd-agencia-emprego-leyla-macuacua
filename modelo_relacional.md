# Modelo Relacional — Agência de Emprego («Elo Emprego»)

**Notação:** `[PK]` = chave primária · `[FK]` = chave estrangeira · `->` indica a tabela referenciada.

## 1. Esquema relacional

```
AREA_PROFISSIONAL ( id_area [PK], nome, descricao )

UTILIZADOR ( id_utilizador [PK], email, palavra_passe, perfil, data_registo, ativo )

CANDIDATO ( id_candidato [PK], id_utilizador [FK], nome_completo, bi, data_nascimento,
            genero, telefone, cidade, nivel_academico, profissao, cv_ficheiro )
    id_utilizador -> UTILIZADOR(id_utilizador)

EXPERIENCIA_PROFISSIONAL ( id_candidato [PK,FK], num_experiencia [PK], cargo,
                           empresa_anterior, data_inicio, data_fim, descricao )   <- ENTIDADE FRACA
    id_candidato -> CANDIDATO(id_candidato)

EMPRESA ( id_empresa [PK], id_utilizador [FK], nome, nuit, setor, cidade, telefone,
          email_contacto )
    id_utilizador -> UTILIZADOR(id_utilizador)

VAGA ( id_vaga [PK], id_empresa [FK], id_area [FK], titulo, descricao, localidade,
       salario, tipo_contrato, data_publicacao, prazo_candidatura, estado )
    id_empresa -> EMPRESA(id_empresa)
    id_area    -> AREA_PROFISSIONAL(id_area)

CANDIDATURA ( id_candidatura [PK], id_candidato [FK], id_vaga [FK], data_candidatura, estado )
    id_candidato -> CANDIDATO(id_candidato)
    id_vaga      -> VAGA(id_vaga)
    (id_candidato, id_vaga) e UNICO

ENTREVISTA ( id_entrevista [PK], id_candidatura [FK], id_funcionario [FK], data_hora,
             local, resultado )
    id_candidatura -> CANDIDATURA(id_candidatura)
    id_funcionario -> UTILIZADOR(id_utilizador)    (utilizador com perfil 'funcionario')
```

## 2. Chaves estrangeiras e comportamento ao eliminar

| Tabela filha | Chave estrangeira | Tabela pai | ON DELETE | Relacionamento (ER) |
|---|---|---|---|---|
| candidato | id_utilizador (UNIQUE) | utilizador | RESTRICT | tem perfil de (1:1) |
| experiencia_profissional | id_candidato | candidato | **CASCADE** | possui (1:N, identificador) |
| empresa | id_utilizador (UNIQUE) | utilizador | RESTRICT | representa (1:1) |
| vaga | id_empresa | empresa | RESTRICT | publica (1:N) |
| vaga | id_area | area_profissional | RESTRICT | classifica (1:N) |
| candidatura | id_candidato | candidato | RESTRICT | faz (1:N) |
| candidatura | id_vaga | vaga | RESTRICT | refere-se a (1:N) |
| entrevista | id_candidatura | candidatura | RESTRICT | agenda (1:N) |
| entrevista | id_funcionario | utilizador | RESTRICT | conduz (1:N) |

`RESTRICT` impede eliminar um registo "pai" que ainda tenha "filhos". Só a experiência profissional
é eliminada em `CASCADE`, porque é entidade fraca e não faz sentido existir sem o candidato.

## 3. Como o modelo ER foi convertido em tabelas

1. **Cada entidade forte** → uma tabela, com a sua chave primária (`id_...`).
2. **Entidade fraca** (Experiência Profissional) → tabela cuja chave primária é **composta**: a chave do
   candidato (`id_candidato`) + a chave parcial (`num_experiencia`).
3. **Relacionamento 1:N** → a chave estrangeira fica na tabela do lado **N** (ex.: `vaga.id_empresa`).
4. **Relacionamento 1:1** (Utilizador–Candidato e Utilizador–Empresa) → chave estrangeira na tabela de
   participação total (candidato/empresa) com restrição `UNIQUE`, para garantir que é 1:1.
5. **Candidatura** liga Candidato e Vaga (relação N:M) e tem atributos próprios (data, estado); por isso é
   uma tabela com duas chaves estrangeiras e a restrição `UNIQUE (id_candidato, id_vaga)`.

## 4. Dependências funcionais e normalização (resumo)

Todas as tabelas estão na **3.ª Forma Normal**: os atributos dependem apenas da chave primária, sem
dependências transitivas. Exemplo: o nome da empresa não está em `vaga`, apenas `id_empresa`; o nome do
candidato não está em `candidatura`, apenas `id_candidato`. A informação completa obtém-se com `JOIN`.
