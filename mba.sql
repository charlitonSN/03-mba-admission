 -- Banco completo de MBA Admission
 -- admission vazio (NULL) = candidato não admitido (Deny)
 -- Waitlist é considerado como não admitido
 -- race vazio (NULL) = candidato internacional (o dataset não registra raça desses candidatos)



-- Qual é a distribuição de gênero, nacionalidade, major e raça entre os candidatos?
SELECT
    gender AS genero,
    COUNT(*) AS qtd_candidatos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM mba), 2) AS percentual

FROM mba

GROUP BY gender

ORDER BY qtd_candidatos DESC;


SELECT
    CASE
        WHEN international = 1 THEN 'Internacional'
        ELSE 'Nacional'
    END AS nacionalidade,
    COUNT(*) AS qtd_candidatos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM mba), 2) AS percentual

FROM mba

GROUP BY international

ORDER BY qtd_candidatos DESC;


SELECT
    major AS graduacao,
    COUNT(*) AS qtd_candidatos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM mba), 2) AS percentual

FROM mba

GROUP BY major

ORDER BY qtd_candidatos DESC;


SELECT
    COALESCE(race, 'International') AS raca,
    COUNT(*) AS qtd_candidatos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM mba), 2) AS percentual

FROM mba

GROUP BY race

ORDER BY qtd_candidatos DESC;



-- Qual é a proporção de candidatos internacionais admitidos? E dos candidatos locais?
SELECT
    CASE
        WHEN international = 1 THEN 'Internacional'
        ELSE 'Nacional'
    END AS nacionalidade,

    COUNT(*) AS qtd_candidatos,

    SUM(
        CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
    ) AS qtd_admitidos,

    ROUND(
        100.0 * SUM(
            CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS taxa_admissao

FROM mba

GROUP BY international

ORDER BY taxa_admissao DESC;



-- Qual é a média de GPA e de GMAT para candidatos internacionais vs nacionais?
SELECT
    CASE
        WHEN international = 1 THEN 'Internacional'
        ELSE 'Nacional'
    END AS nacionalidade,
    COUNT(*) AS qtd_candidatos,
    ROUND(AVG(gpa), 2) AS media_gpa,
    ROUND(AVG(gmat), 2) AS media_gmat

FROM mba

GROUP BY international;



-- Como se comparam as distribuições de GPA e GMAT entre candidatos internacionais e nacionais?
-- Resumo estatístico (mínimo, quartis, máximo, média e desvio padrão)
WITH base AS (
    SELECT
        CASE
            WHEN international = 1 THEN 'Internacional'
            ELSE 'Nacional'
        END AS nacionalidade,
        'GPA' AS metrica,
        gpa AS valor

    FROM mba

    UNION ALL

    SELECT
        CASE
            WHEN international = 1 THEN 'Internacional'
            ELSE 'Nacional'
        END AS nacionalidade,
        'GMAT' AS metrica,
        gmat AS valor

    FROM mba
),

ordenado AS (
    SELECT
        nacionalidade,
        metrica,
        valor,
        ROW_NUMBER() OVER (PARTITION BY nacionalidade, metrica ORDER BY valor) AS posicao,
        COUNT(*) OVER (PARTITION BY nacionalidade, metrica) AS qtd

    FROM base
)

SELECT
    metrica,
    nacionalidade,
    MIN(valor) AS minimo,
    MAX(CASE WHEN posicao = CAST(0.25 * qtd + 0.5 AS INT) THEN valor END) AS q1,
    ROUND(AVG(CASE WHEN posicao IN ((qtd + 1) / 2, (qtd + 2) / 2) THEN valor END), 2) AS mediana,
    MAX(CASE WHEN posicao = CAST(0.75 * qtd + 0.5 AS INT) THEN valor END) AS q3,
    MAX(valor) AS maximo,
    ROUND(AVG(valor), 2) AS media,
    ROUND(
        SQRT((SUM(valor * valor) - COUNT(*) * AVG(valor) * AVG(valor)) / (COUNT(*) - 1)),
        2
    ) AS desvio_padrao

FROM ordenado

GROUP BY
    metrica,
    nacionalidade

ORDER BY
    metrica,
    nacionalidade;


-- Distribuição de GPA por faixa (histograma)
-- Verificar o gráfico no power bi
SELECT
    ROUND(CAST(gpa * 10 AS INT) / 10.0, 1) AS faixa_gpa,

    ROUND(
        100.0 * SUM(
            CASE WHEN international = 0 THEN 1 ELSE 0 END
        ) / (SELECT COUNT(*) FROM mba WHERE international = 0),
        2
    ) AS percentual_nacional,

    ROUND(
        100.0 * SUM(
            CASE WHEN international = 1 THEN 1 ELSE 0 END
        ) / (SELECT COUNT(*) FROM mba WHERE international = 1),
        2
    ) AS percentual_internacional

FROM mba

GROUP BY faixa_gpa

ORDER BY faixa_gpa;


-- Distribuição de GMAT por faixa (histograma)
-- Verificar o gráfico no power bi
SELECT
    CAST(gmat / 50 AS INT) * 50 AS faixa_gmat,

    ROUND(
        100.0 * SUM(
            CASE WHEN international = 0 THEN 1 ELSE 0 END
        ) / (SELECT COUNT(*) FROM mba WHERE international = 0),
        2
    ) AS percentual_nacional,

    ROUND(
        100.0 * SUM(
            CASE WHEN international = 1 THEN 1 ELSE 0 END
        ) / (SELECT COUNT(*) FROM mba WHERE international = 1),
        2
    ) AS percentual_internacional

FROM mba

GROUP BY faixa_gmat

ORDER BY faixa_gmat;



-- Questão Bônus: teste de hipóteses para comparar as médias de GPA e GMAT entre os dois públicos.
-- Teste t de Welch | H0: médias iguais | H1: médias diferentes
-- Com amostras grandes, |t| > 1,96 rejeita H0 a 5% de significância
WITH estatisticas AS (
    SELECT
        international,
        COUNT(*) AS qtd,
        AVG(gpa) AS media_gpa,
        (SUM(gpa * gpa) - COUNT(*) * AVG(gpa) * AVG(gpa)) / (COUNT(*) - 1) AS variancia_gpa,
        AVG(gmat) AS media_gmat,
        (SUM(gmat * gmat) - COUNT(*) * AVG(gmat) * AVG(gmat)) / (COUNT(*) - 1) AS variancia_gmat

    FROM mba

    GROUP BY international
),

teste AS (
    SELECT
        'GPA' AS metrica,
        i.media_gpa AS media_internacional,
        n.media_gpa AS media_nacional,
        (i.media_gpa - n.media_gpa)
            / SQRT(i.variancia_gpa / i.qtd + n.variancia_gpa / n.qtd) AS estatistica_t

    FROM estatisticas i, estatisticas n

    WHERE i.international = 1
      AND n.international = 0

    UNION ALL

    SELECT
        'GMAT' AS metrica,
        i.media_gmat AS media_internacional,
        n.media_gmat AS media_nacional,
        (i.media_gmat - n.media_gmat)
            / SQRT(i.variancia_gmat / i.qtd + n.variancia_gmat / n.qtd) AS estatistica_t

    FROM estatisticas i, estatisticas n

    WHERE i.international = 1
      AND n.international = 0
)

SELECT
    metrica,
    ROUND(media_internacional, 2) AS media_internacional,
    ROUND(media_nacional, 2) AS media_nacional,
    ROUND(estatistica_t, 2) AS estatistica_t,
    CASE
        WHEN ABS(estatistica_t) > 1.96 THEN 'Diferença significativa'
        ELSE 'Sem diferença significativa'
    END AS conclusao

FROM teste;



-- Existe alguma relação entre o GPA e a pontuação no GMAT dos candidatos admitidos?
-- Coeficiente de Pearson
SELECT
    COUNT(*) AS qtd_admitidos,
    ROUND(
        (AVG(gpa * gmat) - AVG(gpa) * AVG(gmat))
        / (SQRT(AVG(gpa * gpa) - AVG(gpa) * AVG(gpa))
         * SQRT(AVG(gmat * gmat) - AVG(gmat) * AVG(gmat))),
        2
    ) AS correlacao_gpa_gmat

FROM mba

WHERE admission = 'Admit';



-- Existe alguma indústria em que a proporção de candidatos admitidos é maior?
SELECT
    work_industry AS industria,

    COUNT(*) AS qtd_candidatos,

    SUM(
        CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
    ) AS qtd_admitidos,

    ROUND(
        100.0 * SUM(
            CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS taxa_admissao

FROM mba

GROUP BY work_industry

ORDER BY taxa_admissao DESC;



-- Existe alguma correlação entre a experiência de trabalho e a admissão no programa
-- (coeficiente de Pearson)?
-- Admissão convertida em 1 (admitido) e 0 (não admitido)
WITH base AS (
    SELECT
        work_exp AS experiencia,
        CASE WHEN admission = 'Admit' THEN 1.0 ELSE 0 END AS admitido

    FROM mba
)

SELECT
    COUNT(*) AS qtd_candidatos,
    ROUND(
        (AVG(experiencia * admitido) - AVG(experiencia) * AVG(admitido))
        / (SQRT(AVG(experiencia * experiencia) - AVG(experiencia) * AVG(experiencia))
         * SQRT(AVG(admitido * admitido) - AVG(admitido) * AVG(admitido))),
        2
    ) AS correlacao_experiencia_admissao

FROM base;



-- Dado que o candidato pertence a uma certa raça/etnia, qual a probabilidade dele ser admitido
-- (probabilidade condicional)?
SELECT
    COALESCE(race, 'International') AS raca,

    COUNT(*) AS qtd_candidatos,

    SUM(
        CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
    ) AS qtd_admitidos,

    ROUND(
        100.0 * SUM(
            CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS probabilidade_admissao

FROM mba

GROUP BY race

ORDER BY probabilidade_admissao DESC;



-- Existe alguma relação entre gênero e notas de GPA e GMAT, considerando também apenas os
-- aprovados? Há alguma injustiça de gênero considerando uma diferença menor que 5% como irrelevante?
-- Diferença percentual = (Female - Male) / Male
WITH medias AS (
    SELECT
        'Todos os candidatos' AS grupo,
        AVG(CASE WHEN gender = 'Female' THEN gpa END) AS gpa_female,
        AVG(CASE WHEN gender = 'Male' THEN gpa END) AS gpa_male,
        AVG(CASE WHEN gender = 'Female' THEN gmat END) AS gmat_female,
        AVG(CASE WHEN gender = 'Male' THEN gmat END) AS gmat_male

    FROM mba

    UNION ALL

    SELECT
        'Admitidos' AS grupo,
        AVG(CASE WHEN gender = 'Female' THEN gpa END) AS gpa_female,
        AVG(CASE WHEN gender = 'Male' THEN gpa END) AS gpa_male,
        AVG(CASE WHEN gender = 'Female' THEN gmat END) AS gmat_female,
        AVG(CASE WHEN gender = 'Male' THEN gmat END) AS gmat_male

    FROM mba

    WHERE admission = 'Admit'
)

SELECT
    grupo,
    ROUND(gpa_female, 2) AS gpa_female,
    ROUND(gpa_male, 2) AS gpa_male,
    ROUND(100.0 * (gpa_female - gpa_male) / gpa_male, 2) AS diferenca_gpa,
    ROUND(gmat_female, 2) AS gmat_female,
    ROUND(gmat_male, 2) AS gmat_male,
    ROUND(100.0 * (gmat_female - gmat_male) / gmat_male, 2) AS diferenca_gmat,
    CASE
        WHEN ABS(gpa_female - gpa_male) / gpa_male >= 0.05
          OR ABS(gmat_female - gmat_male) / gmat_male >= 0.05 THEN 'Diferença relevante'
        ELSE 'Diferença irrelevante'
    END AS avaliacao

FROM medias;


-- Taxa de admissão por gênero
SELECT
    gender AS genero,

    COUNT(*) AS qtd_candidatos,

    SUM(
        CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
    ) AS qtd_admitidos,

    ROUND(
        100.0 * SUM(
            CASE WHEN admission = 'Admit' THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS taxa_admissao

FROM mba

GROUP BY gender

ORDER BY taxa_admissao DESC;



-- A média de experiência de trabalho é diferente entre aprovados e não aprovados para cada gênero?
SELECT
    gender AS genero,

    CASE
        WHEN admission = 'Admit' THEN 'Aprovado'
        ELSE 'Não aprovado'
    END AS status_admissao,

    COUNT(*) AS qtd_candidatos,
    ROUND(AVG(work_exp), 2) AS media_experiencia

FROM mba

GROUP BY
    gender,
    CASE
        WHEN admission = 'Admit' THEN 'Aprovado'
        ELSE 'Não aprovado'
    END

ORDER BY
    genero,
    status_admissao;
