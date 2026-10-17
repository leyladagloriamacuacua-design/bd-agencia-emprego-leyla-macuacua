-- =====================================================================
-- Projecto de Base de Dados: Agência de Emprego (Elo Emprego)
-- Disciplina: Tecnologias de Base de Dados - 2.º ano, Licenciatura em Informática
-- Autor: <O SEU NOME COMPLETO>
-- SGBD: MySQL 8.0+ (executar de raiz, sem erros)
-- Ficheiro 1/2: criação da base de dados, tabelas e inserção de registos
-- =====================================================================

DROP DATABASE IF EXISTS agencia_emprego;
CREATE DATABASE agencia_emprego CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE agencia_emprego;

-- ---------------------------------------------------------------------
-- 1. CRIAÇÃO DAS TABELAS (ordem: primeiro as tabelas "pai", depois as "filhas")
-- ---------------------------------------------------------------------

-- Categorias profissionais usadas para classificar as vagas
CREATE TABLE area_profissional (
    id_area    INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(60)  NOT NULL,
    descricao  VARCHAR(200),
    CONSTRAINT uq_area_nome UNIQUE (nome)
) ENGINE=InnoDB;

-- Contas de acesso ao sistema (administrador, funcionário, candidato, empresa)
CREATE TABLE utilizador (
    id_utilizador  INT AUTO_INCREMENT PRIMARY KEY,
    email          VARCHAR(100) NOT NULL,
    palavra_passe  CHAR(64)     NOT NULL,   -- hash da palavra-passe (nunca texto simples)
    perfil         ENUM('administrador','funcionario','candidato','empresa') NOT NULL,
    data_registo   DATE         NOT NULL,
    ativo          TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT uq_utilizador_email UNIQUE (email)
) ENGINE=InnoDB;

-- Candidatos a emprego (cada candidato tem exactamente uma conta de utilizador)
CREATE TABLE candidato (
    id_candidato     INT AUTO_INCREMENT PRIMARY KEY,
    id_utilizador    INT          NOT NULL,
    nome_completo    VARCHAR(100) NOT NULL,
    bi               VARCHAR(13)  NOT NULL,
    data_nascimento  DATE         NOT NULL,
    genero           ENUM('M','F') NOT NULL,
    telefone         VARCHAR(20)  NOT NULL,
    cidade           VARCHAR(50)  NOT NULL,
    nivel_academico  ENUM('Ensino Médio','Técnico Médio','Licenciatura','Mestrado') NOT NULL,
    profissao        VARCHAR(80)  NOT NULL,
    cv_ficheiro      VARCHAR(100),
    CONSTRAINT uq_candidato_utilizador UNIQUE (id_utilizador),
    CONSTRAINT uq_candidato_bi UNIQUE (bi),
    CONSTRAINT fk_candidato_utilizador FOREIGN KEY (id_utilizador)
        REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ENTIDADE FRACA: a experiência não existe sem o candidato.
-- Chave primária composta = chave do candidato + número de ordem da experiência.
CREATE TABLE experiencia_profissional (
    id_candidato      INT          NOT NULL,
    num_experiencia   INT          NOT NULL,
    cargo             VARCHAR(80)  NOT NULL,
    empresa_anterior  VARCHAR(100) NOT NULL,
    data_inicio       DATE         NOT NULL,
    data_fim          DATE,                      -- NULL = emprego actual
    descricao         VARCHAR(200),
    PRIMARY KEY (id_candidato, num_experiencia),
    CONSTRAINT ck_experiencia_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT fk_experiencia_candidato FOREIGN KEY (id_candidato)
        REFERENCES candidato (id_candidato) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Empresas que publicam vagas (cada empresa tem uma conta de utilizador)
CREATE TABLE empresa (
    id_empresa       INT AUTO_INCREMENT PRIMARY KEY,
    id_utilizador    INT          NOT NULL,
    nome             VARCHAR(100) NOT NULL,
    nuit             CHAR(9)      NOT NULL,
    setor            VARCHAR(60)  NOT NULL,
    cidade           VARCHAR(50)  NOT NULL,
    telefone         VARCHAR(20)  NOT NULL,
    email_contacto   VARCHAR(100) NOT NULL,
    CONSTRAINT uq_empresa_utilizador UNIQUE (id_utilizador),
    CONSTRAINT uq_empresa_nuit UNIQUE (nuit),
    CONSTRAINT fk_empresa_utilizador FOREIGN KEY (id_utilizador)
        REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Ofertas de emprego publicadas pelas empresas
CREATE TABLE vaga (
    id_vaga            INT AUTO_INCREMENT PRIMARY KEY,
    id_empresa         INT           NOT NULL,
    id_area            INT           NOT NULL,
    titulo             VARCHAR(100)  NOT NULL,
    descricao          VARCHAR(300)  NOT NULL,
    localidade         VARCHAR(50)   NOT NULL,
    salario            DECIMAL(10,2) NOT NULL,   -- em meticais (MZN)
    tipo_contrato      ENUM('Efetivo','Prazo certo','Estágio','Part-time') NOT NULL,
    data_publicacao    DATE          NOT NULL,
    prazo_candidatura  DATE          NOT NULL,
    estado             ENUM('aberta','fechada','preenchida') NOT NULL DEFAULT 'aberta',
    CONSTRAINT ck_vaga_salario CHECK (salario >= 0),
    CONSTRAINT ck_vaga_datas CHECK (prazo_candidatura >= data_publicacao),
    CONSTRAINT fk_vaga_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa (id_empresa) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_vaga_area FOREIGN KEY (id_area)
        REFERENCES area_profissional (id_area) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Candidatura = ligação N:M entre candidato e vaga (com dados próprios)
CREATE TABLE candidatura (
    id_candidatura    INT AUTO_INCREMENT PRIMARY KEY,
    id_candidato      INT  NOT NULL,
    id_vaga           INT  NOT NULL,
    data_candidatura  DATE NOT NULL,
    estado            ENUM('submetida','em_analise','entrevista_agendada','aceite','rejeitada')
                      NOT NULL DEFAULT 'submetida',
    CONSTRAINT uq_candidatura UNIQUE (id_candidato, id_vaga),   -- 1 candidatura por vaga
    CONSTRAINT fk_candidatura_candidato FOREIGN KEY (id_candidato)
        REFERENCES candidato (id_candidato) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_candidatura_vaga FOREIGN KEY (id_vaga)
        REFERENCES vaga (id_vaga) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Entrevistas agendadas a partir de uma candidatura, conduzidas por um funcionário
CREATE TABLE entrevista (
    id_entrevista   INT AUTO_INCREMENT PRIMARY KEY,
    id_candidatura  INT          NOT NULL,
    id_funcionario  INT          NOT NULL,   -- utilizador com perfil 'funcionario'
    data_hora       DATETIME     NOT NULL,
    local           VARCHAR(100) NOT NULL,
    resultado       ENUM('pendente','aprovado','reprovado') NOT NULL DEFAULT 'pendente',
    CONSTRAINT fk_entrevista_candidatura FOREIGN KEY (id_candidatura)
        REFERENCES candidatura (id_candidatura) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_entrevista_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. INSERÇÃO DE REGISTOS (ordem imposta pelas chaves estrangeiras)
--    area_profissional -> utilizador -> candidato -> experiencia_profissional
--    -> empresa -> vaga -> candidatura -> entrevista
-- ---------------------------------------------------------------------

-- 20 áreas profissionais
INSERT INTO area_profissional (id_area, nome, descricao) VALUES
    (1, 'Tecnologias de Informação', 'Programação, redes, suporte e sistemas'),
    (2, 'Saúde', 'Enfermagem, farmácia, clínicas e hospitais'),
    (3, 'Educação', 'Ensino, formação e explicações'),
    (4, 'Construção Civil', 'Obras, acabamentos e fiscalização'),
    (5, 'Contabilidade e Finanças', 'Contabilidade, auditoria e banca'),
    (6, 'Vendas e Comercial', 'Comércio a retalho e gestão de lojas'),
    (7, 'Logística e Transportes', 'Motoristas, armazéns e distribuição'),
    (8, 'Hotelaria e Turismo', 'Hotéis, alojamentos e turismo'),
    (9, 'Agricultura', 'Produção agrícola e extensão rural'),
    (10, 'Engenharia', 'Engenharia civil, eletrotécnica e mecânica'),
    (11, 'Recursos Humanos', 'Recrutamento, formação e gestão de pessoal'),
    (12, 'Marketing e Comunicação', 'Publicidade, redes sociais e comunicação'),
    (13, 'Direito', 'Assessoria jurídica e contratos'),
    (14, 'Segurança', 'Vigilância e segurança privada'),
    (15, 'Administração', 'Secretariado e gestão administrativa'),
    (16, 'Atendimento ao Cliente', 'Call centers e apoio ao cliente'),
    (17, 'Mecânica e Manutenção', 'Oficinas, manutenção industrial e automóvel'),
    (18, 'Energia e Minas', 'Eletricidade, energia e indústria extrativa'),
    (19, 'Design Gráfico', 'Design, ilustração e produção gráfica'),
    (20, 'Restauração', 'Cozinha, serviço de mesa e catering');

-- 46 utilizadores: 2 administradores, 4 funcionários, 20 candidatos, 20 empresas.
-- (As palavras-passe são hashes SHA-256 de exemplo; na aplicação web usar password_hash().)
INSERT INTO utilizador (id_utilizador, email, palavra_passe, perfil, data_registo, ativo) VALUES
    (1, 'admin@eloemprego.co.mz', '6b2b0e3faebd2f0314e2c6de407b97e6be811fed01963a24d1fd51a653ca277b', 'administrador', '2026-06-02', 1),
    (2, 'gestao@eloemprego.co.mz', '3928196dcb297f0ea9a3ec8d8bf8ccd5ad955cc37213d8b11121bf24eb80207c', 'administrador', '2026-06-03', 1),
    (3, 'marta.sambo@eloemprego.co.mz', '835903f82e8484819bf3f47c82b3c4f7372c8944359ba13ba9f96f5ba03ce6b9', 'funcionario', '2026-06-04', 1),
    (4, 'paulo.vilanculos@eloemprego.co.mz', '53275c026a8812c14390f211750aab6762f37c889e39b0d5d9eff42ac0ca7f76', 'funcionario', '2026-06-05', 1),
    (5, 'ines.maculuve@eloemprego.co.mz', '8f4792ed60c851b5497d7c6f5b2d3db003cf941a7e909e69ec70c901ba08ae7a', 'funcionario', '2026-06-06', 1),
    (6, 'jose.bunga@eloemprego.co.mz', 'fc5add93795db67cfa856c9a4f0f86b1c920d5596781114b3be3d83867627966', 'funcionario', '2026-06-07', 1),
    (7, 'abdul.issufo@mail.co.mz', '76777d173d6f990e63578a21cdc731653e72e4ea18d15bba3f3b8f330ad6c489', 'candidato', '2026-07-11', 1),
    (8, 'ana.nhantumbo@mail.co.mz', '4a3984d2d890db46fe6db4bf002709ca9abf05ae73edecb625d0f9b2a7e368b3', 'candidato', '2026-09-17', 1),
    (9, 'carlos.sitoe@mail.co.mz', 'd338bbc446c584119184f8494c17d84e9ab0e29cffcff05137bb428afd7255c8', 'candidato', '2026-09-28', 1),
    (10, 'dalila.mabjaia@mail.co.mz', 'd71f967a535676754f54bd171d2651107be3711a0291b96cb4226d629bfb081c', 'candidato', '2026-07-08', 1),
    (11, 'edson.muianga@mail.co.mz', 'ed718cde3efb483ad35998ecc17dda2f2395b6c622db3c7b6dced42083825aa0', 'candidato', '2026-09-20', 1),
    (12, 'fatima.cossa@mail.co.mz', 'f98e559e85f82e3dae3063a2e6f62bdc8e5ded74edce040e7ad48c9b0d823228', 'candidato', '2026-09-14', 1),
    (13, 'gilberto.tembe@mail.co.mz', 'ba0fec7fe3dfd7b18371c586dd3f5cd34474d2bd394726e7cc4bc1ad2ae3a4cb', 'candidato', '2026-09-18', 1),
    (14, 'helena.mondlane@mail.co.mz', '02ed80de4cdbb984bae28d17021dd7e0edec8cc105704aaed859df740ae5dc96', 'candidato', '2026-09-25', 1),
    (15, 'ivan.bila@mail.co.mz', '7734e1aa24fc39034faec9d20e600f86bdb2953d6aeb601b6d1e3dc8ee4c3ba1', 'candidato', '2026-08-25', 1),
    (16, 'joana.matsinhe@mail.co.mz', 'b93db47b65a956fa83e5f2987fb3cd23da23e8a17db105081819c1e5dce5cd84', 'candidato', '2026-09-15', 1),
    (17, 'kelvin.chongo@mail.co.mz', '1d73e03d6228694b54c91443b526c3028dcd67d7131f6c5fe1828324860dd3ce', 'candidato', '2026-07-01', 1),
    (18, 'lurdes.macamo@mail.co.mz', 'b011186b1ce817932672826d4e6d7625867bf2fe260c9dae423a4c2b4c7521c9', 'candidato', '2026-09-03', 1),
    (19, 'mario.nhaca@mail.co.mz', 'ed1b04554b1f18a6db5e63c8c5b471ef4f9c1bef0513554c42a1977b9f4ffe36', 'candidato', '2026-07-10', 1),
    (20, 'nelma.langa@mail.co.mz', 'af8af011d66bc9527560f9a4ce1a93747eeab8e598ce78ce6649210db2c2b3d0', 'candidato', '2026-07-15', 1),
    (21, 'osvaldo.zandamela@mail.co.mz', 'bb65bd76ecec0848321346375c767baeccd5e13991345015faf6bef4985431bc', 'candidato', '2026-07-27', 1),
    (22, 'palmira.guambe@mail.co.mz', '5af6a5f920358f9b6d44a41a4f086a2fbefa355c8e42b778577690a045952443', 'candidato', '2026-09-16', 1),
    (23, 'quiteria.mucavele@mail.co.mz', '85d66b484943d34a40d85fb0d86413689499217c13f800f65745f440c141673b', 'candidato', '2026-09-11', 1),
    (24, 'rui.machava@mail.co.mz', 'f140377f7277a411dab6415f28cd89161dbf6158b86cad802bc1557dfae0b371', 'candidato', '2026-07-13', 1),
    (25, 'sandra.cumbe@mail.co.mz', '9b002111679505c3bcb6a66bf5741247a99715ca87242392b059a392665b787c', 'candidato', '2026-08-12', 1),
    (26, 'telmo.baloi@mail.co.mz', '5a7d27c8c08270a242c9b48cd11bb72d4c949d48ec8839b35323ea3366da780f', 'candidato', '2026-08-26', 1),
    (27, 'rh@mozadigital.co.mz', '8d6e694ece11b6584e3fc3879ca1196108683a7fca6d4a61b7a9d3946ddf766b', 'empresa', '2026-08-24', 1),
    (28, 'rh@sofalasaude.co.mz', '7dac4d19e78988fd670276f0d782da20f082c2c1e376cdad795b93c92c7623da', 'empresa', '2026-09-21', 1),
    (29, 'rh@indicoconstrucoes.co.mz', '251c4f3ebf7f6723100a19e8e436350993f80ce8008ceb3cea9432793f3ddcc7', 'empresa', '2026-07-24', 1),
    (30, 'rh@savanaagro.co.mz', '4ff890a0d004ffce77ab29f22d7b7abb8616f0bff7f35162295547e52c5d2807', 'empresa', '2026-08-03', 1),
    (31, 'rh@tchovalogistica.co.mz', '151134803b2c0fd74aa1723a2378efb13e6bb2fb82acb8c248e40b6c27e3847a', 'empresa', '2026-09-18', 1),
    (32, 'rh@baobahoteis.co.mz', '79d4d6cfba860b9bf5ed82aab11f837057b92bbeb863cb60c917811cc3a2bd20', 'empresa', '2026-08-10', 1),
    (33, 'rh@zambezeenergia.co.mz', 'f3e2e5e56b58ae4f68dadf4d72f265ddd11d32c3720b77345c3f568af87d1cc0', 'empresa', '2026-08-05', 1),
    (34, 'rh@perolasuper.co.mz', 'd40738226645a0cb13eb21b36c401a0e7be854acf76afa9a5fd1d6453139b36f', 'empresa', '2026-09-23', 1),
    (35, 'rh@futurobrilhante.co.mz', '1eb021126d0f31c75889ec94792f20c72ad198b64043da1273b4c07cd170be19', 'empresa', '2026-09-19', 1),
    (36, 'rh@nacalatransportes.co.mz', '09dbc6abb8a1e035713af63f6140a4665da25dc26ad9c7678bfa7a19bd715ca9', 'empresa', '2026-08-01', 1),
    (37, 'rh@kuvumbana.co.mz', '6cd1e8f402a61322ab7843369ad7d27c51460adc4b052e864717d3853ca72c08', 'empresa', '2026-09-12', 1),
    (38, 'rh@contascertas.co.mz', '68bd773642178bd7b10c9be3d1cc8ec17cd0e737cc74508393817ab3d49d3d0a', 'empresa', '2026-08-15', 1),
    (39, 'rh@deltaseguranca.co.mz', '72d15f4ced89b75bfabe3463e112385510fc0a299277eaf30fed4616dad38ec7', 'empresa', '2026-08-03', 1),
    (40, 'rh@rovumamineracao.co.mz', '677adc325251a204eba6dc8d6b24bd35c307e453224eee053ad6342af94b1397', 'empresa', '2026-08-19', 1),
    (41, 'rh@matolamecanica.co.mz', 'b7383ad0fdf59276d43a3a997cc758135b2a630b287af8fa9b9969ac8d36e441', 'empresa', '2026-09-16', 1),
    (42, 'rh@ubuntumarketing.co.mz', 'f15f7b9673f2fc72b2d6bcc73d9a6a1d10cf2f6d8662acf454ab9a616e1175a6', 'empresa', '2026-07-14', 1),
    (43, 'rh@mavumeadvogados.co.mz', '58af72d15b9af4ded05e0f0d974c3392ab4b2613b70a0346c706893b77ee4148', 'empresa', '2026-09-26', 1),
    (44, 'rh@vidaplena.co.mz', 'f3a30ff2e3e79701dab053d72116a904102a5ca4b809761a9e7c655d97a07901', 'empresa', '2026-09-16', 1),
    (45, 'rh@saborindico.co.mz', 'f49bdd8d6042faf91703239a1a2dabecc47ee2e5cb7ea702a1707e1544a427ea', 'empresa', '2026-08-17', 1),
    (46, 'rh@horizontetelecom.co.mz', '14ad19d218b6b429a6ded0df554baab49e3d8d349add1e938b58c4d31a247c92', 'empresa', '2026-08-28', 1);

-- 20 candidatos
INSERT INTO candidato (id_candidato, id_utilizador, nome_completo, bi, data_nascimento, genero, telefone, cidade, nivel_academico, profissao, cv_ficheiro) VALUES
    (1, 7, 'Abdul Rachide Issufo', '110705590520H', '1998-03-14', 'M', '+258 86 630 1415', 'Maputo', 'Licenciatura', 'Técnico de Informática', 'cv_abdul_issufo.pdf'),
    (2, 8, 'Ana Paula Nhantumbo', '100922299757C', '1996-07-22', 'F', '+258 82 821 9572', 'Beira', 'Licenciatura', 'Enfermeira', 'cv_ana_nhantumbo.pdf'),
    (3, 9, 'Carlos Manuel Sitoe', '100870203091K', '1992-11-05', 'M', '+258 85 581 3333', 'Maputo', 'Licenciatura', 'Engenheiro Civil', 'cv_carlos_sitoe.pdf'),
    (4, 10, 'Dalila Mabjaia', '110345808782B', '1994-02-18', 'F', '+258 87 817 8484', 'Quelimane', 'Licenciatura', 'Professora', NULL),
    (5, 11, 'Edson Muianga', '110867213565J', '2000-09-30', 'M', '+258 84 673 7587', 'Maputo', 'Licenciatura', 'Programador Web', 'cv_edson_muianga.pdf'),
    (6, 12, 'Fátima Cossa', '110688570007J', '1995-05-11', 'F', '+258 87 590 7585', 'Matola', 'Licenciatura', 'Contabilista', 'cv_fatima_cossa.pdf'),
    (7, 13, 'Gilberto Tembe', '110317466370E', '1990-12-02', 'M', '+258 84 109 1542', 'Beira', 'Ensino Médio', 'Motorista', NULL),
    (8, 14, 'Helena Mondlane', '100803990996K', '1999-04-25', 'F', '+258 85 922 9567', 'Inhambane', 'Técnico Médio', 'Rececionista', 'cv_helena_mondlane.pdf'),
    (9, 15, 'Ivan Bila', '110486478187D', '2001-08-08', 'M', '+258 84 809 8955', 'Maputo', 'Técnico Médio', 'Técnico de Redes', NULL),
    (10, 16, 'Joana Matsinhe', '110648968520H', '1993-01-19', 'F', '+258 85 671 1550', 'Beira', 'Licenciatura', 'Enfermeira', 'cv_joana_matsinhe.pdf'),
    (11, 17, 'Kelvin Chongo', '110440007977H', '1997-06-13', 'M', '+258 82 548 9440', 'Matola', 'Técnico Médio', 'Mecânico Auto', NULL),
    (12, 18, 'Lurdes Macamo', '110586319898C', '1998-10-27', 'F', '+258 85 962 8850', 'Maputo', 'Ensino Médio', 'Vendedora', NULL),
    (13, 19, 'Mário Nhaca', '100796373372E', '1989-03-09', 'M', '+258 85 479 2583', 'Matola', 'Ensino Médio', 'Pedreiro', NULL),
    (14, 20, 'Nelma Langa', '100902677112G', '1996-12-15', 'F', '+258 83 560 1229', 'Maputo', 'Licenciatura', 'Técnica de Recursos Humanos', 'cv_nelma_langa.pdf'),
    (15, 21, 'Osvaldo Zandamela', '100100229748H', '1991-07-04', 'M', '+258 86 659 2360', 'Tete', 'Técnico Médio', 'Eletricista Industrial', 'cv_osvaldo_zandamela.pdf'),
    (16, 22, 'Palmira Guambe', '100366113609B', '1999-11-21', 'F', '+258 86 145 9953', 'Maputo', 'Licenciatura', 'Gestora de Marketing', 'cv_palmira_guambe.pdf'),
    (17, 23, 'Quitéria Mucavele', '110817771848F', '2000-02-06', 'F', '+258 83 105 6135', 'Maputo', 'Licenciatura', 'Jurista', 'cv_quiteria_mucavele.pdf'),
    (18, 24, 'Rui Machava', '110840620525C', '1994-09-17', 'M', '+258 86 328 8749', 'Maputo', 'Ensino Médio', 'Agente de Segurança', NULL),
    (19, 25, 'Sandra Cumbe', '100742244082J', '1997-01-28', 'F', '+258 84 186 7844', 'Beira', 'Técnico Médio', 'Cozinheira', NULL),
    (20, 26, 'Telmo Baloi', '100245326801K', '1995-08-03', 'M', '+258 84 619 7750', 'Chimoio', 'Mestrado', 'Técnico Agrário', 'cv_telmo_baloi.pdf');

-- 33 experiências profissionais (entidade fraca)
INSERT INTO experiencia_profissional (id_candidato, num_experiencia, cargo, empresa_anterior, data_inicio, data_fim, descricao) VALUES
    (1, 1, 'Técnico de Suporte', 'Cyber Centro Maputo', '2020-02-01', '2022-12-31', 'Manutenção de computadores e apoio a clientes.'),
    (1, 2, 'Técnico de Informática', 'Colégio Horizonte', '2023-02-01', NULL, 'Gestão do laboratório de informática e da rede da escola.'),
    (2, 1, 'Enfermeira Estagiária', 'Posto de Saúde Esperança', '2019-03-01', '2020-02-28', 'Triagem de doentes e administração de vacinas.'),
    (2, 2, 'Enfermeira', 'Clínica Vida Nova', '2020-04-01', NULL, 'Cuidados de enfermagem em internamento.'),
    (3, 1, 'Engenheiro Estagiário', 'Construtora Alicerce', '2015-01-10', '2016-06-30', 'Acompanhamento de obras e medições.'),
    (3, 2, 'Engenheiro Civil', 'Construtora Alicerce', '2016-07-01', '2026-03-31', 'Direção técnica de obras de habitação.'),
    (4, 1, 'Professora do Ensino Primário', 'Escola Primária Nova Esperança', '2017-02-01', '2022-11-30', 'Lecionação da 4.ª e 5.ª classes.'),
    (5, 1, 'Estagiário de Desenvolvimento', 'Web Criativa Lda', '2023-01-15', '2023-12-15', 'Desenvolvimento de sites com HTML, CSS e PHP.'),
    (5, 2, 'Programador Web Freelancer', 'Trabalho por conta própria', '2024-01-10', NULL, 'Criação de sites e sistemas para pequenos negócios.'),
    (6, 1, 'Assistente Contabilista', 'Gabinete Numerus', '2018-05-02', '2021-04-30', 'Lançamentos contabilísticos e IVA.'),
    (6, 2, 'Contabilista', 'Comercial Matola Lda', '2021-05-03', NULL, 'Fecho de contas mensal e relatórios fiscais.'),
    (7, 1, 'Motorista de Pesados', 'Transportes Rápido do Centro', '2012-03-01', '2018-08-31', 'Transporte de mercadorias entre Beira e Maputo.'),
    (7, 2, 'Motorista de Pesados', 'Cargas do Zambeze', '2018-09-10', '2026-05-30', 'Transporte de carga a granel para Tete.'),
    (8, 1, 'Rececionista', 'Pensão Mar Azul', '2020-01-06', NULL, 'Receção, reservas e atendimento a hóspedes.'),
    (9, 1, 'Estagiário de Redes', 'Net Maputo Serviços', '2022-06-01', '2023-05-31', 'Instalação de cabos e configuração de routers.'),
    (10, 1, 'Enfermeira', 'Hospital Privado Sol Nascente', '2017-01-09', '2021-12-31', 'Enfermagem em bloco operatório.'),
    (10, 2, 'Enfermeira Chefe de Turno', 'Clínica Santa Luzia', '2022-01-10', NULL, 'Coordenação da equipa de enfermagem.'),
    (11, 1, 'Ajudante de Mecânico', 'Oficina Auto Rápida', '2018-02-01', '2020-12-31', 'Troca de óleo, travões e suspensões.'),
    (11, 2, 'Mecânico Auto', 'Oficina Auto Rápida', '2021-01-04', NULL, 'Diagnóstico e reparação de motores.'),
    (12, 1, 'Vendedora', 'Loja Moda Bonita', '2019-08-01', '2024-03-31', 'Atendimento, vendas e controlo de caixa.'),
    (13, 1, 'Pedreiro', 'Construções Mavila', '2010-04-01', '2019-12-31', 'Alvenaria, rebocos e acabamentos.'),
    (13, 2, 'Encarregado de Obra', 'Construções Mavila', '2020-01-06', NULL, 'Coordenação de equipas de pedreiros.'),
    (14, 1, 'Assistente de Recursos Humanos', 'Grupo Empresarial Kuhluka', '2019-03-01', '2022-09-30', 'Processamento de salários e contratos.'),
    (14, 2, 'Técnica de Recursos Humanos', 'Consultora Pessoas e Talentos', '2022-10-03', NULL, 'Recrutamento e seleção de pessoal.'),
    (15, 1, 'Eletricista', 'Eletro Tete Lda', '2014-05-05', '2020-02-28', 'Instalações elétricas em edifícios.'),
    (15, 2, 'Eletricista Industrial', 'Mineira do Vale Lda', '2020-03-02', NULL, 'Manutenção de quadros e motores elétricos.'),
    (16, 1, 'Assistente de Marketing', 'Agência Cor Viva', '2021-02-01', '2023-06-30', 'Gestão de redes sociais e campanhas.'),
    (17, 1, 'Estagiária Jurídica', 'Escritório Justiça e Direito', '2023-03-01', '2024-02-29', 'Redação de contratos e pesquisa jurídica.'),
    (18, 1, 'Agente de Segurança', 'Guarda Forte Lda', '2015-09-01', '2022-12-31', 'Vigilância de instalações comerciais.'),
    (18, 2, 'Supervisor de Segurança', 'Guarda Forte Lda', '2023-01-02', NULL, 'Chefia de equipas de vigilância.'),
    (19, 1, 'Ajudante de Cozinha', 'Restaurante Mar e Sol', '2018-03-01', '2021-02-28', 'Preparação de ingredientes e limpeza.'),
    (19, 2, 'Cozinheira', 'Restaurante Mar e Sol', '2021-03-01', NULL, 'Confeção de pratos de peixe e marisco.'),
    (20, 1, 'Técnico Agrário', 'Cooperativa Terra Fértil', '2019-01-07', NULL, 'Apoio técnico a pequenos produtores.');

-- 20 empresas
INSERT INTO empresa (id_empresa, id_utilizador, nome, nuit, setor, cidade, telefone, email_contacto) VALUES
    (1, 27, 'Moza Digital Lda', '452399581', 'Tecnologias de Informação', 'Maputo', '+258 83 632 4222', 'rh@mozadigital.co.mz'),
    (2, 28, 'Clínica Sofala Saúde', '450466696', 'Saúde', 'Beira', '+258 82 208 7379', 'rh@sofalasaude.co.mz'),
    (3, 29, 'Índico Construções SA', '409856055', 'Construção Civil', 'Maputo', '+258 82 953 6685', 'rh@indicoconstrucoes.co.mz'),
    (4, 30, 'Savana Agro Lda', '486741219', 'Agricultura', 'Chimoio', '+258 84 888 1422', 'rh@savanaagro.co.mz'),
    (5, 31, 'Tchova Logística Lda', '403433596', 'Logística e Transportes', 'Beira', '+258 86 587 6370', 'rh@tchovalogistica.co.mz'),
    (6, 32, 'Baobá Hotéis e Resorts', '491643123', 'Hotelaria e Turismo', 'Inhambane', '+258 84 560 6341', 'rh@baobahoteis.co.mz'),
    (7, 33, 'Zambeze Energia SA', '416290387', 'Energia', 'Tete', '+258 85 577 3797', 'rh@zambezeenergia.co.mz'),
    (8, 34, 'Pérola Supermercados', '420654844', 'Comércio', 'Maputo', '+258 86 632 4391', 'rh@perolasuper.co.mz'),
    (9, 35, 'Escola Futuro Brilhante', '458197822', 'Educação', 'Quelimane', '+258 86 444 8517', 'rh@futurobrilhante.co.mz'),
    (10, 36, 'Nacala Transportes Lda', '480291676', 'Logística e Transportes', 'Nampula', '+258 83 794 2138', 'rh@nacalatransportes.co.mz'),
    (11, 37, 'Kuvumbana Consultoria', '473464604', 'Recursos Humanos', 'Maputo', '+258 85 134 4202', 'rh@kuvumbana.co.mz'),
    (12, 38, 'Contas Certas e Auditoria', '486869801', 'Contabilidade e Finanças', 'Maputo', '+258 83 146 9925', 'rh@contascertas.co.mz'),
    (13, 39, 'Delta Segurança Lda', '406467611', 'Segurança', 'Maputo', '+258 85 988 4088', 'rh@deltaseguranca.co.mz'),
    (14, 40, 'Rovuma Mineração Lda', '464940010', 'Energia e Minas', 'Tete', '+258 87 794 1335', 'rh@rovumamineracao.co.mz'),
    (15, 41, 'Matola Mecânica Auto', '417332847', 'Mecânica e Manutenção', 'Matola', '+258 87 642 4583', 'rh@matolamecanica.co.mz'),
    (16, 42, 'Ubuntu Marketing', '469370789', 'Marketing e Comunicação', 'Maputo', '+258 83 264 4047', 'rh@ubuntumarketing.co.mz'),
    (17, 43, 'Mavume e Associados, Advogados', '452341080', 'Direito', 'Maputo', '+258 84 535 9732', 'rh@mavumeadvogados.co.mz'),
    (18, 44, 'Farmácia Vida Plena', '455577787', 'Saúde', 'Nampula', '+258 82 492 5995', 'rh@vidaplena.co.mz'),
    (19, 45, 'Sabor do Índico Restaurantes', '425125395', 'Restauração', 'Beira', '+258 84 278 5316', 'rh@saborindico.co.mz'),
    (20, 46, 'Horizonte Telecom', '462265651', 'Telecomunicações', 'Maputo', '+258 85 898 7811', 'rh@horizontetelecom.co.mz');

-- 26 vagas
INSERT INTO vaga (id_vaga, id_empresa, id_area, titulo, descricao, localidade, salario, tipo_contrato, data_publicacao, prazo_candidatura, estado) VALUES
    (1, 1, 1, 'Programador Web Júnior', 'Desenvolvimento e manutenção de aplicações web em PHP e MySQL.', 'Maputo', 28000, 'Efetivo', '2026-09-01', '2026-10-31', 'aberta'),
    (2, 1, 1, 'Técnico de Suporte Informático', 'Apoio a utilizadores e manutenção de equipamentos.', 'Maputo', 22000, 'Efetivo', '2026-09-10', '2026-11-10', 'aberta'),
    (3, 2, 2, 'Enfermeiro Geral', 'Cuidados de enfermagem em consulta externa e internamento.', 'Beira', 25000, 'Efetivo', '2026-08-20', '2026-10-20', 'aberta'),
    (4, 2, 16, 'Rececionista de Clínica', 'Atendimento de pacientes e marcação de consultas.', 'Beira', 15000, 'Prazo certo', '2026-09-05', '2026-10-05', 'fechada'),
    (5, 3, 4, 'Pedreiro Encarregado', 'Chefia de equipa de pedreiros em obra de habitação.', 'Matola', 18000, 'Prazo certo', '2026-09-12', '2026-11-12', 'aberta'),
    (6, 3, 10, 'Engenheiro Civil', 'Direção técnica e fiscalização de obras.', 'Maputo', 55000, 'Efetivo', '2026-08-15', '2026-10-15', 'preenchida'),
    (7, 4, 9, 'Técnico Agrário', 'Apoio técnico a produtores e controlo de culturas.', 'Chimoio', 20000, 'Efetivo', '2026-09-18', '2026-11-18', 'aberta'),
    (8, 5, 7, 'Motorista de Pesados', 'Transporte de carga em rotas nacionais.', 'Beira', 21000, 'Efetivo', '2026-09-20', '2026-11-20', 'aberta'),
    (9, 5, 7, 'Assistente de Logística', 'Gestão de stocks e expedição de mercadorias.', 'Maputo', 19000, 'Efetivo', '2026-10-01', '2026-12-01', 'aberta'),
    (10, 6, 8, 'Rececionista de Hotel', 'Check-in, check-out e reservas.', 'Inhambane', 16000, 'Efetivo', '2026-09-08', '2026-10-30', 'aberta'),
    (11, 6, 20, 'Cozinheiro', 'Preparação de refeições para o restaurante do hotel.', 'Inhambane', 17000, 'Prazo certo', '2026-09-25', '2026-11-25', 'aberta'),
    (12, 7, 18, 'Técnico de Eletricidade', 'Manutenção de redes e subestações elétricas.', 'Tete', 32000, 'Efetivo', '2026-08-25', '2026-10-10', 'fechada'),
    (13, 8, 6, 'Operador de Caixa', 'Atendimento e registo de vendas em caixa.', 'Maputo', 12000, 'Part-time', '2026-10-02', '2026-12-02', 'aberta'),
    (14, 8, 6, 'Gestor de Loja', 'Gestão de equipa, stocks e resultados da loja.', 'Matola', 35000, 'Efetivo', '2026-09-14', '2026-11-14', 'aberta'),
    (15, 9, 3, 'Professor de Matemática', 'Lecionação de Matemática do ensino secundário.', 'Quelimane', 24000, 'Efetivo', '2026-09-03', '2026-10-25', 'aberta'),
    (16, 10, 7, 'Despachante de Transportes', 'Planeamento de viagens e controlo de motoristas.', 'Nampula', 17000, 'Efetivo', '2026-10-05', '2026-12-05', 'aberta'),
    (17, 11, 11, 'Técnico de Recursos Humanos', 'Recrutamento, formação e processamento salarial.', 'Maputo', 30000, 'Efetivo', '2026-09-22', '2026-11-22', 'aberta'),
    (18, 12, 5, 'Assistente Contabilista', 'Lançamentos contabilísticos e apoio ao fecho de contas.', 'Maputo', 26000, 'Efetivo', '2026-09-28', '2026-11-28', 'aberta'),
    (19, 13, 14, 'Agente de Segurança', 'Vigilância e controlo de acessos.', 'Maputo', 11000, 'Efetivo', '2026-10-03', '2026-12-03', 'aberta'),
    (20, 14, 18, 'Técnico de Minas', 'Apoio técnico às operações de extração.', 'Tete', 48000, 'Efetivo', '2026-08-30', '2026-10-30', 'aberta'),
    (21, 15, 17, 'Mecânico Auto', 'Diagnóstico e reparação de viaturas ligeiras e pesadas.', 'Matola', 20000, 'Efetivo', '2026-09-16', '2026-11-16', 'aberta'),
    (22, 16, 12, 'Gestor de Redes Sociais', 'Criação de conteúdos e gestão de campanhas digitais.', 'Maputo', 23000, 'Prazo certo', '2026-09-29', '2026-11-29', 'aberta'),
    (23, 17, 13, 'Estagiário de Direito', 'Apoio na redação de contratos e pareceres.', 'Maputo', 9000, 'Estágio', '2026-10-06', '2026-12-06', 'aberta'),
    (24, 18, 2, 'Técnico de Farmácia', 'Dispensa de medicamentos e gestão de stock.', 'Nampula', 22000, 'Efetivo', '2026-09-07', '2026-10-07', 'fechada'),
    (25, 19, 20, 'Empregado de Mesa', 'Serviço de mesa e atendimento a clientes.', 'Beira', 13000, 'Part-time', '2026-10-08', '2026-12-08', 'aberta'),
    (26, 20, 1, 'Técnico de Redes e Telecomunicações', 'Instalação e manutenção de redes de dados.', 'Maputo', 30000, 'Efetivo', '2026-10-09', '2026-12-09', 'aberta');

-- 32 candidaturas
INSERT INTO candidatura (id_candidatura, id_candidato, id_vaga, data_candidatura, estado) VALUES
    (1, 1, 1, '2026-09-05', 'entrevista_agendada'),
    (2, 5, 1, '2026-09-08', 'em_analise'),
    (3, 9, 1, '2026-09-12', 'rejeitada'),
    (4, 1, 2, '2026-09-15', 'submetida'),
    (5, 5, 2, '2026-09-16', 'em_analise'),
    (6, 2, 3, '2026-08-25', 'entrevista_agendada'),
    (7, 10, 3, '2026-08-28', 'em_analise'),
    (8, 10, 4, '2026-09-08', 'aceite'),
    (9, 3, 6, '2026-08-18', 'aceite'),
    (10, 13, 5, '2026-09-15', 'em_analise'),
    (11, 13, 6, '2026-08-20', 'rejeitada'),
    (12, 20, 7, '2026-09-20', 'submetida'),
    (13, 7, 8, '2026-09-22', 'entrevista_agendada'),
    (14, 7, 9, '2026-10-03', 'submetida'),
    (15, 8, 10, '2026-09-10', 'entrevista_agendada'),
    (16, 19, 11, '2026-09-27', 'em_analise'),
    (17, 15, 12, '2026-08-28', 'aceite'),
    (18, 15, 20, '2026-09-02', 'entrevista_agendada'),
    (19, 12, 13, '2026-10-04', 'submetida'),
    (20, 12, 14, '2026-09-16', 'em_analise'),
    (21, 4, 15, '2026-09-06', 'entrevista_agendada'),
    (22, 14, 17, '2026-09-24', 'entrevista_agendada'),
    (23, 6, 18, '2026-09-30', 'em_analise'),
    (24, 18, 19, '2026-10-05', 'submetida'),
    (25, 11, 21, '2026-09-18', 'entrevista_agendada'),
    (26, 16, 22, '2026-10-01', 'em_analise'),
    (27, 17, 23, '2026-10-08', 'submetida'),
    (28, 2, 24, '2026-09-09', 'rejeitada'),
    (29, 19, 25, '2026-10-10', 'submetida'),
    (30, 9, 26, '2026-10-11', 'em_analise'),
    (31, 1, 26, '2026-10-12', 'submetida'),
    (32, 5, 26, '2026-10-12', 'em_analise');

-- 22 entrevistas
INSERT INTO entrevista (id_entrevista, id_candidatura, id_funcionario, data_hora, local, resultado) VALUES
    (1, 1, 3, '2026-09-25 10:00:00', 'Sede da agência - Sala 1', 'aprovado'),
    (2, 1, 4, '2026-10-22 09:30:00', 'Escritório da empresa - Maputo', 'pendente'),
    (3, 6, 3, '2026-09-10 14:00:00', 'Sede da agência - Sala 2', 'aprovado'),
    (4, 6, 5, '2026-10-24 10:00:00', 'Clínica Sofala Saúde - Beira', 'pendente'),
    (5, 13, 4, '2026-10-20 11:00:00', 'Sede da agência - Sala 1', 'pendente'),
    (6, 15, 6, '2026-10-21 15:00:00', 'Baobá Hotéis - Inhambane', 'pendente'),
    (7, 18, 3, '2026-10-19 09:00:00', 'Rovuma Mineração - Tete', 'pendente'),
    (8, 21, 5, '2026-10-23 09:00:00', 'Escola Futuro Brilhante - Quelimane', 'pendente'),
    (9, 22, 4, '2026-10-22 14:30:00', 'Sede da agência - Sala 3', 'pendente'),
    (10, 25, 6, '2026-10-18 08:30:00', 'Matola Mecânica Auto - Matola', 'pendente'),
    (11, 8, 3, '2026-09-20 10:00:00', 'Clínica Sofala Saúde - Beira', 'aprovado'),
    (12, 9, 4, '2026-09-01 09:00:00', 'Sede da agência - Sala 1', 'aprovado'),
    (13, 9, 4, '2026-09-08 09:00:00', 'Índico Construções - Maputo', 'aprovado'),
    (14, 17, 5, '2026-09-10 11:00:00', 'Zambeze Energia - Tete', 'aprovado'),
    (15, 17, 6, '2026-09-17 11:00:00', 'Zambeze Energia - Tete', 'aprovado'),
    (16, 3, 6, '2026-09-20 10:00:00', 'Sede da agência - Sala 2', 'reprovado'),
    (17, 11, 3, '2026-08-28 10:00:00', 'Índico Construções - Maputo', 'reprovado'),
    (18, 28, 4, '2026-09-14 13:00:00', 'Farmácia Vida Plena - Nampula', 'reprovado'),
    (19, 7, 3, '2026-10-05 09:00:00', 'Sede da agência - Sala 1', 'aprovado'),
    (20, 20, 5, '2026-10-06 10:00:00', 'Pérola Supermercados - Matola', 'aprovado'),
    (21, 16, 6, '2026-10-12 15:00:00', 'Baobá Hotéis - Inhambane', 'aprovado'),
    (22, 23, 4, '2026-10-13 10:00:00', 'Contas Certas e Auditoria - Maputo', 'aprovado');

-- Fim do script. Verificação rápida (opcional):
-- SELECT 'vaga' AS tabela, COUNT(*) AS total FROM vaga UNION ALL SELECT 'candidatura', COUNT(*) FROM candidatura;
