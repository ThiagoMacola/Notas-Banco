CREATE TABLE Curso
(
	nome_curso VARCHAR(20) NOT NULL,
	CONSTRAINT pkcurso PRIMARY KEY(nome_curso) 
);

CREATE TABLE Aluno
(
	ra INT NOT NULL,
	nome_aluno VARCHAR(50) NOT NULL,
	end_logradouro VARCHAR(20),
	end_numero VARCHAR(10) NOT NULL,
	end_bairro VARCHAR(20),
	end_cep CHAR(8) NOT NULL,
	end_localidade VARCHAR(20),
	end_uf VARCHAR(2),
	nome_curso VARCHAR(20) NOT NULL,
	
	CONSTRAINT fkNomeAluno_curso FOREIGN KEY (nome_curso) REFERENCES Curso(nome_curso),
	CONSTRAINT pkAlunoRA PRIMARY KEY(ra) 
);
CREATE TABLE FoneAluno
(
	ra INT NOT NULL,
	numero CHAR(11) NOT NULL,
	tipo VARCHAR(20) NOT NULL,

	CONSTRAINT fkFoneAlunoRa FOREIGN KEY(ra) REFERENCES Aluno(ra),
	CONSTRAINT pkFoneAlunoRaNumero PRIMARY KEY(ra,numero)
);

CREATE TABLE Disciplina
(	
	nome_disciplina VARCHAR(20) NOT NULL,
	qtd_aula INT NOT NULL,
	nome_curso VARCHAR(20) NOT NULL,

	CONSTRAINT fkDisciplinaNomeCurso FOREIGN KEY(nome_curso) REFERENCES Curso(nome_curso),
	CONSTRAINT pkDisciplinaNomeDisciplina PRIMARY KEY(nome_disciplina)
);

-- TABELA ALUNO DISCIPLINA
CREATE TABLE Possui
(
	ra INT NOT NULL,
	nome_disciplina VARCHAR(20)NOT NULL,
	semestre INT NOT NULL,
	falta INT ,
	situacao VARCHAR(20),
	ano INT NOT NULL,
	nota_b1 DECIMAL(4,2),
	nota_b2 DECIMAL(4,2),
	sub DECIMAL(4,2),

	CONSTRAINT fkPossuiRa FOREIGN KEY(ra) REFERENCES Aluno(ra),
	CONSTRAINT fkPossuiNomeDisciplina FOREIGN KEY(nome_disciplina) REFERENCES Disciplina(nome_disciplina),
	CONSTRAINT pkPossuiRaNomeDisciplina PRIMARY KEY(ra,nome_disciplina,semestre, ano)
);
-- REMOÇÃO DO TRIGGER
DROP TRIGGER TatualizaSituacao

-- TRIGGER
CREATE TRIGGER TatualizaSituacao
ON Possui 
FOR INSERT , UPDATE
AS 
BEGIN
	DECLARE 
		-- DECLARAÇÃO DE VARIAVEIS
		@SUB DECIMAL(4,2),
		@NOME VARCHAR(20),
		@RA INT,
		@ANO INT,
		@SEMESTRE INT,
		@NOTA1 DECIMAL(4,2) ,
		@NOTA2 DECIMAL(4,2),
		@MEDIA DECIMAL(4,2),
		@FALTA DECIMAL(4,2),
		@TOTAL DECIMAL(4,2),
		@PORCENTAGEM DECIMAL(4,2)

	-- ATRIBUIÇÃO DE VARIAVEIS
	SELECT @RA = ra, @NOME = nome_disciplina,@SEMESTRE = semestre ,@FAlTA = falta,@ANO = ano, @NOTA1 = nota_b1 , @NOTA2 = nota_b2, @SUB = sub
	FROM INSERTED
	
	-- ATUALIZAÇÃO DA MENOR NOTA PARA A NOTA DA SUBSTITUTIVA
	IF @NOTA1 > @NOTA2 -- NOTA 2 É A MENOR
		UPDATE Possui
		SET @NOTA2 = 
		(CASE
			WHEN @SUB is NULL  THEN nota_b2
			ELSE(@SUB)
		END 
		)
		WHERE ra = @RA AND nome_disciplina = @NOME  AND semestre = @SEMESTRE AND ano = @ANO
		
	ELSE -- NOTA 1 É A MENOR
		UPDATE Possui
		SET @NOTA1 = 
		(CASE
			WHEN @SUB is NULL  THEN nota_b1
			ELSE(@SUB)
		END 
		)
		WHERE ra = @RA AND nome_disciplina = @NOME  AND semestre = @SEMESTRE AND ano = @ANO

	-- CALCULA MEDIA
	SET @MEDIA=(@NOTA1+@NOTA2)/2

	-- RESGATA A QUANTIDADE TOTAL DE AULAS DA DISCIPLINA
	SELECT @TOTAL = qtd_aula 
	FROM Disciplina 
	WHERE nome_disciplina = @NOME

	-- CALCULA A PORCENTAGEM DE FALTAS DO ALUNO NA DISCIPLINA
	SET @PORCENTAGEM = (@FALTA/@TOTAL)

	-- ATUALIZA A SITUAÇÃO DO ALUNO DEPENDENDO DE SUAS NOTAS E FALTAS
	UPDATE Possui 
	SET situacao = 
	(CASE
		WHEN @PORCENTAGEM > 0.250 THEN 'Reprovado por falta' 
		WHEN @MEDIA > 6.00 THEN 'Aprovado'
		WHEN @MEDIA < 5.99 THEN  'Reprovado por nota' 
		WHEN @PORCENTAGEM < 0.250 THEN 'Aprovado'
		
	END 
	)-- CONDIÇÃO PARA ATUALIZAR OS DADOS DO ALUNO QUE ESTA INSERINDO/ALTERANDO 
	WHERE ra = @RA AND nome_disciplina = @NOME  AND semestre = @SEMESTRE AND ano = @ANO
END;

--INSERÇÃO DE DISCIPLINA ALUNO
INSERT INTO Possui(ra,nome_disciplina,ano,semestre,falta,nota_b1,nota_b2)
VALUES(2,'Programação linear',2021,1,0,8,7)

--IMPRESSÕES
SELECT * FROM Disciplina
SELECT * FROM Possui

--SERVE PARA INSERIR DEPOIS DA INSERÇÃO
UPDATE Possui
SET sub = 7
WHERE ra = 2 AND semestre = 1 AND ano = 2020 AND nome_disciplina = 'Programação linear'

UPDATE Possui
SET falta = 10
WHERE ra = 2 AND semestre = 1 AND ano = 2021 AND nome_disciplina = 'Programação linear'

UPDATE Possui
SET nota_b1 = 6
WHERE ra = 2 AND semestre = 1 AND ano = 2020 AND nome_disciplina = 'Programação linear'

-- INSERÇÕES DE DADOS NO BD
INSERT INTO Curso
VALUES('Sistema de inf')

INSERT INTO Aluno
VALUES(1,'Isabela','rua tal','100','centro','14000852','Araraquara','sp','Sistema de inf')

INSERT INTO FoneAluno
VALUES(1,'1699456633','Celular')

INSERT INTO Disciplina
VALUES('Programação BD',30,'Sistema de inf')


/*A)QUAIS SÃO ALUNOS DE UMA DETERMINADA DISCIPLINA MINISTRADA NO ANO DE 2020, COM SUAS NOTAS. VOCÊ DEFINIRÁ A DISCIPLINA.*/
SELECT l.nome_aluno, p.nota_b1,p.nota_b2
FROM Aluno l ,Disciplina d  JOIN Possui p
ON d.nome_disciplina = 'Banco de dados' AND d.nome_disciplina = p.nome_disciplina
WHERE l.ra = p.ra AND p.ano = 2020

/*B)QUAIS  SÃO  AS  NOTAS  DE  UM  ALUNO  EM  TODAS  AS  DISCIPLINAS  POR  ELE CURSADAS  NO  2º.  SEMESTRE  DE  2019.  
(“BOLETIM  COM  AS INFORMAÇÕES  DAS  DISCIPLINAS  CURSADAS”).  VOCÊ  DEFINIRÁ  O ALUNO.*/
SELECT l.nome_aluno,p.semestre,c.nome_disciplina,p.nota_b1, p.nota_b2, CAST((p.nota_b1 + p.nota_b2)/2 AS DECIMAL(4,2)) AS media 
FROM Aluno l,Disciplina c  JOIN Possui p 
ON p.semestre = 2  AND p.nome_disciplina = c.nome_disciplina
WHERE l.nome_aluno = 'Isabela' AND p.ano = 2019 AND p.ra = l.ra

/*C)QUAIS SÃO OS ALUNOS REPROVADOS POR NOTA (MÉDIA INFERIOR A SEIS) NO ANO DE 2020 E,
O NOME DAS DISCIPLINAS E AS MÉDIAS.VOCÊ DEFINIRÁ O CURSO.*/
SELECT l.nome_aluno,c.nome_disciplina,CAST((p.nota_b1 + p.nota_b2)/2 AS DECIMAL(4,2)) AS media
FROM Aluno l ,Disciplina c JOIN Possui p
ON p.situacao = 'Reprovado por nota' AND p.nome_disciplina = c.nome_disciplina
WHERE c.nome_curso = 'ADS' AND p.ano = 2020  and p.ra = l.ra

/*D)TABELA QUE INFORMA O NOME E TELEFONE DOS ALUNOS MATRICULADOS EM ALGUMA DISCIPLINA NA FACUDADE.*/
SELECT DISTINCT l.nome_aluno,t.numero, C.nome_disciplina
FROM Possui p JOIN FoneAluno t ON t.ra = p.ra
JOIN  Disciplina c ON c.nome_disciplina = p.nome_disciplina
JOIN  Aluno l ON p.ra = l.ra 