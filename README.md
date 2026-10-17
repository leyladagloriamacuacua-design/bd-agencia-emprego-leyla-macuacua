# Base de Dados — Agência de Emprego («Elo Emprego»)

| | |
|---|---|
| **Nome** | <Leyla da Gloria Macuacua> |
| **Curso / Ano** | Licenciatura em Informática — 2.º ano |
| **Disciplina** | Tecnologias de Base de Dados |
| **Tema** | Agência de emprego (candidatos, empresas, vagas, candidaturas e entrevistas) |
| **SGBD** | MySQL 8.0+ |
| **Vídeo** | <COLAR AQUI O LINK DO YOUTUBE> |

## 1. Descrição do problema

Muitas agências de emprego ainda guardam os dados de candidatos e empresas em papel ou em folhas soltas,
o que dificulta pesquisar candidatos, acompanhar candidaturas e controlar entrevistas. Este projeto
desenha uma base de dados para informatizar esse processo.

As **empresas** registam-se e publicam **vagas**, indicando o cargo, a área profissional, a localidade, o
salário, o tipo de contrato e o prazo de candidatura. Os **candidatos** criam o seu perfil (dados pessoais,
nível académico, profissão e currículo) e registam as suas **experiências profissionais**. Depois,
candidatam-se às vagas que lhes interessam. Cada **candidatura** tem um estado (submetida, em análise,
entrevista agendada, aceite ou rejeitada) que é atualizado pelos funcionários da agência.

Quando uma candidatura avança, um **funcionário** da agência agenda uma **entrevista** (data, hora e local)
e regista o resultado. Uma candidatura pode ter mais de uma entrevista (várias fases). O **administrador**
gere os utilizadores e as áreas profissionais. Todos acedem ao sistema com uma conta de **utilizador**
(e-mail e palavra-passe) com um perfil: administrador, funcionário, candidato ou empresa.

## 2. Regras de negócio

1. Cada utilizador tem um e-mail único e um perfil: administrador, funcionário, candidato ou empresa.
2. Cada candidato corresponde a exatamente uma conta de utilizador, e o BI de cada candidato é único.
3. Cada empresa corresponde a exatamente uma conta de utilizador, e o NUIT de cada empresa é único.
4. Um candidato pode ter várias experiências profissionais; cada experiência pertence a um só candidato
   e é eliminada se o candidato for eliminado (**entidade fraca**).
5. A data de fim de uma experiência não pode ser anterior à data de início; sem data de fim, é o emprego atual.
6. Uma empresa pode publicar várias vagas; cada vaga pertence a uma só empresa.
7. Cada vaga pertence a uma área profissional; uma área pode classificar várias vagas.
8. O salário de uma vaga não pode ser negativo e o prazo de candidatura não pode ser anterior à data de publicação.
9. Uma vaga está *aberta*, *fechada* ou *preenchida*.
10. Um candidato pode candidatar-se a várias vagas, mas **só uma vez à mesma vaga**.
11. Uma candidatura está *submetida*, *em análise*, *com entrevista agendada*, *aceite* ou *rejeitada*.
12. Uma candidatura pode ter zero, uma ou várias entrevistas; cada entrevista pertence a uma candidatura.
13. Cada entrevista é conduzida por um funcionário da agência.
14. Não é possível eliminar candidatos, empresas, vagas ou candidaturas que tenham registos dependentes
    (a base de dados recusa); apenas as experiências são eliminadas automaticamente com o candidato.

*Regras tratadas na aplicação web (não na base de dados):* só aceitar candidaturas a vagas abertas e dentro do
prazo; só atribuir entrevistas a utilizadores com perfil de funcionário.

## 3. Sistema web previsto (Programação Web)

Portal web **«Elo Emprego»**, construído sobre esta mesma base de dados, com login por perfil:

- **Candidato:** registar-se, editar o perfil e as experiências, pesquisar vagas (por área, localidade e
  tipo de contrato), candidatar-se e acompanhar o estado das candidaturas.
- **Empresa:** registar-se, publicar/editar/fechar vagas e ver os candidatos de cada vaga.
- **Funcionário:** listar e pesquisar candidaturas, alterar o estado, agendar entrevistas e registar resultados.
- **Administrador:** gerir utilizadores e áreas profissionais e consultar estatísticas (vagas preenchidas,
  candidaturas por estado).

## 4. Conteúdo do repositório

```
bd-agencia-emprego-nome-apelido/
 README.md                    <- este ficheiro
 diagrama_er.png              <- diagrama Entidade-Relacionamento (notação de Chen)
 modelo_relacional.md         <- tabelas, chaves primárias e estrangeiras
 01_criacao_e_insercao.sql    <- criação da BD, tabelas e inserção de registos
 02_manipulacao.sql           <- SELECT, JOIN, UPDATE, DELETE e teste de integridade
```

## 5. Como executar

```bash
mysql -u root -p < 01_criacao_e_insercao.sql
mysql -u root -p --force < 02_manipulacao.sql
```

(`--force` permite continuar após o erro **esperado** do teste de integridade, que é o último comando.)
Em alternativa, abrir os ficheiros no MySQL Workbench e executar com o raio ⚡.

## 6. Resumo da base de dados

| Tabela | Registos | O que guarda |
|---|---|---|
| area_profissional | 20 | Categorias das vagas (TI, saúde, educação...) |
| utilizador | 46 | Contas de acesso: 2 administradores, 4 funcionários, 20 candidatos, 20 empresas |
| candidato | 20 | Dados pessoais, nível académico e profissão |
| experiencia_profissional | 33 | Empregos anteriores de cada candidato (entidade fraca) |
| empresa | 20 | Empresas que publicam vagas |
| vaga | 26 | Ofertas de emprego |
| candidatura | 32 | Candidaturas de candidatos a vagas |
| entrevista | 22 | Entrevistas agendadas e respetivo resultado |
