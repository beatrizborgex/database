-- ALUNA: BEATRIZ BORGES DE OLIVEIRA
-- BD TERCEIRIZADOS FIOCRUZ

CREATE OR REPLACE FUNCTION executar_script () 
RETURNS TABLE 
    (
    instituicao_id INT,
    instituicao_nome VARCHAR(150),
    funcionario_id INT,
    nome_funcionario TEXT,
    CPF_funcionario TEXT,
    escolaridade TEXT,
    cbo_id INT,
    cbo_descricao VARCHAR(200),
    id_unidade_contratante INT,
    unidade_contratante VARCHAR(150),
    id_local_trabalho INT,
    local_trabalho VARCHAR(200),
    id_contrato INT,
    num_contrato TEXT,
    salario TEXT,
    obj_do_contrato TEXT,
    data_inicio_contrato DATE,
    data_termino_contrato DATE 
    )
AS $$ 
DECLARE 
    ENCRYPTION_KEY TEXT;
BEGIN
-------------------------------------------------------DROP'S NECESSÁRIOS-------------------------------------------------
    DROP VIEW IF EXISTS seguranca.view_dados;
    DROP TABLE IF EXISTS contrato CASCADE;
    DROP TABLE IF EXISTS cbo CASCADE;
    DROP TABLE IF EXISTS terceirizado;
    DROP TABLE IF EXISTS funcionario;
    DROP TABLE IF EXISTS unidade_contratante;
    DROP TABLE IF EXISTS local_trabalho;
    DROP TABLE IF EXISTS instituicao;
    DROP SCHEMA IF EXISTS seguranca CASCADE;
    DROP TABLE IF EXISTS seguranca.configuracoes;
-----------------------------------------------IMPORTANDO CSV-----------------------------------------------
    CREATE TABLE public.terceirizado 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        instituicao VARCHAR(150) NOT NULL,
        nome_funcionario VARCHAR(255) NOT NULL,
        posto VARCHAR(150),
        salario DECIMAL(10, 2),
        atividade VARCHAR(1000),
        cpf VARCHAR(20) NOT NULL,
        data_inicio_contrato DATE NOT NULL,
        data_termino_contrato DATE NOT NULL,
        num_contrato VARCHAR(20) NOT NULL,
        obj_do_contrato TEXT NOT NULL,
        cnpj VARCHAR(20) NOT NULL,
        escolaridade VARCHAR(200) NOT NULL,
        local_de_trabalho VARCHAR(200) NOT NULL,
        data_de_admissao DATE NOT NULL,
        data_de_desligamento DATE NOT NULL,
        unidade_contratante VARCHAR(150),
        cbo VARCHAR(200)
    );

    COPY terceirizado (instituicao, nome_funcionario, posto, salario, atividade, cpf, data_inicio_contrato, data_termino_contrato, num_contrato, obj_do_contrato, cnpj, escolaridade, local_de_trabalho, data_de_admissao, data_de_desligamento, unidade_contratante, cbo)
    FROM '/dados/trabalho2/trabalho_pronto/terceirizado.csv' DELIMITER ';' CSV HEADER;

-----------------------------------------------CRIANDO TABELAS NORMALIZADAS-----------------------------------------------
    CREATE TABLE public.instituicao 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        nome VARCHAR(150) NOT NULL
    );

    CREATE TABLE public.cbo 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        descricao_cbo VARCHAR(200) 
    );

    CREATE TABLE public.funcionario 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        nome VARCHAR(255) NOT NULL,
        cpf VARCHAR(150) NOT NULL,
        escolaridade VARCHAR(200) NOT NULL,
        cbo_id INT REFERENCES cbo(id) NOT NULL
    );

    CREATE TABLE public.unidade_contratante 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        nome_unidade VARCHAR(150) NOT NULL
    );

    CREATE TABLE public.local_trabalho 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        nome_local VARCHAR(200) NOT NULL
    );

    CREATE TABLE public.contrato 
    (
        id SERIAL PRIMARY KEY NOT NULL,
        num_contrato VARCHAR(150) NOT NULL,
        instituicao_id INT REFERENCES instituicao(id) NOT NULL,
        funcionario_id INT REFERENCES funcionario(id) NOT NULL,
        salario VARCHAR(150) NOT NULL,
        obj_do_contrato TEXT NOT NULL,
        data_inicio_contrato DATE NOT NULL,
        data_termino_contrato DATE NOT NULL,
        local_trabalho_id INT REFERENCES local_trabalho(id) NOT NULL,
        unidade_contratante_id INT REFERENCES unidade_contratante(id) NOT NULL
    );
-----------------------------------------------INSERINDO DADOS NAS TABELAS-----------------------------------------------
    INSERT INTO cbo (descricao_cbo)
    SELECT DISTINCT t.cbo
    FROM terceirizado t;

    INSERT INTO instituicao (nome)
    SELECT DISTINCT t.instituicao
    FROM terceirizado t;

    INSERT INTO funcionario (nome, cpf, escolaridade, cbo_id)
    SELECT DISTINCT t.nome_funcionario, t.cpf, t.escolaridade, cbo.id
    FROM terceirizado t
    JOIN cbo ON t.cbo = cbo.descricao_cbo;

    INSERT INTO unidade_contratante (nome_unidade)
    SELECT DISTINCT t.unidade_contratante
    FROM terceirizado t;

    INSERT INTO local_trabalho (nome_local)
    SELECT DISTINCT t.local_de_trabalho
    FROM terceirizado t;

    INSERT INTO contrato (num_contrato, obj_do_contrato, salario, data_inicio_contrato, data_termino_contrato, instituicao_id, funcionario_id, local_trabalho_id, unidade_contratante_id)
    SELECT DISTINCT t.num_contrato, t.obj_do_contrato, t.salario, t.data_inicio_contrato, t.data_termino_contrato, i.id, f.id, lt.id, uc.id
    FROM terceirizado t
    JOIN instituicao i ON t.instituicao = i.nome
    JOIN funcionario f ON t.cpf = f.cpf
    JOIN local_trabalho lt ON t.local_de_trabalho = lt.nome_local
    JOIN unidade_contratante uc ON t.unidade_contratante = uc.nome_unidade;
-----------------------------------------------TABELA PARA ARMAZENAR A CHAVE DE CRIPTOGRAFIA-----------------------------------------------
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    CREATE SCHEMA seguranca;

    CREATE TABLE seguranca.configuracoes 
    (
    chave VARCHAR(255) PRIMARY KEY,
    valor TEXT
    );

    INSERT INTO seguranca.configuracoes (chave, valor) VALUES ('ENCRYPTION_KEY', gen_salt('bf'));
    SELECT valor INTO ENCRYPTION_KEY FROM seguranca.configuracoes WHERE chave = 'ENCRYPTION_KEY';
-----------------------------------------------INICIANDO CRIPTOGRAFIA-----------------------------------------------
    ALTER TABLE contrato
    ALTER COLUMN num_contrato TYPE VARCHAR(300); 

    ALTER TABLE contrato
    ALTER COLUMN salario TYPE VARCHAR(300); 

    ALTER TABLE funcionario
    ALTER COLUMN nome TYPE VARCHAR(400);

    ALTER TABLE funcionario
    ALTER COLUMN cpf TYPE VARCHAR(300);

UPDATE funcionario
SET nome = pgp_sym_encrypt(funcionario.nome, ENCRYPTION_KEY),
    cpf = pgp_sym_encrypt(funcionario.cpf,ENCRYPTION_KEY),
    escolaridade = pgp_sym_encrypt(funcionario.escolaridade, ENCRYPTION_KEY);

UPDATE contrato 
SET num_contrato = pgp_sym_encrypt(contrato.num_contrato, ENCRYPTION_KEY),
    salario = pgp_sym_encrypt(contrato.salario, ENCRYPTION_KEY);

-----------------------------------------------CRIANDO VIEW-----------------------------------------------
EXECUTE 'CREATE OR REPLACE VIEW seguranca.view_dados AS 
        SELECT
            inst.id AS instituicao_id,
            inst.nome AS instituicao_nome,
            funcionario.id AS funcionario_id,
            pgp_sym_decrypt(funcionario.nome::bytea, ''' || ENCRYPTION_KEY || ''')::TEXT AS nome_funcionario,
            pgp_sym_decrypt(funcionario.cpf::bytea, ''' || ENCRYPTION_KEY || ''')::TEXT AS CPF_funcionario,
            pgp_sym_decrypt(funcionario.escolaridade::bytea, ''' || ENCRYPTION_KEY || ''')::TEXT AS escolaridade,
            cbo.id AS cbo_id,
            cbo.descricao_cbo AS cbo_descricao,
            unidade_contratante.id AS id_unidade_contratante,
            unidade_contratante.nome_unidade AS unidade_contratante,
            local_trabalho.id AS id_local_trabalho,
            local_trabalho.nome_local AS local_trabalho,
            c.id AS id_contrato,
            pgp_sym_decrypt(c.num_contrato::bytea, ''' || ENCRYPTION_KEY || ''')::TEXT AS num_contrato,
            pgp_sym_decrypt(c.salario::bytea, ''' || ENCRYPTION_KEY || ''')::TEXT AS salario,
            c.obj_do_contrato AS obj_do_contrato,
            c.data_inicio_contrato AS data_inicio_contrato,
            c.data_termino_contrato AS data_termino_contrato
        FROM
            contrato c 
        JOIN
            instituicao inst ON inst.id = c.instituicao_id
        JOIN
            funcionario ON funcionario.id = c.funcionario_id
        JOIN
            cbo ON cbo.id = funcionario.cbo_id 
        JOIN
            unidade_contratante ON unidade_contratante.id = c.unidade_contratante_id
        JOIN
            local_trabalho ON local_trabalho.id = c.local_trabalho_id;';

RETURN QUERY SELECT * FROM seguranca.view_dados;

DROP TABLE terceirizado;

END $$ LANGUAGE plpgsql;
