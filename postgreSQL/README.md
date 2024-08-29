# Database Project - PostgreSQL

## Descrição
Este repositório contém o projeto acadêmico desenvolvido para a disciplina de Banco de Dados, utilizando PostgreSQL. 
As instruções do professor da disciplina para o desenvolvimento do projeto eram as seguintes:

### O que fazer?

Acesse o portal de dados abertos do governo federal https://dados.gov.br/dados/conjuntos-dados e faça download de um dataset não normalizado, em formato csv, com pelo menos 1000 registros. Case desejar você pode converter o dataset para o formato csv.

Para um SGBD PostgreSQL, crie uma função (stored procedure) que:
            
            Faça a importação dos dados do arquivo csv para uma tabela física do BD, criada dentro da procedure;
            Normalize os dados: criação das tabelas e inserção/atualização dos dados;
            Criptografe os dados sensíveis; Caso seu dataset não tiver dados sensíveis criptografe ao menos 5 informações importantes;
            Crie uma visão de banco de dados, que denormalize e descriptografe os dados;
            Retorne corretamente uma tabela com os dados da visão;

Observação: todos os objetos devem ser criados/recriados dentro da função, dentre eles:

            tabelas;
            chaves primárias;
            chaves estrangeiras;
            visão;
                        
#####       Faça a chamada para a função criada, que deve executar corretamente E sem interrupções!

### O que devo entregar?

            script no formato .sql;
            arquivo(s) .csv utilizado(s) para importação dos dados;
            relatório técnico descrevendo as atividades desenvolvidas;
            Projeto físico simplificado do BD resultante - arquivo do projeto e imagem no relatório;


## Estrutura do Repositório
- **data/**: Contém o dataset utilizado para a importação.
- **scripts/**: Contém o script SQL que realiza todas as operações solicitadas.
- **docs/**: Contém o relatório técnico e imagem do projeto físico do banco de dados.

## Instruções de Uso
1. Clone este repositório.
2. Execute o script SQL localizado na pasta `scripts/` dentro de um ambiente PostgreSQL configurado.
3. O dataset necessário para a execução está localizado na pasta `data/`.


